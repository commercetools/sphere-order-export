_ = require 'underscore'
_.mixin require('underscore-mixins')
{parseString} = require 'xml2js'
{ElasticIo} = require 'sphere-node-utils'
OrderExport = require '../../lib/orderexport'
Config = require '../../config'
SpecHelper = require '../helper'

describe 'integration tests', ->

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

  it 'export as XML', (done) ->
    @orderExport.run()
    .then (xmlOrders) =>
      expect(_.size xmlOrders).toBeGreaterThan 1
      expectedOrder = _.find xmlOrders, (o) => o.id is @order.id
      parseString expectedOrder.xml, (err, result) =>
        expect(result.order.customerNumber[0]).toEqual @customer.customerNumber
        expect(result.order.externalCustomerId[0]).toEqual @customer.externalId
        done()
    .catch (err) -> done _.prettify err

  # TODO: export as CSV

  describe 'elastic.io', ->
    it 'nothing to do', (done) ->
      @orderExport.elasticio {}, Config, (error, message) ->
        done(_.prettify(error), null, 4) if error
        expect(message).toBe 'No data from elastic.io!'
        done()

    it 'full turn around', (done) ->
      msg =
        body: [@order]
      @orderExport.elasticio msg, Config, (error, message) ->
        done(_.prettify(error), null, 4) if error
        expect(message.attachments).toBeDefined()
        expect(message.attachments['touch-timestamp.txt']).toBeDefined()
        done()
