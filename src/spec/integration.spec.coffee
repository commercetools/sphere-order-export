Mapping = require '../lib/mapping.js'
SphereClient = require 'sphere-node-client'
Config = require '../config'
fs = require 'fs'

describe 'integration tests', ->
  beforeEach (done) ->
    @sphere = new SphereClient Config
    fs.readFile './schema/order.xsd', 'utf8', (err, content) =>
      options =
        config: Config.config
        xsd: content
      @mapping = new Mapping options
      done()
  
  it 'full turn around', (done) ->
    @sphere.orders.perPage(10).fetch().then (result) =>
      @mapping.mapOrders result, ->
        done()

  it 'elastic.io integration', (done) ->
    @sphere.orders.perPage(10).fetch().then (result) =>
      msg =
        body: result
      @mapping.elasticio msg, Config, (result) ->
        done()
