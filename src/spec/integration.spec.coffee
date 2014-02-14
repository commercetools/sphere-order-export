Mapping = require '../lib/mapping.js'
SphereClient = require 'sphere-node-client'
config = require '../config'

describe 'elastic.io integration', ->
  beforeEach ->
    @sphere = new SphereClient config
  
  it "getOrders", (done) ->
    @sphere.orders.fetch().then (result) ->
      expect(result).not.toBeUndefined()
      done()

  it "full turn around", (done) ->
    @sphere.orders.fetch().then (result) ->
      new Mapping().mapOrders result, ->
        done()
