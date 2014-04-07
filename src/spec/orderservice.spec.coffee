_ = require 'underscore'
Mapping = require '../lib/mapping'
SphereClient = require 'sphere-node-client'
{ElasticIo, _u} = require('sphere-node-utils')
Config = require '../config'
fs = require 'fs'
ChannelService = require '../lib/channelservice'
SpecHelper = require './helper'
OrderService = require '../lib/orderservice'

jasmine.getEnv().defaultTimeoutInterval = 10000

describe 'orderservice', ->

  CHANNEL_KEY = 'OrderXmlFileExport'
  CHANNEL_ROLE = 'OrderExport'

  beforeEach (done) ->
    @sphere = new SphereClient Config
    @mapping = new Mapping Config
    @channelService = new ChannelService Config
    @orderService = new OrderService Config

    @channelService.byKeyOrCreate(CHANNEL_KEY, CHANNEL_ROLE)
    .then (result) =>
      @channel = result.body
      # get a tax category required for setting up shippingInfo
      #   (simply returning first found)
      @sphere.taxCategories.save SpecHelper.taxCategoryMock()
    .then (result) =>
      @taxCategory = result.body
      @sphere.zones.save zoneMock()
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
      @sphere.orders
        .import SpecHelper.orderMock(@shippingMethod, @product, @taxCategory)
    .then (result) =>
      @order = result.body
      done()
    .fail (err) ->
      done _u.prettify err

  it 'should return unsynced orders', ->
    unsyncedOrders = @orderService.unsyncedOrders([@order], @channel)
    expect(_.size(unsyncedOrders)).toEqual 1

  it 'should return empty collection when no unsynced orders are available', ->

    syncedOrder = _u.deepClone @order

    syncedOrder.syncInfo = [
      channel:
        id: @channel.id
      ]

    unsyncedOrders = @orderService.unsyncedOrders([syncedOrder], @channel)
    expect(_.size(unsyncedOrders)).toEqual 0

  it 'should add syncInfo', ->
    externalId = 'filename.txt'
    @orderService
      .addSyncInfo @order.id, @order.version, @channel, externalId
    .then (result) =>
      expect(result.body.syncInfo).toBeDefined()
      expect (_.size(result.body.syncInfo)).to Equal 1
      expect (_.size(result.body.syncInfo[0].channel)).toEqual @channel.id
      expect (_.size(result.body.syncInfo[0].externalId)).toEqual externalId
    .fail (err) ->
      done _u.prettify err
