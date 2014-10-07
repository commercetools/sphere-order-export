_ = require 'underscore'
_.mixin require('underscore-mixins')
{parseString} = require 'xml2js'
{ElasticIo} = require 'sphere-node-utils'
OrderExport = require '../lib/orderexport'
Config = require '../config'
SpecHelper = require './helper'

describe 'integration tests', ->

  CHANNEL_KEY = 'OrderXmlFileExport'
  CHANNEL_ROLE = 'OrderExport'
  CONTAINER_PAYMENT = 'checkoutInfo'

  beforeEach (done) ->
    @orderExport = new OrderExport Config
    @sphere = @orderExport.client

    @sphere.channels.ensure(CHANNEL_KEY, CHANNEL_ROLE)
    .then (result) =>
      @channel = result.channel
      # get a tax category required for setting up shippingInfo
      #   (simply returning first found)
      @sphere.taxCategories.save SpecHelper.taxCategoryMock()
    .then (result) =>
      @taxCategory = result.body
      @sphere.zones.save SpecHelper.zoneMock()
    .then (result) =>
      zone = result.body
      @sphere.shippingMethods
        .save SpecHelper.shippingMethodMock(zone, @taxCategory)
    .then (result) =>
      @shippingMethod = result.body
      @sphere.productTypes.save SpecHelper.productTypeMock()
    .then (result) =>
      productType = result.body
      @sphere.products.save SpecHelper.productMock(productType)
    .then (result) =>
      @product = result.body
      @sphere.customers.save SpecHelper.customerMock()
    .then (result) =>
      @customer = result.body.customer
      @sphere.orders.import SpecHelper.orderMock(@shippingMethod, @product, @taxCategory, @customer)
    .then (result) =>
      @order = result.body
      @sphere.customObjects.save SpecHelper.orderPaymentInfo(CONTAINER_PAYMENT, @order.id)
    .then (result) -> done()
    .catch (err) -> done _.prettify err
  , 20000 # 20sec

  it 'nothing to do', (done) ->
    @orderExport.processOrders([])
    .then (xmlOrders) ->
      expect(xmlOrders).toBeDefined()
      expect(_.size(xmlOrders)).toEqual 0
      done()
    .catch (err) -> done _.prettify err

  it 'full turn around', (done) ->
    @orderExport.processOrders([@order], @channel).then (xmlOrders) =>
      expect(_.size xmlOrders).toBe 1
      doc = xmlOrders[0].xml
      parseString doc, (err, result) =>
        expect(result.order.customerNumber[0]).toEqual @customer.customerNumber
        expect(result.order.externalCustomerId[0]).toEqual @customer.externalId
        done()
    .catch (err) -> done _.prettify err

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
