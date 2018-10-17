_ = require 'underscore'
Promise = require 'bluebird'
Csv = require 'csv'
access = require 'safe-access'
productJsonToCsv = require '@commercetools/product-json-to-csv'

class CsvMapping
  constructor: (@options = {}) ->
    productMapperConfig = {
      fillAllRows: true,
      categoryBy: 'slug',
      lang: 'en',
      multiValDel: ';',
      createShortcuts: true
    }

    @productMapper = new productJsonToCsv.MapProductData(productMapperConfig)

  COLUMNS_FOR_ALL_ROWS = [
    'id'
    'orderNumber'
  ]

  mapOrders: (template, orders) ->
    @_analyseTemplate(template)
    .then ([header, mappings]) =>
      rows = _.map orders, (order) =>
        @_mapOrder(order, mappings)

      data = _.flatten rows, true
      @toCSV(header, data)

  _mapOrder: (order, mappings) ->
    rows = []

    rows.push _.map mappings, (mapping) =>
      @_getValue order, mapping

    if order.lineItems? and @hasLineItemHeader?
      _.each order.lineItems, (lineItem, index) =>
        rows.push _.map mappings, (mapping) =>
          if /lineItems/.test(mapping)
            lineItemMapping = [mapping[0].replace(/lineItems/, "lineItems[#{index}]"), mapping[1]]
            @_getValue order, lineItemMapping
          else if @options.fillAllRows or _.contains COLUMNS_FOR_ALL_ROWS, mapping[0]
            @_getValue order, mapping
    rows

  _getValue: (order, mapping) ->
    # test if we want to map an attribute and parse attributeName
    attributeRegexp = /(lineItems\[.*]\.variant\.attributes)\.(.+)$/i
    # get a path to attributes array - eg: lineItems[1].variant.attributes
    # and the name of requested attribute
    attributeNames = attributeRegexp.exec(mapping[0])

    if (attributeNames isnt null)
      attributes = access order, attributeNames[1]
      return @formatProductAttributes(attributeNames[2], attributes)

    value = access order, mapping[0]
    if not value and value != 0
      return ''

    if _.size(mapping) is 2 and _.isFunction mapping[1]
      mapping[1].call this, value, mapping[0]
    else if isMoneyFormat value
      formatMoney value
    else
      # return an empty string for "lineItems.variant.attributes" for any lineItem
      # otherwise we would return an array with objects (attributes)
      if mapping[0].match(/^lineItems\[.*]\.variant\.attributes\.?$/gi)
        ''
      else
        value

  _analyseTemplate: (template) ->
    @parse(template)
    .then (data) =>
      header = data[0]
      mappings = _.map header, (entry) =>
        if /lineItems/.test entry
          @hasLineItemHeader = true
        @_mapHeader(entry)
      Promise.resolve [header, mappings]

  _mapHeader: (entry) ->
    switch entry
      when 'totalNet', 'totalGross' then ["taxedPrice.#{entry}", formatMoney]
      when 'totalPrice' then [entry, formatMoney]
      when 'lineItems.price' then [entry, formatPrice]
      when 'lineItems.state' then [entry, formatStates]
      when 'lineItems.variant.images' then [entry, formatImages]
      when 'lineItems.variant.prices' then [entry, formatVariantPrices]
      when 'lineItems.variant.availability' then [entry, formatVariantAvailability]
      when 'lineItems.supplyChannel' then [entry, formatChannel]
      when 'customerGroup' then [entry, formatCustomerGroup]
      when 'discountCodes' then [entry, formatDiscountCodes]
      when 'paymentInfo' then [entry, formatPayments]
      else [entry]

  formatPayments = (payments) ->
    return _.map(payments.payments, ({ id }) ->
      return id
    ).join(';')

  formatDiscountCodes = (discountCodes) ->
    return _.map(discountCodes, ({ discountCode: { obj: { code } } }) ->
      return code
    ).join(';')
  # TODO: Move method below to sphere-node-utils

  formatProductAttributes: (attributeName, attributes) ->
    mappedAttributes = @productMapper._mapAttributes(attributes)
    value = mappedAttributes[attributeName]

    # value can be a zero so we should check strictly if it is undefined
    if value is undefined
      value = ''
    value

  formatPrice = (price) ->
    productJsonToCsv.MapProductData._mapPriceToString(price)

  formatVariantAvailability = (availability) ->
    availability.availableQuantity

  formatVariantPrices = (prices) ->
    @productMapper._mapPricesToString(prices)

  # check if given value is an object with money fields
  isMoneyFormat = (value) ->
    moneyFields = ['centAmount', 'currencyCode']
    return _.isObject(value) and _.isEqual(moneyFields, Object.keys(value).sort())

  formatMoney = (money) ->
    "#{money.currencyCode} #{money.centAmount}"

  # states are expanded
  # TODO: Catch case that only item is present and don't show delimiter
  # TODO: Make delimiter configurable
  formatStates = (states) ->
    _.reduce states, (cell, state) ->
      "#{state.state.obj.key}:#{state.quantity};#{cell}"
    , ''

  # TODO: Catch case that only item is present and don't show delimiter
  # TODO: Make delimiter configurable
  formatImages = (images) ->
    @productMapper._mapImagesToString images

  formatChannel = (channel) ->
    if channel?
      "#{channel.obj.key}"

  formatCustomerGroup = (customerGroup) ->
    if customerGroup?
      "#{customerGroup.obj.name}"

  parse: (csvString) ->
    new Promise (resolve, reject) ->
      Csv().from.string(csvString)
      .on 'error', (error) -> reject error
      .to.array (data) -> resolve data

  toCSV: (header, data) ->
    new Promise (resolve, reject) ->
      Csv().from([header].concat data)
      .on 'error', (error) -> reject error
      .to.string (asString) -> resolve asString

  toCSVWithoutHeader: (data) ->
    new Promise (resolve, reject) ->
      Csv().from(data)
      .on 'error', (error) -> reject error
      .to.string (asString) -> resolve asString

module.exports = CsvMapping
