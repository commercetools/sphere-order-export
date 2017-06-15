_ = require 'underscore'
Promise = require 'bluebird'
tmp = require 'tmp'
streamtest = require 'streamtest'

DeliveryExport = require '../../lib/delivery-export'
Config = require '../../config'
utils = require '../../lib/utils'
SpecHelper = require '../helper'

tmp.setGracefulCleanup()
logDir = tmp.dirSync()

logger = utils.getLogger({logDir: logDir.name}, 'deliveries-export-test')

getApiObjectsFromResponses = (res) ->
  Object.keys(res).forEach (key) ->
    res[key] = res[key].body
  res

deleteOrders = (client) ->
  client.orders
  .process (res) ->
    if res.body.count
      Promise.map res.body.results, (order) ->
        client.orders.byId(order.id).delete(order.version)
      , { concurrency: 10 }
    else
      Promise.resolve()

createOrderMock = (apiObjects, index) ->
  order = SpecHelper.orderMock(apiObjects.shippingMethod, apiObjects.product, apiObjects.taxCategory, apiObjects.customer, apiObjects.type)

  delete order.id
  order.orderNumber = "order_#{index}"
  order.shippingInfo.deliveries = [{
    id: '0bd3dd28-609a-4d98-8565-9874caae8c99'
    createdAt: '2017-06-07T19:33:22.230Z',
    items: [{
      id: apiObjects.product.id
      quantity: 1
    }],
    parcels: [{
      id: '0bd3dd28-609a-4d98-8565-9874caae8c25',
      createdAt: '2017-06-09T19:33:22.230Z',
      trackingData: {
        trackingId: 'trackingId',
        carrier: 'dhl',
        isReturn: false
      }
    }]
  }]
  order

describe 'DeliveryExport - Integration tests', ->
  beforeEach (done) ->
    @deliveriesExport = new DeliveryExport {client: Config}, logger

    deleteOrders(@deliveriesExport.client)
    .then =>
      Promise.props
        productType: @deliveriesExport.client.productTypes.save(SpecHelper.productTypeMock())
        taxCategory: @deliveriesExport.client.taxCategories.save(SpecHelper.taxCategoryMock())
        customer: @deliveriesExport.client.customers.save(SpecHelper.customerMock())
        zone: @deliveriesExport.client.zones.save(SpecHelper.zoneMock())
        type: @deliveriesExport.client.types.save(SpecHelper.typeMock())
    .then (res) =>
      @apiObjects = getApiObjectsFromResponses res
      @apiObjects.customer = @apiObjects.customer.customer

      shippingMethod = SpecHelper.shippingMethodMock(@apiObjects.zone, @apiObjects.taxCategory)

      Promise.props
        shippingMethod: @deliveriesExport.client.shippingMethods.save shippingMethod
        product: @deliveriesExport.client.products.save(SpecHelper.productMock(@apiObjects.productType))

    .then (res) =>
      Object.assign(@apiObjects, getApiObjectsFromResponses(res))

      # create 5 orders
      orders = [1...6].map (index) =>
        createOrderMock(@apiObjects, index)

      Promise.map orders, (order) =>
        @deliveriesExport.client.orders.import order
    .then (order) =>
      @apiObjects.order = order.body
      done()
    .catch (err) -> done _.prettify err
  , 20000 # 20sec

  afterEach (done) ->
    deleteOrders(@deliveriesExport.client)
    .then -> done()

  describe 'Streaming', ->
    it '#streamOrders should stream orders', (done) ->
      # stream 2 orders per page
      @deliveriesExport.options.export.perPage = 2
      callCount = 0
      ordersCount = 0

      @deliveriesExport.streamOrders (orders) ->
        callCount++
        ordersCount += orders.length
      .then ->
        expect(callCount).toBe(3)
        expect(ordersCount).toBe(5)
        done()

    it '#streamCsvDeliveries should stream deliveries in CSV format', (done) ->
      # stream 2 orders per page
      @deliveriesExport.options.export.perPage = 2

      outputStream = streamtest['v2'].toText (error, output) =>
        expect(error).toBe(null)
        expect(output).toContain(@deliveriesExport._getCsvHeader())

        csvRows = output.split('\n')
        expect(csvRows[csvRows.length - 1]).toBe('') # last row should be empty
        expect(csvRows.length).toBe(7) # 5 deliveries + 1 header + 1 empty row
        done()

      @deliveriesExport.streamCsvDeliveries(outputStream)
      .then (stats) ->
        expect(stats).toEqual
          loadedOrders: 5
          exportedDeliveries: 5
          exportedRows: 5

    it '#streamCsvDeliveries should work when there are no orders', (done) ->
      @deliveriesExport.options.export.where = 'orderNumber = "invalidOrderNumber"'

      outputStream = streamtest['v2'].toText (error, output) =>
        expect(error).toBe(null)
        expect(output).toContain(@deliveriesExport._getCsvHeader())

        csvRows = output.split('\n')
        expect(csvRows[csvRows.length - 1]).toBe('') # last row should be empty
        expect(csvRows.length).toBe(2) # 9 deliveries + 1 header + 1 empty row
        done()

      @deliveriesExport.streamCsvDeliveries(outputStream)
      .then (stats) ->
        expect(stats).toEqual
          loadedOrders: 0
          exportedDeliveries: 0
          exportedRows: 0

    it '#streamCsvDeliveries should work when there are orders without deliveries', (done) ->
      @deliveriesExport.options.export.where = 'orderNumber = "order_withoutDelivery"'
      order = createOrderMock(@apiObjects, 'withoutDelivery')
      order.shippingInfo.deliveries = []

      outputStream = streamtest['v2'].toText (error, output) =>
        expect(error).toBe(null)
        expect(output).toContain(@deliveriesExport._getCsvHeader())

        csvRows = output.split('\n')
        expect(csvRows[csvRows.length - 1]).toBe('') # last row should be empty
        expect(csvRows.length).toBe(2) # 9 deliveries + 1 header + 1 empty row
        done()

      @deliveriesExport.client.orders.import order
      .then =>
        @deliveriesExport.streamCsvDeliveries(outputStream)
      .then (stats) ->
        expect(stats).toEqual
          loadedOrders: 1
          exportedDeliveries: 0
          exportedRows: 0

