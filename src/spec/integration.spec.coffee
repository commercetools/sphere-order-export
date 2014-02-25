_ = require 'underscore'
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

  it 'nothing to do', (done) ->
    @mapping.mapOrders([]).then (xmlOrders) ->
      expect(xmlOrders).toEqual []
      done()
  
  it 'full turn around', (done) ->
    @sphere.orders.perPage(3).fetch().then (result) =>
      @mapping.mapOrders(result.results).then (xmlOrders) ->
        expect(_.size xmlOrders).toBe 3
        done()

  it 'elastic.io integration', (done) ->
    @mapping.elasticio {}, Config, (result) ->
      expect(result.status).toBe true
      expect(result.message).toBe 'No data from elastic.io!'
      done()

  it 'elastic.io integration', (done) ->
    @sphere.orders.perPage(7).fetch().then (result) =>
      msg =
        body: result
      @mapping.elasticio msg, Config, (result) ->
        expect(result).toBeDefined()
        expect(result.attachments).toBeDefined()
        done()
