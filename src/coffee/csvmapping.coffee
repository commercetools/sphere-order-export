_ = require 'underscore'
Q = require 'q'
Csv = require 'csv'
access = require('safe-access')

class CsvMapping

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
          else
            @_getValue order, mapping

    rows

  _getValue: (order, mapping) ->
    value = access order, mapping[0]
    if _.size(mapping) is 2 and _.isFunction mapping[1]
      mapping[1].call undefined, value
    else
      value

  _analyseTemplate: (template) ->
    @parse(template)
    .then (header) =>
      mappings = _.map header, (entry) =>
        if /lineItems/.test entry
          @hasLineItemHeader = true
        @_mapHeader(entry)
      Q [header, mappings]

  _mapHeader: (entry) ->
    switch entry
      when 'totalNet', 'totalGross' then ["taxedPrice.#{entry}", formatMoney]
      when 'totalPrice' then [entry, formatMoney]
      when 'lineItems.price' then [entry, formatPrice]
      when 'lineItems.state' then [entry, formatStates]
      when 'lineItems.variant.images' then [entry, formatImages]
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

  parse: (csvString) ->
    deferred = Q.defer()

    Csv().from.string(csvString)
    .to.array (data) ->
      deferred.resolve data[0]

    .on 'error', (error) ->
      deferred.reject error

    deferred.promise

  toCSV: (header, data) ->
    deferred = Q.defer()

    Csv().from([header].concat data)
    .to.string (asString) ->
      deferred.resolve asString
    .on 'error', (error) ->
      deferred.reject error

    deferred.promise


module.exports = CsvMapping