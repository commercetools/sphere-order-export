_ = require 'underscore'
path = require 'path'
fs = require('fs-extra')
DeliveryExport = require './delivery-export'
utils = require './utils'

# get CLI params
argv = utils.getDefaultOptions()
  .argv

# set up logger
logger = utils.getLogger(argv, 'deliveries-export')

process.on 'SIGUSR2', -> logger.reopenFileStreams()

fs.ensureDir(argv.targetDir)
.then ->
  utils.ensureCredentials(argv)
.then (credentials) ->
  options =
    client: utils.getClientOptions(credentials, argv)
    export: _.pick(argv, 'perPage', 'where')

  deliveryExport = new DeliveryExport options, logger

  logger.debug "Created output dir at #{argv.targetDir}"

  fileName = utils.getFileName(argv.fileWithTimestamp, 'deliveries')
  fileStream = fs.createWriteStream(path.join(argv.targetDir, fileName))

  logger.info "Streaming deliveries to #{fileStream.path}"
  deliveryExport.streamCsvDeliveries(fileStream)
.then (stats) ->
  logger.info "Loaded #{stats.loadedOrders} order(s) and exported #{stats.exportedDeliveries} deliveries."
.catch (error) ->
  logger.error error, 'Oops, something went wrong!'
  process.exitCode = 1
