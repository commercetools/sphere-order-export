SphereClient = require 'sphere-node-client'
Q = require 'q'

class OrderService

  constructor: (options = {}) ->
    unless options.sphere_client
      options.sphere_client = new SphereClient options
    @orders = options.sphere_client.orders

  addSyncInfo: (orderId, orderVersion, channelId, externalId) ->
    data =
      version: orderVersion
      actions: [
        action: 'updateSyncInfo'
        channel:
          typeId: 'channel'
          id: channelId
        externalId: externalId
      ]
    @orders.byId(orderId).save(data)

module.exports = OrderService
