_ = require 'underscore'
Mapping = require '../lib/mapping.js'
SphereClient = require 'sphere-node-client'
Config = require '../config'
fs = require 'fs'

describe 'integration tests', ->
  beforeEach ->
    @sphere = new SphereClient Config
    @mapping = new Mapping Config

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
      @mapping.elasticio msg, Config, (msg, data) ->
        expect(data).toBeDefined()
        expect(data.attachments).toBeDefined()
        expect(data.attachments['touch-timestamp.txt']).toBeDefined()
        console.log data.attachments['touch-timestamp.txt'].content
        done()
