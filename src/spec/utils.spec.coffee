_ = require 'underscore'
tmp = require 'tmp'
packageJson = require '../package'
utils = require '../lib/utils'

tmpDir = tmp.dirSync()

describe 'Utils', ->

  it '#getFileName should return a fileName based on arguments', ->
    fileName = utils.getFileName(false, 'orders')
    expect(fileName).toBe 'orders.csv'

    fileName = utils.getFileName(false, 'orders', '1234')
    expect(fileName).toBe 'orders.csv'

    fileName = utils.getFileName(true, 'orders', '1234')
    expect(fileName).toBe 'orders_1234.csv'

  it '#getClientOptions should return a simple client options object', ->
    credentials =
      config:
        project_key: 'project-key'
      access_token: 'access-token'

    args =
      timeout: 100

    res = utils.getClientOptions(credentials, args)
    expect(res).toEqual
      config:
        project_key: 'project-key'
      access_token: 'access-token'
      user_agent: "#{packageJson.name} - #{packageJson.version}"
      timeout: 100

  it '#getClientOptions should return a complex client options object', ->
    credentials =
      config:
        project_key: 'project-key'
      access_token: 'access-token'

    args =
      timeout: 100
      sphereHost: 'host'
      sphereProtocol: 'http'
      sphereAuthHost: '123'
      sphereAuthProtocol: 'https'

    res = utils.getClientOptions(credentials, args)
    expect(res).toEqual
      config:
        project_key: 'project-key'
      access_token: 'access-token'
      user_agent: "#{packageJson.name} - #{packageJson.version}"
      host: 'host'
      timeout: 100
      protocol: 'http'
      oauth_host: '123'
      oauth_protocol: 'https'
      rejectUnauthorized: false

  it '#getDefaultOptions should return an optimist object', ->
    argv = utils.getDefaultOptions()
    expect(argv.help).toBeDefined()
    expect(argv.help()).toContain('Usage:')

  it '#getLogger should return a logger instance', ->
    args =
      projectKey: 'myProjectKey'
      logDir: tmpDir.name

    logger = utils.getLogger(args)
    expect(logger.additionalFields.project_key).toBe('myProjectKey')
    expect(logger.error).toBeDefined()
    expect(logger.info).toBeDefined()
    expect(logger.debug).toBeDefined()
    expect(logger.warn).toBeDefined()
    expect(logger.debug).toBeDefined()
    expect(logger.trace).toBeDefined()

  it '#ensureCredentials should return credentials with accessToken', (done) ->
    args =
      accessToken: 'myAccessToken'
      projectKey: 'myProjectKey'

    utils.ensureCredentials args
      .then (credentials) ->
        expect(credentials).toEqual
          config:
            project_key: 'myProjectKey'
          access_token: 'myAccessToken'
        done()
      .catch (e) -> done (e or 'Undefined error')

  it '#ensureCredentials should return credentials from env variables', (done) ->
    args =
      projectKey: 'myProjectKey'

    process.env.SPHERE_PROJECT_KEY = args.projectKey
    process.env.SPHERE_CLIENT_ID = 'myProjectId'
    process.env.SPHERE_CLIENT_SECRET = 'myProjectSecret'

    utils.ensureCredentials args
      .then (credentials) ->
        expect(credentials).toEqual
          config:
            project_key: 'myProjectKey'
            client_id: 'myProjectId'
            client_secret: 'myProjectSecret'
        done()
      .catch (e) -> done (e or 'Undefined error')
