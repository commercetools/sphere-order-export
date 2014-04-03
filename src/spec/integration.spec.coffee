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
    @mapping.mapOrders([]).then (xmlOrders) ->
      expect(xmlOrders).toEqual []
      done()

  it 'full turn around', (done) ->
    @sphere.orders.perPage(3).fetch().then (result) =>
      @mapping.mapOrders(result.body.results).then (xmlOrders) ->
        expect(_.size xmlOrders).toBe 3
        done()

  describe 'elastic.io', ->
    it 'nothing to do', (done) ->
      @mapping.elasticio {}, Config, (error, message) ->
        expect(error).toBe null
        expect(message).toBe 'No data from elastic.io!'
        done()

    it 'full turn around', (done) ->
      @sphere.orders.perPage(5).fetch().then (result) =>
        msg =
          body: result.body
        @mapping.elasticio msg, Config, (error, message) ->
          console.log error
          expect(error).toBe null
          expect(message.attachments).toBeDefined()
          expect(message.attachments['touch-timestamp.txt']).toBeDefined()
          console.log message.attachments['touch-timestamp.txt'].content
          done()
