_ = require 'underscore'
Promise = require 'bluebird'
fs = Promise.promisifyAll require('fs')
tmp = Promise.promisifyAll require('tmp')
{ExtendedLogger, ProjectCredentialsConfig, Sftp} = require 'sphere-node-utils'
package_json = require '../package.json'
OrderExport = require '../lib/orderexport'

argv = require('optimist')
  .usage('Usage: $0 --projectKey key --clientId id --clientSecret secret')
  .describe('projectKey', 'your SPHERE.IO project-key')
  .describe('clientId', 'your OAuth client id for the SPHERE.IO API')
  .describe('clientSecret', 'your OAuth client secret for the SPHERE.IO API')
  .describe('sphereHost', 'SPHERE.IO API host to connecto to')
  .describe('fetchHours', 'Number of hours to fetch modified orders')
  .describe('standardShippingMethod', 'Allows to define the fallback shipping method name of order has none')
  .describe('useExportTmpDir', 'whether to use a tmp folder to store resulting XML files in or not (if no, files will be created under \'./exports\')')
  .describe('csvTemplate', 'CSV template to define the structure of the export - if present only one CSV file will be generated, otherwise XML files')
  .describe('csvFile', "CSV file to export template to, otherwise see option 'useExportTmpDir'")
  .describe('sftpCredentials', 'the path to a JSON file where to read the credentials from')
  .describe('sftpHost', 'the SFTP host (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpUsername', 'the SFTP username (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpPassword', 'the SFTP password (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpTarget', 'path in the SFTP server to where to move the worked files')
  .describe('sftpContinueOnProblems', 'ignore errors when processing a file and continue with the next one')
  .describe('logLevel', 'log level for file logging')
  .describe('logDir', 'directory to store logs')
  .describe('logSilent', 'use console to print messages')
  .describe('timeout', 'Set timeout for requests')
  .default('fetchHours', 0) # by default don't restrict on modifications
  .default('standardShippingMethod', 'None')
  .default('useExportTmpDir', false)
  .default('logLevel', 'info')
  .default('logDir', '.')
  .default('logSilent', false)
  .default('timeout', 60000)
  .default('sftpContinueOnProblems', false)
  .demand(['projectKey'])
  .argv

logOptions =
  name: "#{package_json.name}-#{package_json.version}"
  streams: [
    { level: 'error', stream: process.stderr }
    { level: argv.logLevel, path: "#{argv.logDir}/sphere-order-xml-export.log" }
  ]
logOptions.silent = argv.logSilent if argv.logSilent
logger = new ExtendedLogger
  additionalFields:
    project_key: argv.projectKey
  logConfig: logOptions
if argv.logSilent
  logger.bunyanLogger.trace = -> # noop
  logger.bunyanLogger.debug = -> # noop

process.on 'SIGUSR2', -> logger.reopenFileStreams()
process.on 'exit', => process.exit(@exitCode)

tmp.setGracefulCleanup()

fsExistsAsync = (path) ->
  new Promise (resolve, reject) ->
    fs.exists path, (exists) ->
      if exists
        resolve(true)
      else
        resolve(false)

ensureExportDir = ->
  if "#{argv.useExportTmpDir}" is 'true'
    # unsafeCleanup: recursively removes the created temporary directory, even when it's not empty
    tmp.dirAsync {unsafeCleanup: true}
  else
    exportsPath = "#{__dirname}/../exports"
    fsExistsAsync(exportsPath)
    .then (exists) ->
      if exists
        Promise.resolve(exportsPath)
      else
        fs.mkdirAsync(exportsPath)
        .then -> Promise.resolve(exportsPath)

readJsonFromPath = (path) ->
  return Promise.resolve({}) unless path
  fs.readFileAsync(path, {encoding: 'utf-8'}).then (content) ->
    Promise.resolve JSON.parse(content)

isCsvMode = -> argv.csvTemplate?

ProjectCredentialsConfig.create()
.then (credentials) =>
  options =
    config: credentials.enrichCredentials
      project_key: argv.projectKey
      client_id: argv.clientId
      client_secret: argv.clientSecret
    timeout: argv.timeout
    user_agent: "#{package_json.name} - #{package_json.version}"
  options.host = argv.sphereHost if argv.sphereHost
  options.standardShippingMethod = argv.standardShippingMethod

  orderExport = new OrderExport options
  client = orderExport.client

  ensureExportDir()
  .then (outputDir) =>
    logger.debug "Created output dir at #{outputDir}"
    @outputDir = outputDir
    client.orders.all()
    .expand('lineItems[*].state[*].state')
    .expand('lineItems[*].supplyChannel')
    .expand('customerGroup')
    .last("#{argv.fetchHours}h")
    .fetch()
  .then (result) ->
    orderExport.processOrders(result.body.results, argv.csvTemplate)
  .then (result) =>
    @orderReferences = []
    if isCsvMode()
      csvFile = argv.csvFile or "#{@outputDir}/orders.csv"
      logger.info "Storing CSV export to '#{csvFile}'."
      # TODO: timestamp option
      fileName = 'orders.csv'
      fs.writeFileAsync csvFile, result
    else
      logger.info "Storing #{_.size result} file(s) to '#{@outputDir}'."
      Promise.map result, (entry) =>
        content = entry.xml.end(pretty: true, indent: '  ', newline: '\n')
        fileName = "#{entry.id}.xml"
        @orderReferences.push name: fileName, entry: entry
        fs.writeFileAsync "#{@outputDir}/#{fileName}", content
      , {concurrency: 10}
  .then =>
    {sftpCredentials, sftpHost, sftpUsername, sftpPassword} = argv
    if sftpCredentials or (sftpHost and sftpUsername and sftpPassword)

      readJsonFromPath(sftpCredentials)
      .then (credentials) =>
        projectSftpCredentials = credentials[argv.projectKey] or {}
        {host, username, password, sftpTarget} = _.defaults projectSftpCredentials,
          host: sftpHost
          username: sftpUsername
          password: sftpPassword
          sftpTarget: argv.sftpTarget

        throw new Error 'Missing sftp host' unless host
        throw new Error 'Missing sftp username' unless username
        throw new Error 'Missing sftp password' unless password

        sftpClient = new Sftp
          host: host
          username: username
          password: password
          logger: logger

        sftpClient.openSftp()
        .then (sftp) =>
          fs.readdirAsync(@outputDir)
          .then (files) =>
            logger.info "About to upload #{_.size files} file(s) from #{@outputDir} to #{sftpTarget}"
            filesSkipped = 0
            Promise.map files, (filename) =>
              logger.debug "Uploading #{@outputDir}/#{filename}"
              sftpClient.safePutFile(sftp, "#{@outputDir}/#{filename}", "#{sftpTarget}/#{filename}")
              .then =>
                xml = _.find @orderReferences, (r) -> r.name is filename
                if xml
                  logger.debug "About to sync order #{filename}"
                  orderExport.syncOrder xml.entry, filename
                else
                  logger.warn "Not able to create syncInfo for #{filename} as xml for that file was not found"
                  Promise.resolve()
              .catch (err) ->
                if argv.sftpContinueOnProblems
                  filesSkipped++
                  logger.warn err, "There was an error processing the file #{file}, skipping and continue"
                  Promise.resolve()
                else
                  Promise.reject err
            , {concurrency: 1}
            .then ->
              totFiles = _.size(files)
              if totFiles > 0
                logger.info "Export to SFTP successfully finished: #{totFiles - filesSkipped} out of #{totFiles} files were processed"
              else
                logger.info "Export successfully finished: there were no new files to be processed"
              sftpClient.close(sftp)
              Promise.resolve()
          .finally -> sftpClient.close(sftp)
        .catch (err) =>
          logger.error err, 'There was an error uploading the files to SFTP'
          @exitCode = 1
      .catch (err) =>
        logger.error err, "Problems on getting sftp credentials from config files for project #{argv.projectKey}."
        @exitCode = 1
    else
      Promise.resolve()
  .then =>
    logger.info 'Orders export complete'
    @exitCode = 0
  .catch (error) =>
    logger.error error, 'Oops, something went wrong!'
    @exitCode = 1
  .done()

.catch (err) =>
  logger.error err, 'Problems on getting client credentials from config files.'
  @exitCode = 1
.done()
