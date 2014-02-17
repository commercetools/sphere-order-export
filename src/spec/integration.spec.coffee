Mapping = require '../lib/mapping.js'
SphereClient = require 'sphere-node-client'
config = require '../config'

describe 'integration tests', ->
  beforeEach ->
    @sphere = new SphereClient config
    @mapping = new Mapping config
  
  it 'full turn around', (done) ->
    @sphere.orders.perPage(2).fetch().then (result) =>
      @mapping.mapOrders result, ->
        done()

  it 'elastic.io integration', (done) ->
    @sphere.orders.perPage(10).fetch().then (result) =>
      msg =
        body: result
      @mapping.elasticio msg, config, (result) ->
        done()
