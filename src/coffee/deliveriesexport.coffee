{SphereClient} = require 'sphere-node-sdk'
Promise = require 'bluebird'
_ = require 'underscore'
Csv = require 'csv'
objectPath = require 'object-path'

class DeliveriesExport
  constructor: (@options, @logger) ->
    @client = new SphereClient @options.client
    @stats = @_getDefaultStats()

  _getDefaultStats: ->
    _.clone
      loadedOrders: 0
      exportedDeliveries: 0
      exportedRows: 0

  _getCsvHeader: ->
    [
      'orderNumber',
      'delivery.id',
      '_itemGroupId',
      'item.id',
      'item.quantity',
      'parcel.id',
      'parcel.length',
      'parcel.height',
      'parcel.width',
      'parcel.weight',
      'parcel.trackingId',
      'parcel.carrier',
      'parcel.provider',
      'parcel.providerTransaction',
      'parcel.isReturn'
    ].join(',')

  _castRowsToCsv: (rows) ->
    new Promise (resolve, reject) ->
      Csv().from rows
        .on 'error', reject
        .to.string resolve

  # take delivery objects and map to CSV rows (objects indexed by column names)
  _mapDeliveriesToRows: (orderNumber, deliveries) ->
    @stats.exportedDeliveries += deliveries.length

    # run through all deliveries
    _.flatten deliveries.map (delivery) =>

      # create CSV rows from delivery items and orderNumber and deliveryId
      # Note that every delivery has at least one item
      rows = delivery.items.map (_item, index) =>
        item =
          orderNumber: orderNumber
          'delivery.id': delivery.id
          # add a unique ID to every delivery.item
          # (one delivery can have multiple items with the same lineItemId and quantity)
          '_itemGroupId': index
          'item.id': _item.id
          'item.quantity': _item.quantity

        # add info about parcels, if there are no parcels fill cells with empty strings
        @_connectItemWithParcel(item, delivery.parcels[index] or {})

      # if there are more parcels then items, duplicate last CSV row
      # and push it again with the rest of parcels
      for index in [rows.length...delivery.items.length]
        rows.push(@_connectItemWithParcel(
          _.copy(rows[rows.length - 1]), delivery.parcels[index]
        ))
      rows

  _connectItemWithParcel: (item, parcel) ->
    # Example parcel object:
    # {
    #   "id": "1",
    #   "trackingData": {
    #     "trackingId": "123456789",
    #     "carrier": "TEST",
    #     "provider": "provider 1",
    #     "providerTransaction": "provider transaction 1",
    #     "isReturn": false
    #   },
    #   "measurements": {
    #     "lengthInMillimeter": 100,
    #     "heightInMillimeter": 200,
    #     "widthInMillimeter": 200,
    #     "weightInGram": 500
    #   }
    # }

    map =
      'parcel.id': 'id'
      'parcel.length': 'measurements.lengthInMillimeter'
      'parcel.height': 'measurements.heightInMillimeter'
      'parcel.width': 'measurements.widthInMillimeter'
      'parcel.weight': 'measurements.lengthInMillimeter'
      'parcel.trackingId': 'trackingData.trackingId'
      'parcel.carrier': 'trackingData.carrier'
      'parcel.provider': 'trackingData.provider'
      'parcel.providerTransaction': 'trackingData.providerTransaction'
      'parcel.isReturn': 'trackingData.isReturn'

    Object.keys(map).forEach (key) ->
      item[key] = objectPath.get(parcel, map[key], '')

    # cast boolean value to 0 or 1
    if parcel.trackingData?.isReturn?
      item['parcel.isReturn'] = Number(parcel.trackingData.isReturn)
    item

  # load deliveries, serialize them as CSVs and save them to stream
  streamCsvDeliveries: (stream) ->
    stream.write("#{@_getCsvHeader()}\n")

    @streamDeliveries (orders) =>
      @stats.loadedOrders += orders.length
      @logger.debug("Processing #{orders.length} order(s)")

      # process only orders with deliveries
      orders = orders.filter (order) ->
        order.shippingInfo?.deliveries and order.shippingInfo.deliveries.length

      Promise.map orders, (order) =>
        rows = @_mapDeliveriesToRows(order.orderNumber, order.shippingInfo.deliveries)
        if rows.length
          @stats.exportedRows += rows.length
          @_castRowsToCsv(rows)
            .then (csv) -> stream.write("#{csv}\n")
    .then =>
      stream.end()
      @stats

  # load deliveries in chunks and pass them to processFn function
  streamDeliveries: (processFn) ->
    @client.orders
      .where(@options.export.where or '')
      .perPage(@options.export.perPage or 500)
      .process (res) ->
        Promise.resolve processFn(res.body.results)
    , { accumulate: false }

module.exports = DeliveriesExport