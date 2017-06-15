_ = require 'underscore'
_.mixin require('underscore-mixins')
{parseString} = require 'xml2js'
{ElasticIo} = require 'sphere-node-utils'
OrderExport = require '../../lib/orderexport'
Config = require '../../config'
SpecHelper = require '../helper'

describe 'OrderExport - Integration tests', ->

  CHANNEL_KEY = 'OrderXmlFileExport'
  CHANNEL_ROLE = 'OrderExport'
  CONTAINER_PAYMENT = 'checkoutInfo'

  beforeEach (done) ->
    @orderExport = new OrderExport client: Config

    @orderExport.client.channels.ensure(CHANNEL_KEY, CHANNEL_ROLE)
    .then (result) =>
      # get a tax category required for setting up shippingInfo
      #   (simply returning first found)
      @orderExport.client.taxCategories.save SpecHelper.taxCategoryMock()
    .then (result) =>
      @taxCategory = result.body
      @orderExport.client.zones.save SpecHelper.zoneMock()
    .then (result) =>
      zone = result.body
      @orderExport.client.shippingMethods
        .save SpecHelper.shippingMethodMock(zone, @taxCategory)
    .then (result) =>
      @shippingMethod = result.body
      @orderExport.client.productTypes.save SpecHelper.productTypeMock()
    .then (result) =>
      productType = result.body
      @orderExport.client.products.save SpecHelper.productMock(productType)
    .then (result) =>
      @product = result.body
      @orderExport.client.customers.save SpecHelper.customerMock()
    .then (result) =>
      @customer = result.body.customer
      @orderExport.client.orders.import SpecHelper.orderMock(@shippingMethod, @product, @taxCategory, @customer)
    .then (result) =>
      @order = result.body
      @orderExport.client.customObjects.save SpecHelper.orderPaymentInfo(CONTAINER_PAYMENT, @order.id)
    .then (result) -> done()
    .catch (err) -> done _.prettify err
  , 20000 # 20sec

  it 'should export as XML', (done) ->
    @orderExport._exportOptions.where = "id = \"#{@order.id}\""
    @orderExport.run()
    .then (xmlOrders) =>
      expectedOrder = _.find xmlOrders, (o) => o.id is @order.id
      parseString expectedOrder.xml, (err, result) =>
        expect(result.order.customerNumber[0]).toEqual @customer.customerNumber
        expect(result.order.externalCustomerId[0]).toEqual @customer.externalId
        done()
    .catch (err) -> done _.prettify err

  it 'should export as CSV', (done) ->
    @orderExport._exportOptions.where = "id = \"#{@order.id}\""
    @orderExport._exportOptions.exportType = 'csv'
    @orderExport._exportOptions.csvTemplate = __dirname + '/../../data/template-order-simple.csv'
    @orderExport.run()
    .then (csvData) =>
      @orderExport.csvMapping.parse csvData
      .then (parsed) ->
        expect(parsed[0]).toEqual ['id', 'orderNumber', 'totalPrice', 'totalNet', 'totalGross', 'discountCodes']
        expect(parsed[1][0]).toEqual jasmine.any(String)
        expect(parsed[1][1]).toBe ''
        expect(parsed[1][2]).toBe 'EUR 999'
        expect(parsed[1][3]).toBe ''
        expect(parsed[1][4]).toBe ''
        done()
    .catch (err) -> done _.prettify err
  , 10000 #10sec

  describe 'elastic.io', ->

    it 'should do nothing', (done) ->
      @orderExport.elasticio {}, Config, (error, message) ->
        done(_.prettify(error), null, 4) if error
        expect(message).toBe 'No data from elastic.io!'
        done()

    it 'should export', (done) ->
      msg =
        body: [@order]
      @orderExport.elasticio msg, Config, (error, message) ->
        done(_.prettify(error), null, 4) if error
        expect(message.attachments).toBeDefined()
        expect(message.attachments['touch-timestamp.txt']).toBeDefined()
        done()
