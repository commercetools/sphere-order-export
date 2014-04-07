_ = require 'underscore'
Mapping = require '../lib/mapping'
SphereClient = require 'sphere-node-client'
{ElasticIo, _u} = require('sphere-node-utils')
Config = require '../config'
fs = require 'fs'
ChannelService = require '../lib/channelservice'
SpecHelper = require './helper'

jasmine.getEnv().defaultTimeoutInterval = 10000

describe 'channelservice tests', ->

  CHANNEL_KEY = 'OrderXmlFileExport'
  CHANNEL_ROLE = 'OrderExport'

  beforeEach (done) ->
    @sphere = new SphereClient Config
    @mapping = new Mapping Config
    @channelService = new ChannelService Config

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
      @sphere.productTypes
        .save SpecHelper.productTypeMock()
    .then (result) =>
      productType = result.body
      @sphere.products
        .save SpecHelper.productMock(productType)
    .then (result) =>
      @product = result.body
      @sphere.orders
        .import SpecHelper.orderMock(@shippingMethod, @product, @taxCategory)
    .then (result) =>
      @order = result.body
      done()
    .fail (err) ->
      done _u.prettify err

  afterEach (done) ->
    done()

  it 'should create a new channel and return it', (done) ->
    key = "channel-#{new Date().getTime()}"
    @channelService.byKeyOrCreate(key, CHANNEL_ROLE)
    .then (result) ->
      expect(result.body).toBeDefined()
      expect(result.body.key).toEqual key
      expect(result.body.roles).toEqual [CHANNEL_ROLE]
      done()
    .fail (err) ->
      done _u.prettify(err)

  it 'should fetch an existing channel, add given role and return it', (done) ->
    @channelService.byKeyOrCreate(CHANNEL_KEY, CHANNEL_ROLE)
    .then (result) =>
      @channelService.byKeyOrCreate(CHANNEL_KEY, 'Primary')
      .then (result) ->
      done()
    .fail (err) ->
      done _u.prettify(err)

  it 'should fetch an existing channel and return it', (done) ->
    @channelService.byKeyOrCreate(CHANNEL_KEY, CHANNEL_ROLE)
    .then (result) =>
      expect(result.body).toBeDefined()
      expect(result.body.id).toEqual @channel.id
      expect(result.body.roles).toEqual @channel.roles
      done()
    .fail (err) ->
      done _u.prettify(err)

  it 'should fail if role is not possible', (done) ->
    key = "channel-#{new Date().getTime()}"
    @channelService.byKeyOrCreate(key, 'bla')
    .then (result) ->
      done('Should fail if a wrong role is given.')
    .fail (err) ->
      done()
