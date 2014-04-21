fs = require 'fs'
_ = require 'underscore'
{ElasticIo, _u} = require 'sphere-node-utils'
OrderExport = require '../lib/orderexport'
Config = require '../config'
SpecHelper = require './helper'
{parseString} = require 'xml2js'

jasmine.getEnv().defaultTimeoutInterval = 10000

describe 'integration tests', ->

  CHANNEL_KEY = 'OrderXmlFileExport'
  CHANNEL_ROLE = 'OrderExport'

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
      @sphere.customObjects.save SpecHelper.orderPaymentInfo(@order.id)
    .then (result) ->
      done()
    .fail (err) ->
      done _u.prettify err

  it 'nothing to do', (done) ->
    @orderExport.processOrders([])
    .then (xmlOrders) ->
      expect(xmlOrders).toBeDefined()
      expect(_.size(xmlOrders)).toEqual 0
      done()
    .fail (err) ->
      done _u.prettify err

  it 'full turn around', (done) ->
    @orderExport.processOrders([@order], @channel).then (xmlOrders) =>
      expect(_.size xmlOrders).toBe 1
      doc = xmlOrders[0].xml
      parseString doc, (err, result) =>
        expect(result.order.customerNumber[0]).toEqual @customer.customerNumber
        expect(result.order.externalCustomerId[0]).toEqual @customer.externalId
        done()
    .fail (err) ->
      done _u.prettify err

  describe 'elastic.io', ->
    it 'nothing to do', (done) ->
      @orderExport.elasticio {}, Config, (error, message) ->
        done(_u.prettify(error), null, 4) if error
        expect(message).toBe 'No data from elastic.io!'
        done()

    it 'full turn around', (done) ->
      msg =
        body: [@order]
      @orderExport.elasticio msg, Config, (error, message) ->
        done(_u.prettify(error), null, 4) if error
        expect(message.attachments).toBeDefined()
        expect(message.attachments['touch-timestamp.txt']).toBeDefined()
        done()
