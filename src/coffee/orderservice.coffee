Q = require 'q'
_ = require 'underscore'

class OrderService

  constructor: (@client) ->

  ###
  Returns only orders which haven't been synced using the given channel.
  @param {Collection} orders List of order resources.
  @param {Channel} channel SyncInfo channel to which an order mustn't have.
  @return {Collection}
  ###
  unsyncedOrders: (orders, channel) ->
    _.select orders, (order) ->
      order.syncInfo or= []
      not _.find order.syncInfo, (syncInfo) ->
        syncInfo.channel.id is channel?.id

  # TODO: retry if version of order is updated

  ###
  Add a SyncInfo to a given order.
  @param {String} orderId Id of order to be updated.
  @param {Channel} orderVersion Order resource version to update.
  @param {Channel} channel Channel which used for syncing.
  @param {String} externalId Id of external order resource (filename)
  @return {Promise Result}
  ###
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

    @client.orders.byId(orderId).save(data)

module.exports = OrderService
