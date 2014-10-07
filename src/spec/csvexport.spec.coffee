_ = require 'underscore'
_.mixin require('underscore-mixins')
CsvMapping = require '../lib/csvmapping'
exampleorders = require './exampleorders'

describe '#mapOrders', ->

  beforeEach ->
    @csvMapping = new CsvMapping()

  it 'should export base attributes', (done) ->
    template =
      """
      id,orderNumber
      """

    expectedCSV =
      """
      id,orderNumber
      abc,10001
      xyz,10002
      """

    @csvMapping.mapOrders(template, exampleorders.orders)
    .then (result) ->
      expect(result).toBe expectedCSV
      done()
    .catch (err) -> done(_.prettify err)
    .done()

  it 'should export prices', (done) ->
    template =
      """
      id,orderNumber,totalPrice,totalNet,totalGross
      """

    expectedCSV =
      """
      id,orderNumber,totalPrice,totalNet,totalGross
      abc,10001,USD 5950,USD 5000,USD 5950
      xyz,10002,USD 2380,USD 2000,USD 2380
      """

    @csvMapping.mapOrders(template, exampleorders.orders)
    .then (result) ->
      expect(result).toBe expectedCSV
      done()
    .catch (err) -> done(_.prettify err)
    .done()

  it 'export addresses', (done) ->
    template =
      """
      id,orderNumber,billingAddress.firstName,billingAddress.lastName,billingAddress.streetName,billingAddress.streetNumber,billingAddress.postalCode,billingAddress.city,billingAddress.country,shippingAddress.firstName,shippingAddress.lastName,shippingAddress.streetName,shippingAddress.streetNumber,shippingAddress.postalCode,shippingAddress.city,shippingAddress.country
      """

    expectedCSV =
      """
      id,orderNumber,billingAddress.firstName,billingAddress.lastName,billingAddress.streetName,billingAddress.streetNumber,billingAddress.postalCode,billingAddress.city,billingAddress.country,shippingAddress.firstName,shippingAddress.lastName,shippingAddress.streetName,shippingAddress.streetNumber,shippingAddress.postalCode,shippingAddress.city,shippingAddress.country
      abc,10001,John,Doe,Some Street,11,11111,Some City,US,John,Doe,Some Street,11,11111,Some City,US
      xyz,10002,Jane,Doe,Some Other Street ,22,22222,Some Other City,US,Jane,Doe,Some Other Street ,22,22222,Some Other City,US
      """

    @csvMapping.mapOrders(template, exampleorders.orders)
    .then (result) ->
      expect(result).toBe expectedCSV
      done()
    .catch (err) -> done(_.prettify err)
    .done()

  it 'export lineItems', (done) ->
    template =
      """
      id,orderNumber,lineItems.id,lineItems.productId,lineItems.name.en,lineItems.variant.variantId,lineItems.variant.sku,lineItems.quantity,lineItems.price
      """

    expectedCSV =
      """
      id,orderNumber,lineItems.id,lineItems.productId,lineItems.name.en,lineItems.variant.variantId,lineItems.variant.sku,lineItems.quantity,lineItems.price
      abc,10001,,,,,,,
      abc,10001,LineItemId-1-1,ProductId-1-1,Product-1-1,1,SKU-1-1,2,US-USD 1190
      abc,10001,LineItemId-1-2,ProductId-1-2,Product-1-2,2,SKU-1-2,3,US-USD 1190
      xyz,10002,,,,,,,
      xyz,10002,LineItemId-2-1,ProductId-2-1,Product-2-1,1,SKU-2-1,1,US-USD 2380
      """

    @csvMapping.mapOrders(template, exampleorders.orders)
    .then (result) ->
      expect(result).toBe expectedCSV
      done()
    .catch (err) -> done(_.prettify err)
    .done()

  it 'export lineItems and prices', (done) ->
    template =
      """
      id,orderNumber,lineItems.id,lineItems.productId,lineItems.name.en,lineItems.variant.variantId,lineItems.variant.sku,lineItems.quantity,lineItems.price,totalPrice,totalNet,totalGross
      """

    expectedCSV =
      """
      id,orderNumber,lineItems.id,lineItems.productId,lineItems.name.en,lineItems.variant.variantId,lineItems.variant.sku,lineItems.quantity,lineItems.price,totalPrice,totalNet,totalGross
      abc,10001,,,,,,,,USD 5950,USD 5000,USD 5950
      abc,10001,LineItemId-1-1,ProductId-1-1,Product-1-1,1,SKU-1-1,2,US-USD 1190,,,
      abc,10001,LineItemId-1-2,ProductId-1-2,Product-1-2,2,SKU-1-2,3,US-USD 1190,,,
      xyz,10002,,,,,,,,USD 2380,USD 2000,USD 2380
      xyz,10002,LineItemId-2-1,ProductId-2-1,Product-2-1,1,SKU-2-1,1,US-USD 2380,,,
      """

    @csvMapping.mapOrders(template, exampleorders.orders)
    .then (result) ->
      expect(result).toBe expectedCSV
      done()
    .catch (err) -> done(_.prettify err)
    .done()

  xit 'export lineItems and deliveries without parcels', (done) ->
    template =
      """
      id,orderNumber,lineItems.id,lineItems.name.en,lineItems.variant.sku,lineItems.quantity,lineItems.shippingInfo.deliveries.id,lineItems.shippingInfo.deliveries.items
      """

    expectedCSV =
      """
      id,orderNumber,lineItems.id,lineItems.name.en,lineItems.variant.sku,lineItems.quantity,lineItems.shippingInfo.deliveries.id,lineItems.shippingInfo.deliveries.items.id,lineItems.shippingInfo.deliveries.items.quantity
      abc,10001,,,,,,,,,
      abc,10001,LineItemId-1-1,Product-1-1,1,SKU-1-1,2,,,
      abc,10001,LineItemId-1-2,ProductId-1-2,Product-1-2,2,SKU-1-2,3,,,
      abc,10001,,,,,deliveryId-1-1,,
      abc,10001,,,,,deliveryId-1-1,LineItemId-1-1,1
      abc,10001,,,,,deliveryId-1-1,LineItemId-1-2,1
      xyz,10002,,,,,,,
      xyz,10002,LineItemId-2-1,ProductId-2-1,Product-2-1,1,SKU-2-1,1,,,
      xyz,10002,,,,,deliveryId-2-1,,
      xyz,10002,,,,,deliveryId-2-1,LineItemId-2-1,1
      """

    @csvMapping.mapOrders(template, exampleorders.orders)
    .then (result) ->
      expect(result).toBe expectedCSV
      done()
    .catch (err) -> done(_.prettify err)
    .done()

  it 'export lineItems with states', (done) ->
    template =
      """
      id,orderNumber,lineItems.id,lineItems.state
      """

    expectedCSV =
      """
      id,orderNumber,lineItems.id,lineItems.state
      abc,10001,,
      abc,10001,LineItemId-1-1,secondState:1;firstState:1;
      abc,10001,LineItemId-1-2,thirdState:1;secondState:1;firstState:1;
      xyz,10002,,
      xyz,10002,LineItemId-2-1,firstState:1;
      """

    @csvMapping.mapOrders(template, exampleorders.orders)
    .then (result) ->
      expect(result).toBe expectedCSV
      done()
    .catch (err) -> done(_.prettify err)
    .done()

  it 'export lineItems with images', (done) ->
    template =
      """
      id,orderNumber,lineItems.id,lineItems.variant.images
      """

    expectedCSV =
      """
      id,orderNumber,lineItems.id,lineItems.variant.images
      abc,10001,,
      abc,10001,LineItemId-1-1,http://www.example.org/image-1-1-3.jpg;http://www.example.org/image-1-1-2.jpg;http://www.example.org/image-1-1-1.jpg;
      abc,10001,LineItemId-1-2,
      xyz,10002,,
      xyz,10002,LineItemId-2-1,http://www.example.org/image-2-1-1.jpg;
      """

    @csvMapping.mapOrders(template, exampleorders.orders)
    .then (result) ->
      expect(result).toBe expectedCSV
      done()
    .catch (err) -> done(_.prettify err)
    .done()

  it 'export lineItems with channel', (done) ->
    template =
      """
      id,orderNumber,lineItems.id,lineItems.supplyChannel
      """

    expectedCSV =
      """
      id,orderNumber,lineItems.id,lineItems.supplyChannel
      abc,10001,,
      abc,10001,LineItemId-1-1,
      abc,10001,LineItemId-1-2,secondChannel
      xyz,10002,,
      xyz,10002,LineItemId-2-1,secondChannel
      """

    @csvMapping.mapOrders(template, exampleorders.orders)
    .then (result) ->
      expect(result).toBe expectedCSV
      done()
    .catch (err) -> done(_.prettify err)
    .done()

  it 'export orders with customerGroup', (done) ->
    template =
      """
      id,orderNumber,customerGroup
      """

    expectedCSV =
      """
      id,orderNumber,customerGroup
      abc,10001,
      xyz,10002,cool customers
      """

    @csvMapping.mapOrders(template, exampleorders.orders)
    .then (result) ->
      expect(result).toBe expectedCSV
      done()
    .catch (err) -> done(_.prettify err)
    .done()
