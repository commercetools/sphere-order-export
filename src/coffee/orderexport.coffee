_ = require 'underscore'
_.mixin require('underscore-mixins')
Promise = require 'bluebird'
fs = Promise.promisifyAll require('fs')
{SphereClient} = require 'sphere-node-sdk'
{ElasticIo} = require 'sphere-node-utils'
XmlMapping = require './mapping-utils/xml'
CsvMapping = require './mapping-utils/csv'

BASE64 = 'base64'
CHANNEL_KEY = 'OrderXmlFileExport'
CHANNEL_ROLE = 'OrderExport'
CONTAINER_PAYMENT = 'checkoutInfo'

class OrderExport

  constructor: (options = {}) ->
    @_exportOptions = _.defaults (options.export or {}),
      standardShippingMethod: 'None'
      exportType: 'xml'
      fillAllRows: false
      exportUnsyncedOnly: true
    @client = new SphereClient options.client
    @xmlMapping = new XmlMapping @_exportOptions
    @csvMapping = new CsvMapping @_exportOptions
    @ordersExported = false # Flag to avoid empty file being generated if no order is exported

  elasticio: (msg, cfg, next, snapshot) ->
    if _.isEmpty msg or _.isEmpty msg.body
      ElasticIo.returnSuccess 'No data from elastic.io!', next
      return

    # TODO: xml only export?
    @client.channels.ensure(CHANNEL_KEY, CHANNEL_ROLE)
    .then (result) =>
      @channel = result.body
      @xmlExport @_unsyncedOnly(msg.body.results, @channel)
    .then (xmlOrders) =>
      now = new Buffer(new Date().toISOString()).toString(BASE64)
      data =
        body: {}
        attachments:
          'touch-timestamp.txt':
            content: now
      syncInfos = []

      for xmlOrder in xmlOrders
        content = xmlOrder.xml.end(pretty: true, indent: '  ', newline: "\n")
        fileName = "#{xmlOrder.id}.xml"
        base64 = new Buffer(content).toString(BASE64)
        data.attachments[fileName] =
          content: base64
        syncInfos.push @syncOrder xmlOrder, fileName

      Promise.all(syncInfos)
      .then -> ElasticIo.returnSuccess data, next
    .catch (err) -> ElasticIo.returnFailure err, err.message, next

  run: ->
    switch @_exportOptions.exportType.toLowerCase()
      when 'csv' then @_fetchOrders().then (orders) => @csvExport(orders)
      when 'xml' then @_fetchOrders().then (orders) => @xmlExport(orders)
      else Promise.reject "Undefined export type '#{@_exportOptions.exportType}', supported 'csv' or 'xml'"

  runCSVAndStreamToFile: (writeToFile) ->
    @_getCSVOrderTemplate()
    .then (template) => @csvMapping._analyseTemplate(template)
    .then ([header, mappings]) =>
      # write first the header
      writeToFile(header.join(','))
      .then () =>
        if @_exportOptions.where
          @client.orders.where(@_exportOptions.where)

        @client.orders
        .expand('lineItems[*].state[*].state')
        .expand('lineItems[*].supplyChannel')
        .expand('discountCodes[*].discountCode')
        .expand('customerGroup')
        .perPage(@_exportOptions.perPage)
        .process (payload) =>
          orders = payload.body.results
          rows = _.map orders, (order) => @csvMapping._mapOrder(order, mappings)
          data = _.flatten rows, true
          @csvMapping.toCSVWithoutHeader(data)
          .then (exportedOrders) ->
            # write chunk of data
            writeToFile(exportedOrders)
        , { accumulate: false }

  csvExport: (orders) ->
    # TODO: export all fields if no csvTemplate is defined?
    @_getCSVOrderTemplate().then (content) => @csvMapping.mapOrders content, orders

  xmlExport: (orders) ->
    Promise.map orders, (order) => @_processXmlOrder order

  _fetchOrders: ->
    @client.channels.ensure(CHANNEL_KEY, CHANNEL_ROLE)
    .then (result) =>
      @channel = result.body

      # TODO: query also for syncInfo? -> not well supported by the API at the moment
      if @_exportOptions.where
        @client.orders.where(@_exportOptions.where)
      else
        @client.orders.all()

      @client.orders
      .expand('lineItems[*].state[*].state')
      .expand('lineItems[*].supplyChannel')
      .expand('discountCodes[*].discountCode')
      .expand('customerGroup')
      .fetch()
    .then (result) =>
      allOrders = result.body.results
      if @_exportOptions.exportUnsyncedOnly
        _unSyncedOrders = @_unsyncedOnly(allOrders, @channel)
        if _unSyncedOrders.length
          @ordersExported = true
        Promise.resolve _unSyncedOrders
      else
        if allOrders.length
          @ordersExported = true
        Promise.resolve allOrders

  _unsyncedOnly: (orders, channel) ->
    _.filter orders, (order) ->
      order.syncInfo or= []
      if _.isEmpty order.syncInfo
        return true
      else
        not _.find order.syncInfo, (syncInfo) ->
          syncInfo.channel.id is channel?.id

  _processXmlOrder: (order) ->
    if order.customerId?
      @client.customers.byId(order.customerId).fetch()
      .then (result) =>
        entry =
          id: order.id
          xml: @xmlMapping.mapOrder order, result.body
          version: order.version
        Promise.resolve entry
    else
      entry =
        id: order.id
        xml: @xmlMapping.mapOrder order
        version: order.version
      Promise.resolve entry

  syncOrder: (xmlOrder, filename) ->
    data =
      version: xmlOrder.version
      actions: [
        action: 'updateSyncInfo'
        channel:
          typeId: 'channel'
          id: @channel.id
        externalId: filename
      ]
    @client.orders.byId(xmlOrder.id).update(data)

  _getCSVOrderTemplate: () ->
    unless @_exportOptions.csvTemplate
      throw new Error 'You need to provide a csv template for exporting order information'
    fs.readFileAsync(@_exportOptions.csvTemplate, {encoding: 'utf-8'})

module.exports = OrderExport
