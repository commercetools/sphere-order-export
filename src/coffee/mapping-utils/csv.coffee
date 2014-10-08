_ = require 'underscore'
Promise = require 'bluebird'
Csv = require 'csv'
access = require 'safe-access'

class CsvMapping

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
          else if _.contains COLUMNS_FOR_ALL_ROWS, mapping[0]
            @_getValue order, mapping

    rows

  _getValue: (order, mapping) ->
    value = access order, mapping[0]
    return '' unless value
    if _.size(mapping) is 2 and _.isFunction mapping[1]
      mapping[1].call undefined, value
    else
      value or ''

  _analyseTemplate: (template) ->
    @parse(template)
    .then (header) =>
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
      when 'lineItems.supplyChannel' then [entry, formatChannel]
      when 'customerGroup' then [entry, formatCustomerGroup]
      else [entry]

  # TODO: Move method below to sphere-node-utils
  formatPrice = (price) ->
    if price?.value?
      countryPart = ''
      if price.country?
        countryPart = "#{price.country}-"
      customerGroupPart = ''
      if price.customerGroup?
        customerGroupPart = " #{price.customerGroup.id}"
      channelKeyPart = ''
      if price.channel?
        channelKeyPart = "##{price.channel.id}"
      "#{countryPart}#{price.value.currencyCode} #{price.value.centAmount}#{customerGroupPart}#{channelKeyPart}"

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
    _.reduce images, (cell, image) ->
      "#{image.url};#{cell}"
    , ''

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
      .to.array (data) -> resolve data[0]

  toCSV: (header, data) ->
    new Promise (resolve, reject) ->
      Csv().from([header].concat data)
      .on 'error', (error) -> reject error
      .to.string (asString) -> resolve asString

module.exports = CsvMapping
