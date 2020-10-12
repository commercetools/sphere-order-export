_ = require 'underscore'
_.mixin require('underscore-mixins')
Mapping = require '../lib/mapping-utils/csv'
testOrders = require '../data/orders'

template = 'id,orderNumber,totalPrice,customLineItems.id,customLineItems.slug,customLineItems.quantity,lineItems.id,lineItems.productId,billingAddress.firstName'

describe 'CsvMapping', ->
  it '#_mapOrder should remove redundant info', (done) ->
    mapping = new Mapping
    mapping._analyseTemplate template
    .then ([header, mappings]) ->
      rows = mapping._mapOrder(testOrders[0], mappings)
      expect(rows.length).toBe 4
      expect(rows).toEqual [
        [ 'abc', '10001', 'USD 5950', "", "", "", '', '', 'John' ],
        [ 'abc',
          '10001',
          undefined,
          undefined,
          undefined,
          undefined,
          'LineItemId-1-1',
          'ProductId-1-1',
          undefined ],
        [ 'abc',
          '10001',
          undefined,
          undefined,
          undefined,
          undefined,
          'LineItemId-1-2',
          'ProductId-1-2',
          undefined ],
          [ 'abc',
          '10001',
          undefined,
          "64d8843b-3b53-497c-8d31-fcca82bee6f3",
          "slug",
          1,
          undefined,
          undefined,
          undefined ]
      ]
      done()

  it '#_mapOrder should fill all rows', (done) ->
    mapping = new Mapping fillAllRows: true
    mapping._analyseTemplate template
    .then ([header, mappings]) ->
      rows = mapping._mapOrder(testOrders[0], mappings)
      expect(rows.length).toBe 4
      expect(rows).toEqual [
        [ 'abc', '10001', 'USD 5950', '', '', '', '', '', 'John' ],
        [ 'abc',
          '10001',
          'USD 5950',
          '',
          '',
          '',
          'LineItemId-1-1',
          'ProductId-1-1',
          'John' ],
        [ 'abc',
          '10001',
          'USD 5950',
          "",
          "",
          "",
          'LineItemId-1-2',
          'ProductId-1-2',
          'John' ],
          [ 'abc',
          '10001',
          'USD 5950',
          "64d8843b-3b53-497c-8d31-fcca82bee6f3",
          "slug",
          1,
          '',
          '',
          'John' ]
      ]
      done()

  it '#_mapOrder should return order even when lineItems are missing', (done) ->
    mapping = new Mapping fillAllRows: true
    mapping._analyseTemplate template
    .then ([header, mappings]) ->
      order = _.deepClone(testOrders[0])
      order.lineItems = []

      rows = mapping._mapOrder(order, mappings)
      expect(rows.length).toBe 2
      expect(rows).toEqual [
        [ 'abc', '10001', 'USD 5950', '', '', '', '', '', 'John' ],
        [ 'abc', '10001', 'USD 5950', '64d8843b-3b53-497c-8d31-fcca82bee6f3', 'slug', 1, '', '', 'John' ],
      ]
      done()
