_ = require('underscore')._
SphereClient = require 'sphere-node-client'
InventoryUpdater = require('sphere-node-sync').InventoryUpdater
Q = require 'q'

class OrderService

  constructor: (options = {}) ->
    unless options.sphere_client
      options.sphere_client = new SphereClient options
    @client = options.sphere_client

  filterOrders: (orders, channelId) ->
    _.select orders, (order) ->
      order.syncInfo or= []
      not _.find order.syncInfo, (syncInfo) ->
        syncInfo.channel.id is channelId

  # TODO:
  # retry if version of order is updated
  addSyncInfo: (orderId, orderVersion, channel, externalId) ->
    data =
      version: orderVersion
      actions: [
        action: 'updateSyncInfo'
        channel:
          typeId: 'channel'
          id: channel.id
        externalId: externalId
      ]

    console.log "data: #{JSON.stringify data, null, 4}"
    console.log "channel: #{JSON.stringify channel, null, 4}"
    @client.orders.byId(orderId).save(data)

module.exports = OrderService
