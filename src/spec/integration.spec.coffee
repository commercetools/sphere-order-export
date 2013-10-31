basedir = "../../build/app/"

services = require basedir + "services.js"
sphere = require basedir + "sphere.js"
config = require('../../config').config

describe "elastic.io integration", ->
  it "login", ->
    sphere.login(config.project_key, config.client_id, config.client_secret, (p, t) ->
      expect(t).not.toBeUndefined()
      asyncSpecDone()
    )
    asyncSpecWait()

  it "getOrders", ->
    sphere.login(config.project_key, config.client_id, config.client_secret, (p, t) ->
      sphere.getOrders(p, t, (r) ->
        expect(r).not.toBeUndefined()
        asyncSpecDone()
      )
    )
    asyncSpecWait()

  it "full turn around", ->
    sphere.login(config.project_key, config.client_id, config.client_secret, (p, t) ->
      sphere.getOrders(p, t, (r) ->
        services.mapOrders(r, (finish) ->
          asyncSpecDone()
        )
      )
    )
    asyncSpecWait()
