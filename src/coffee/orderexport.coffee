_ = require 'underscore'
Q = require 'q'
fs = require 'q-io/fs'
SphereClient = require 'sphere-node-client'
{ElasticIo, _u} = require 'sphere-node-utils'
OrderService = require '../lib/orderservice'
XmlMapping = require './xmlmapping'
CsvMapping = require './csvMapping'

class OrderExport

  BASE64 = 'base64'
  CHANNEL_KEY = 'OrderXmlFileExport'
  CHANNEL_ROLE = 'OrderExport'
  CONTAINER_PAYMENT = 'checkoutInfo'

  constructor: (options = {}) ->
    @client = new SphereClient options
    @orderService = new OrderService @client
    @xmlMapping = new XmlMapping options
    @csvMapping = new CsvMapping options

  elasticio: (msg, cfg, next, snapshot) ->
    if _.isEmpty msg or _.isEmpty msg.body
      ElasticIo.returnSuccess 'No data from elastic.io!', next
      return

    @processOrders(msg.body.results)
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

      Q.all(syncInfos)
      .then ->
        ElasticIo.returnSuccess data, next
    .fail (result) ->
      ElasticIo.returnFailure res, res, next

  processOrders: (orders, csvTemplate) ->
    if csvTemplate?
      fs.read(csvTemplate).then (content) =>
        @csvMapping.mapOrders content, orders
    else
      @client.channels.ensure(CHANNEL_KEY, CHANNEL_ROLE)
      .then (result) =>
        @channel = result.body
        unsyncedOrders = @orderService.unsyncedOrders orders, @channel
        Q.all _.map unsyncedOrders, (order) => @processOrder order

  processOrder: (order) ->
    deferred = Q.defer()
    @client.customObjects.byId("#{CONTAINER_PAYMENT}/#{order.id}").fetch()
    .then (result) =>
      paymentInfo = result.body
      if order.customerId?
        @client.customers.byId(order.customerId).fetch()
        .then (result) =>
          entry =
            id: order.id
            xml: @xmlMapping.mapOrder order, paymentInfo, result.body
            version: order.version
          deferred.resolve entry
      else
        entry =
          id: order.id
          xml: @xmlMapping.mapOrder order, paymentInfo
          version: order.version
        deferred.resolve entry
    .fail (err) ->
      deferred.reject err

    deferred.promise

  syncOrder: (xmlOrder, filename) ->
    @orderService.addSyncInfo xmlOrder.id, xmlOrder.version, @channel, filename


module.exports = OrderExport