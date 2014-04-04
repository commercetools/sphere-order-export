_ = require('underscore')._
SphereClient = require 'sphere-node-client'
InventoryUpdater = require('sphere-node-sync').InventoryUpdater
Q = require 'q'

class OrderService

  constructor: (options = {}) ->
    unless options.sphere_client
      options.sphere_client = new SphereClient options
    @client = options.sphere_client

  ###
  Returns only orders without given syncInfo channel.
  @param {Collection} orders List of order resources.
  @param {Channel} channel SyncInfo channel to which an order mustn't have.
  @return {Collection}
  ###
  unsyncedOrders: (orders, channel) ->
    _.select orders, (order) ->
      order.syncInfo or= []
      not _.find order.syncInfo, (syncInfo) ->
        syncInfo.channel.id is channel

  # TODO:
  # retry if version of order is updated

  ###
  Add a SyncInfo to a given order.
  @param {String} orderId Id of order to be updated.
  @param {Channel} orderVersion Order resource version to update.
  @param {Channel} channel Channel which used for syncing.
  @param {String} externalId Id of external order resource (filename)
  @return {Promise SyncInfo}
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
