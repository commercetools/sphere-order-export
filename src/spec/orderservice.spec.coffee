_ = require 'underscore'
_.mixin require('sphere-node-utils')._u
OrderExport = require '../lib/orderexport'
Config = require '../config'

describe 'orderservice', ->

  beforeEach ->
    @orderExport = new OrderExport Config
    @orderExport.channel = @orderExportChannel =
      id: 'channel-export'
      type: 'channel'

  it 'should return unsynced orders', ->
    orders = [
      {id: 'aaa', syncInfo: [{channel: {typeId: 'channel', id: 'foo'}}]}
      {id: 'bbb'}
      {id: 'ccc', syncInfo: [{channel: {typeId: 'channel', id: @orderExportChannel.id}}]}
    ]
    unsyncedOrders = @orderExport.orderService.unsyncedOrders(orders, @orderExportChannel)
    expect(_.size(unsyncedOrders)).toEqual 2

  it 'should add syncInfo', ->
    externalId = 'filename.txt'
    spyOn(@orderExport.client.orders, 'save')
    @orderExport.syncOrder {id: 'aaa', version: 1}, externalId

    expect(@orderExport.client.orders.save).toHaveBeenCalledWith
      version: 1
      actions: [
        action: 'updateSyncInfo'
        channel:
          typeId: 'channel'
          id: @orderExportChannel.id
        externalId: externalId
      ]
