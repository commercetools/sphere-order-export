Mapping = require '../lib/mapping.js'
sphere = require '../lib/sphere.js'
config = require('../config').config

describe "elastic.io integration", ->
  it "login", (done) ->
    sphere.login config.project_key, config.client_id, config.client_secret, (p, t) ->
      expect(t).not.toBeUndefined()
      done()

  it "getOrders", (done) ->
    sphere.login config.project_key, config.client_id, config.client_secret, (p, t) ->
      sphere.getOrders p, t, (r) ->
        expect(r).not.toBeUndefined()
        done()

  it "full turn around", (done) ->
    sphere.login config.project_key, config.client_id, config.client_secret, (p, t) ->
      sphere.getOrders p, t, (r) ->
        new Mapping().mapOrders r, (finish) ->
          done()
