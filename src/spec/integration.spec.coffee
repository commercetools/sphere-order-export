_ = require 'underscore'
Mapping = require '../lib/mapping'
SphereClient = require 'sphere-node-client'
Config = require '../config'
fs = require 'fs'
ChannelService = require '../lib/channelservice'

jasmine.getEnv().defaultTimeoutInterval = 10000

describe 'integration tests', ->

  CHANNEL_KEY = 'OrderXmlFileExport'
  CHANNEL_ROLE = 'OrderExport'

  beforeEach (done) ->
    @sphere = new SphereClient Config
    @mapping = new Mapping Config
    @channelService = new ChannelService Config

    @channelService.byKeyOrCreate(CHANNEL_KEY, CHANNEL_ROLE)
    .then (channel) =>
      @channel = channel
      # get a tax category required for setting up shippingInfo
      #   (simply returning first found)
      @sphere.taxCategories.save(taxCategoryMock())
    .then (result) =>
      @taxCategory = result.body
      @sphere.zones.save(zoneMock())
    .then (result) =>
      zone = result.body
      @sphere.shippingMethods.save(shippingMethodMock(zone, @taxCategory))
    .then (result) =>
      @shippingMethod = result.body
      @sphere.productTypes.save(productTypeMock())
    .then (result) =>
      productType = result.body
      @sphere.products.save(productMock(productType))
    .then (result) =>
      @product = result.body
      @sphere.orders.import(orderMock(@shippingMethod, @product, @taxCategory))
    .then (result) =>
      @order = result.body
      done()
    .fail (err) ->
      done(JSON.stringify err, null, 4)

  afterEach (done) ->
    done()

  it 'nothing to do', (done) ->
    @mapping.processOrders([])
    .then (xmlOrders) ->
      expect(xmlOrders).toBeDefined()
      expect(_.size(xmlOrders)).toEqual 0
      done()
    .fail (err) ->
      done(JSON.stringify err, null, 4)

  it 'full turn around', (done) ->
    @mapping.processOrders([@order], @channel).then (xmlOrders) ->
      expect(_.size xmlOrders).toBe 1
      done()
    .fail (err) ->
      done(JSON.stringify err, null, 4)

  describe 'elastic.io', ->
    it 'nothing to do', (done) ->
      @mapping.elasticio {}, Config, (error, message) ->
        done(JSON.stringify error, null, 4) if error
        expect(message).toBe 'No data from elastic.io!'
        done()

    it 'full turn around', (done) ->
      msg =
        body: [@order]
      @mapping.elasticio msg, Config, (error, message) ->
        done(JSON.stringify error, null, 4) if error
        expect(message.attachments).toBeDefined()
        expect(message.attachments['touch-timestamp.txt']).toBeDefined()
        done()


###
helper methods
###

shippingMethodMock = (zone, taxCategory) ->
  unique = new Date().getTime()
  shippingMethod =
    name: "S-#{unique}"
    zoneRates: [{
      zone:
        typeId: 'zone'
        id: zone.id
      shippingRates: [{
        price:
          currencyCode: 'EUR'
          centAmount: 99
        }]
      }]
    isDefault: false
    taxCategory:
      typeId: 'tax-category'
      id: taxCategory.id


zoneMock = ->
  unique = new Date().getTime()
  zone =
    name: "Z-#{unique}"

taxCategoryMock = ->
  unique = new Date().getTime()
  taxCategory =
    name: "TC-#{unique}"
    rates: [{
        name: "5%",
        amount: 0.05,
        includedInPrice: false,
        country: "DE",
        id: "jvzkDxzl"
      }]

productTypeMock = ->
  unique = new Date().getTime()
  productType =
    name: "PT-#{unique}"
    description: 'bla'

productMock = (productType) ->
  unique = new Date().getTime()
  product =
    productType:
      typeId: 'product-type'
      id: productType.id
    name:
      en: "P-#{unique}"
    slug:
      en: "p-#{unique}"
    masterVariant:
      sku: "sku-#{unique}"

orderMock = (shippingMethod, product, taxCategory) ->
  unique = new Date().getTime()
  order =
    id: "order-#{unique}"
    orderState: 'Open'
    paymentState: 'Pending'
    shipmentState: 'Pending'

    lineItems: [ {
      productId: product.id
      name:
        de: 'foo'
      variant:
        id: 1
      taxRate:
        name: 'myTax'
        amount: 0.10
        includedInPrice: false
        country: 'DE'
      quantity: 1
      price:
        value:
          centAmount: 999
          currencyCode: 'EUR'
    } ]
    totalPrice:
      currencyCode: 'EUR'
      centAmount: 999
    returnInfo: []
    shippingInfo:
      shippingMethodName: 'UPS'
      price:
        currencyCode: 'EUR'
        centAmount: 99
      shippingRate:
        price:
          currencyCode: 'EUR'
          centAmount: 99
      taxRate: _.first taxCategory.rates
      taxCategory:
        typeId: 'tax-category'
        id: taxCategory.id
      shippingMethod:
        typeId: 'shipping-method'
        id: shippingMethod.id
