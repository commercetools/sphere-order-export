_ = require('underscore')._
SphereClient = require 'sphere-node-client'
Q = require 'q'

class ChannelService

  constructor: (options = {}) ->
    unless options.sphere_client
      options.sphere_client = new SphereClient options
    @client = options.sphere_client

  byKeyOrCreate: (key) ->
    deferred = Q.defer()

    @client.channels.where("key=\"#{key}\"").page(1).fetch()
    .then (channel) ->
      deferred.resolve channel
    .fail (result) =>
      if result.statusCode is 404
        channel =
          key: channelId

        @client.channels.save(channel)
        .then (channel) ->
          deferred.resolve channel
        .fail (result) ->
          deferred.reject result
      else
        deferred.reject result

    deferred.promise

module.exports = ChannelService
