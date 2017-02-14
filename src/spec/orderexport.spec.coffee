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

createClientMock = () ->
  return {
    params: []
    where: (cond) ->
      this.params.push(cond)
      this
    last: (cond) ->
      this.params.push(cond)
      this
  }


describe 'OrderExport', ->

  beforeEach ->
    @orderExport = new OrderExport client: Config
    expect(@orderExport._exportOptions).toEqual
      createdFrom: null
      createdTo: null
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
    _unsyncedOrders = @orderExport._unsyncedOnly(unsyncedOrders(@orderExportChannel.id), @orderExportChannel)
    expect(_.size(_unsyncedOrders)).toEqual 2

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

  it '#_addDateOffset - default', ->
    client = createClientMock()
    client = @orderExport._addDateOffset(client)
    expect(client.params).toEqual ['48h']

  it '#_addDateOffset - time offset', ->
    client = createClientMock()
    _.assign @orderExport._exportOptions,
      fetchHours: 50
    client = @orderExport._addDateOffset(client)
    expect(client.params).toEqual ['50h']

  it '#_addDateOffset - time offset with createdTo limit', ->
    client = createClientMock()
    _.assign @orderExport._exportOptions,
      fetchHours: 50
      createdTo: '2001-09-11T14:00'
    client = @orderExport._addDateOffset(client)
    expect(client.params).toEqual [ 'createdAt <= "2001-09-11T14:00"' ]

  it '#_addDateOffset - createdTo and createdFrom limits', ->
    client = createClientMock()
    _.assign @orderExport._exportOptions,
      createdFrom: '2001-09-01T14:00'
      createdTo: '2001-09-11T14:00'
    client = @orderExport._addDateOffset(client)
    expect(client.params).toEqual [
      'createdAt <= "2001-09-11T14:00"',
      'createdAt >= "2001-09-01T14:00"'
    ]

  it '#_addDateOffset - createdFrom limit', ->
    client = createClientMock()
    _.assign @orderExport._exportOptions,
      createdFrom: '2001-09-01T14:00'
    client = @orderExport._addDateOffset(client)
    expect(client.params).toEqual [
      'createdAt >= "2001-09-01T14:00"'
    ]
