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
      fetchHours: 48
      standardShippingMethod: 'None'
      exportType: 'xml'
      exportUnsyncedOnly: true
    @client = new SphereClient options.client
    @xmlMapping = new XmlMapping @_exportOptions
    @csvMapping = new CsvMapping @_exportOptions

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

  csvExport: (orders) ->
    # TODO: export all fields if no csvTemplate is defined?
    throw new Error 'You need to provide a csv template for exporting order information' unless @_exportOptions.csvTemplate
    fs.readFileAsync(@_exportOptions.csvTemplate, {encoding: 'utf-8'})
    .then (content) => @csvMapping.mapOrders content, orders

  xmlExport: (orders) ->
    Promise.map orders, (order) => @_processXmlOrder order

  _fetchOrders: ->
    @client.channels.ensure(CHANNEL_KEY, CHANNEL_ROLE)
    .then (result) =>
      @channel = result.body

      # TODO: query also for syncInfo? -> not well supported by the API at the moment
      @client.orders.all()
      .expand('lineItems[*].state[*].state')
      .expand('lineItems[*].supplyChannel')
      .expand('discountCodes[*].discountCode')
      .expand('customerGroup')
      .last("#{@_exportOptions.fetchHours}h")
      .fetch()
    .then (result) =>
      allOrders = result.body.results
      if @_exportOptions.exportUnsyncedOnly
        Promise.resolve @_unsyncedOnly(allOrders, @channel)
      else
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
    # TODO: what if customObject is not found?
    # TODO: why not doing it also for CSV export?
    customObjectId = if order.cart
      order.cart.id
    else
      order.id
    @client.customObjects.byId("#{CONTAINER_PAYMENT}/#{customObjectId}").fetch()
    .then (result) =>
      paymentInfo = result.body
      if order.customerId?
        @client.customers.byId(order.customerId).fetch()
        .then (result) =>
          entry =
            id: order.id
            xml: @xmlMapping.mapOrder order, paymentInfo, result.body
            version: order.version
          Promise.resolve entry
      else
        entry =
          id: order.id
          xml: @xmlMapping.mapOrder order, paymentInfo
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

module.exports = OrderExport
