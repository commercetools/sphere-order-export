path = require 'path'
_ = require 'underscore'
Promise = require 'bluebird'
fs = Promise.promisifyAll require('fs')
tmp = Promise.promisifyAll require('tmp')
{ProjectCredentialsConfig, Sftp} = require 'sphere-node-utils'
package_json = require '../package.json'
OrderExport = require './orderexport'
utils = require './utils'
csv = require 'csv-parser'

CHANNEL_KEY = 'OrderXmlFileExport'

argv = utils.getDefaultOptions()
  .describe('standardShippingMethod', 'Allows to define the fallback shipping method name if order has none')
  .describe('exportUnsyncedOnly', 'whether only unsynced orders will be exported or not')
  .describe('useExportTmpDir', 'whether to use a system tmp folder to store exported files')
  .describe('csvTemplate', 'CSV template to define the structure of the export')
  .describe('createSyncActions', 'upload syncInfo update actions for orders exported (only supports sftp upload')
  .describe('fileWithTimestamp', 'whether exported file should contain a timestamp')
  .describe('sftpCredentials', 'the path to a JSON file where to read the credentials from')
  .describe('sftpHost', 'the SFTP host (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpUsername', 'the SFTP username (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpPassword', 'the SFTP password (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpTarget', 'path in the SFTP server to where to move the worked files')
  .describe('sftpContinueOnProblems', 'ignore errors when processing a file and continue with the next one')
  .describe('where', 'where predicate used to filter orders exported. More info here http://dev.commercetools.com/http-api.html#predicates')
  .describe('fillAllRows', 'fill all rows')
  .describe('exportCSVAsStream', 'Exports CSV as stream (to use for performance reasons)')
  .default('standardShippingMethod', 'None')
  .default('exportUnsyncedOnly', true)
  .default('useExportTmpDir', false)
  .default('createSyncActions', false)
  .default('sftpContinueOnProblems', false)
  .default('fillAllRows', false)
  .default('exportCSVAsStream', false)
  .argv

logger = utils.getLogger(argv)

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
    exportsPath = argv.targetDir
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

exportCSVAsStream = (csvFile, orderExport) ->
  new Promise (resolve, reject) ->
    output = fs.createWriteStream csvFile, {encoding: 'utf-8'}
    output.on 'error', (error) -> reject error
    output.on 'finish', -> resolve()
    orderExport.runCSVAndStreamToFile (data) =>
      process.stdout.write('.')
      output.write "#{data}\n"
      Promise.resolve()
    .then () ->
      process.stdout.write('\n')
      output.end()
    .catch (e) -> reject(e)

createSyncOrders = (fileName) ->
  logger.debug "Creating order objects with sync Information"
  new Promise (resolve, reject) ->
    orders = []
    orderNumberMap = {}
    fs.createReadStream(fileName)
      .pipe(csv())
      .on('data', (data) ->
        if data.orderNumber and not orderNumberMap[data.orderNumber]
          order =
            orderNumber: data.orderNumber
            syncInfo: [{
              externalId: fileName
              channel: CHANNEL_KEY
            }]
          orders.push(order)
          orderNumberMap[data.orderNumber] = true
      )
      .on('end', () ->
        logger.info "SyncInfo generated #{JSON.stringify(orders)}"
        resolve(orders)
      )
      .on 'error', (err) ->
        reject(err)

utils.ensureCredentials(argv)
.then (credentials) =>
  exportType = if argv.csvTemplate then 'csv' else 'xml'

  orderExport = new OrderExport
    client: utils.getClientOptions(credentials, argv)
    export:
      perPage: argv.perPage
      standardShippingMethod: argv.standardShippingMethod
      exportType: exportType
      exportUnsyncedOnly: argv.exportUnsyncedOnly
      csvTemplate: argv.csvTemplate
      fillAllRows: argv.fillAllRows
      where: argv.where

  ensureExportDir()
  .then (outputDir) =>
    logger.debug "Created output dir at #{outputDir}"
    @outputDir = outputDir
    if argv.exportCSVAsStream
      logger.info "Exporting orders as stream."
      fileName = utils.getFileName argv.fileWithTimestamp, 'orders'
      csvFile = argv.csvFile or "#{@outputDir}/#{fileName}"
      exportCSVAsStream(csvFile, orderExport)

    else
      orderExport.run()
      .then (data) =>
        # TODO: xml export
        # - one file for all (default)
        # - one file for each order
        @orderReferences = []
        if exportType.toLowerCase() is 'csv'
          fileName = utils.getFileName argv.fileWithTimestamp, 'orders'
          csvFile = argv.csvFile or "#{@outputDir}/#{fileName}"
          logger.info "Storing CSV export to '#{csvFile}'."
          @orderReferences.push fileName: csvFile, entry: data
          fs.writeFileAsync csvFile, data
        else
          logger.info "Storing #{_.size data} file(s) to '#{@outputDir}'."
          ts = (new Date()).getTime()
          Promise.map data, (entry) =>
            content = entry.xml.end(pretty: true, indent: '  ', newline: '\n')
            if argv.fileWithTimestamp
              fileName = "#{entry.id}_#{ts}.xml"
            else
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
              if not orderExport.ordersExported
                return Promise.resolve()

              sftpClient.safePutFile(sftp, "#{@outputDir}/#{filename}", "#{sftpTarget}/#{filename}")
              .then =>
                if exportType.toLowerCase() is 'csv' and argv.createSyncActions
                  createSyncOrders(@orderReferences[0].fileName)
                    .then (orders) =>
                      if orders.length
                        if argv.fileWithTimestamp
                          ts = (new Date()).getTime()
                          ordersFileJSON = "orders_sync_#{ts}.json"
                        else
                          ordersFileJSON = 'orders_sync.json'
                        fs.writeFileAsync("#{@outputDir}/#{ordersFileJSON}", JSON.stringify(orders,null,2)).then =>
                          logger.debug "Uploading #{@outputDir}/#{ordersFileJSON}"
                          sftpClient.safePutFile(sftp, "#{@outputDir}/#{ordersFileJSON}", "#{sftpTarget}/#{ordersFileJSON}")
                      else
                        logger.debug "No orders: #{JSON.stringify(orders, null, 2)} exported, no orders sync action to be set."
                        Promise.resolve()
                else
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
      Promise.resolve() # no sftp
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
