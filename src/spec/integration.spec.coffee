_ = require 'underscore'
Mapping = require '../lib/mapping'
SphereClient = require 'sphere-node-client'
Config = require '../config'
fs = require 'fs'

jasmine.getEnv().defaultTimeoutInterval = 10000

describe 'integration tests', ->
  beforeEach ->
    @sphere = new SphereClient Config
    @mapping = new Mapping Config

  it 'nothing to do', (done) ->
    @mapping.processOrders([]).then (xmlOrders) ->
      expect(xmlOrders).toEqual 'Nothing to do'
      done()

  xit 'full turn around', (done) ->
    @sphere.orders.perPage(3).fetch().then (result) =>
      @mapping.processOrders(result.body.results).then (xmlOrders) ->
        expect(_.size xmlOrders).toBe 3
        done()
    .fail (err) ->
      done err

  describe 'elastic.io', ->
    it 'nothing to do', (done) ->
      @mapping.elasticio {}, Config, (error, message) ->
        done(JSON.stringify error, null, 4) if error
        expect(message).toBe 'No data from elastic.io!'
        done()

    it 'full turn around', (done) ->
      @sphere.orders.perPage(5).fetch().then (result) =>
        msg =
          body: result.body
        @mapping.elasticio msg, Config, (error, message) ->
          done(JSON.stringify error, null, 4) if error
          expect(message.attachments).toBeDefined()
          expect(message.attachments['touch-timestamp.txt']).toBeDefined()
          done()
