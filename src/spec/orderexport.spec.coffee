_ = require 'underscore'
_.mixin require('underscore-mixins')
Promise = require 'bluebird'
OrderExport = require '../lib/orderexport'
Config = require '../config'

unsyncedOrders = (channelId) -> [
  {id: 'aaa', syncInfo: [{channel: {typeId: 'channel', id: 'foo'}}]} # unsynced
  {id: 'bbb'} # unsynced
  {id: 'ccc', syncInfo: [{channel: {typeId: 'channel', id: channelId}}]} # synced
]

describe 'OrderExport', ->

  beforeEach ->
    @orderExport = new OrderExport client: Config
    expect(@orderExport._exportOptions).toEqual
      fetchHours: 48
      standardShippingMethod: 'None'
      exportType: 'xml'
      exportUnsyncedOnly: true
    @orderExport.channel = @orderExportChannel =
      id: 'channel-export'
      type: 'channel'

  it '#run', -> # TODO

  it '#csvExport', -> # TODO

  it 'should throw if no csv template is defined', ->
    @orderExport._exportOptions.exportType = 'csv'
    expect(=> @orderExport.csvExport()).toThrow new Error 'You need to provide a csv template for exporting order information'

  it '#xmlExport', -> # TODO

  it '#_fetchOrders (all)', (done) ->
    spyOn(@orderExport.client.orders, 'fetch').andCallFake -> Promise.resolve
      body:
        results: [1, 2]
    @orderExport._exportOptions.exportUnsyncedOnly = false
    @orderExport._fetchOrders()
    .then (orders) ->
      expect(orders).toEqual [1, 2]
      done()
    .catch (e) -> done e

  it '#_fetchOrders (unsynced only)', (done) ->
    spyOn(@orderExport, '_unsyncedOnly').andCallThrough()
    spyOn(@orderExport.client.orders, 'fetch').andCallFake => Promise.resolve
      body:
        results: unsyncedOrders(@orderExport.channel.id)
    @orderExport._exportOptions.exportUnsyncedOnly = true
    @orderExport._fetchOrders()
    .then (orders) =>
      expect(@orderExport._unsyncedOnly).toHaveBeenCalled()
      expect(orders.length).toEqual 2
      done()
    .catch (e) -> done e

  it '#_unsyncedOnly', ->
    unsyncedOrders = @orderExport._unsyncedOnly(unsyncedOrders(@orderExportChannel.id), @orderExportChannel)
    expect(_.size(unsyncedOrders)).toEqual 2

  it 'should set ordersExported flag to true if orders is returned', (done) ->
    spyOn(@orderExport.client.orders, 'fetch').andCallFake => Promise.resolve
      body:
        results: unsyncedOrders(@orderExport.channel.id)
    @orderExport._fetchOrders()
      .then () =>
        expect(@orderExport.ordersExported).toBeTruthy()
        done()

  it 'should set ordersExported flag to false if no orders is returned', (done) ->
    spyOn(@orderExport.client.orders, 'fetch').andCallFake => Promise.resolve
      body:
        results: []
    @orderExport._fetchOrders()
      .then () =>
        expect(@orderExport.ordersExported).toBeFalsy()
        done()

  it '#_processXmlOrder', -> # TODO

  it '#syncOrder', ->
    externalId = 'filename.txt'
    spyOn(@orderExport.client.orders, 'update')
    @orderExport.syncOrder {id: 'aaa', version: 1}, externalId

    expect(@orderExport.client.orders.update).toHaveBeenCalledWith
      version: 1
      actions: [
        action: 'updateSyncInfo'
        channel:
          typeId: 'channel'
          id: @orderExportChannel.id
        externalId: externalId
      ]
