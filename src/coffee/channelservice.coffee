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
    .then (result) =>
      if result.body.total is 1
        deferred.resolve result.body.results[0]
      else

        channel =
          key: key
          roles: ['OrderExport']
        @client.channels.save(channel)

    .fail (result) ->
      deferred.reject result

    deferred.promise

module.exports = ChannelService
