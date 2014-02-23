Mapping = require '../lib/mapping'
Config = require '../config'
{parseString} = require 'xml2js'

describe '#mapOrder', ->
  beforeEach ->
    @mapping = new Mapping Config

  it 'simple', (done) ->
    order =
      id: 'abc'
      version: 1
    doc = @mapping.mapOrder order
    parseString doc, (err, result) ->
      expect(result.order.xsdVersion[0]).toBe '0.8'
      expect(result.order.id[0]).toBe 'abc'
      expect(result.order.version[0]).toBe '1'
      expect(result.order.paymentState[0]).toBe 'Pending'
      expect(result.order.shipmentState[0]).toBe 'Pending'
      expect(result.order.externalCustomerId[0]).toBe 'UNKNOWN'
      done()

  it 'lineItem', (done) ->
    order =
      lineItems: [
        id: 'l1'
        name:
          de: 'mein Produkt'
        price:
          value:
            currencyCode: 'EUR'
            centAmount: 999
        quantity: 2
        taxRate:
          name: 'Mehrwertsteuer'
          amount: 0.19
          oncludedInPrice: true
          country: 'DE'
          id: 'ABC'
        variant:
          id: 1
          sku: '345'
      ]
    doc = @mapping.mapOrder order
    parseString doc, (err, result) ->
      expect(result.order.lineItems.length).toBe 1
      li = result.order.lineItems[0]
      expect(li.id[0]).toBe 'l1'
      expect(li.name[0]).toBe 'mein Produkt'
      expect(li.sku[0]).toBe '345'

      expect(li.variant[0].id[0]).toBe '1'
      expect(li.variant[0].sku[0]).toBe '345'

      expect(li.price[0].value[0].currencyCode[0]).toBe 'EUR'
      expect(li.price[0].value[0].centAmount[0]).toBe '999'

      expect(li.quantity[0]).toBe '2'

      expect(li.lineItemPrice[0].value[0].currencyCode[0]).toBe 'EUR'
      expect(li.lineItemPrice[0].value[0].centAmount[0]).toBe '1998'

      expect(li.taxRate[0].id[0]).toBe 'ABC'
      expect(li.taxRate[0].name[0]).toBe 'Mehrwertsteuer'
      expect(li.taxRate[0].amount[0]).toBe '0.19'
      expect(li.taxRate[0].country[0]).toBe 'DE'
      done()

  it 'customLineItem', (done) ->
    order =
      customLineItems: [
        id: 'cl1'
        name:
          de: 'Rabatt'
        slug: 'discount'
        money:
            currencyCode: 'EUR'
            centAmount: -700
        quantity: 3
        taxRate:
          name: 'Mehrwertsteuer'
          amount: 0.19
          oncludedInPrice: true
          country: 'DE'
          id: 'ABC'
      ]
    doc = @mapping.mapOrder order
    parseString doc, (err, result) ->
      expect(result.order.customLineItems.length).toBe 1
      cli = result.order.customLineItems[0]
      expect(cli.id[0]).toBe 'cl1'
      expect(cli.name[0]).toBe 'Rabatt'
      expect(cli.slug[0]).toBe 'discount'

      expect(cli.money[0].currencyCode[0]).toBe 'EUR'
      expect(cli.money[0].centAmount[0]).toBe '-700'

      expect(cli.quantity[0]).toBe '3'

      expect(cli.lineItemPrice[0].value[0].currencyCode[0]).toBe 'EUR'
      expect(cli.lineItemPrice[0].value[0].centAmount[0]).toBe '-2100'

      expect(cli.taxRate[0].id[0]).toBe 'ABC'
      expect(cli.taxRate[0].name[0]).toBe 'Mehrwertsteuer'
      expect(cli.taxRate[0].amount[0]).toBe '0.19'
      expect(cli.taxRate[0].country[0]).toBe 'DE'
      done()

  it 'taxedPrice', (done) ->
    order =
      taxedPrice:
        totalNet:
          currencyCode: 'EUR',
          centAmount: 1000
        totalGross:
          currencyCode: 'EUR',
          centAmount: 1190
        taxPortions: [
          rate: 'MwSt',
          amount:
            currencyCode: 'EUR',
            centAmount: 190
          ]
    doc = @mapping.mapOrder order
    parseString doc, (err, result) ->
      expect(result.order.taxedPrice).not.toBeUndefined()
      expect(result.order.taxedPrice[0].totalNet[0].currencyCode[0]).toBe 'EUR'
      expect(result.order.taxedPrice[0].totalNet[0].centAmount[0]).toBe '1000'
      expect(result.order.taxedPrice[0].totalGross[0].currencyCode[0]).toBe 'EUR'
      expect(result.order.taxedPrice[0].totalGross[0].centAmount[0]).toBe '1190'
      expect(result.order.taxedPrice[0].taxPortions[0].rate[0]).toBe 'MwSt'
      expect(result.order.taxedPrice[0].taxPortions[0].amount[0].currencyCode[0]).toBe 'EUR'
      expect(result.order.taxedPrice[0].taxPortions[0].amount[0].centAmount[0]).toBe '190'
      done()

  it 'shippingAddress', (done) ->
    order =
      shippingAddress:
        title: 'Prof. Dr.'
    doc = @mapping.mapOrder order
    parseString doc, (err, result) ->
      expect(result.order.shippingAddress).not.toBeUndefined()
      expect(result.order.shippingAddress[0].title[0]).toBe 'Prof. Dr.'
      done()

  it 'billingAddress', (done) ->
    order =
      billingAddress:
        pOBox: '123456789'
    doc = @mapping.mapOrder order
    parseString doc, (err, result) ->
      expect(result.order.billingAddress).not.toBeUndefined()
      expect(result.order.billingAddress[0].pOBox[0]).toBe '123456789'
      done()

  it 'customerGroup', (done) ->
    order =
      customerGroup:
        typeId: 'customer-group'
        id: '213'
        obj:
          id: '213'
          version: 3
          name: 'B2B'
    doc = @mapping.mapOrder order
    parseString doc, (err, result) ->
      cg = result.order.customerGroup[0]
      expect(cg.id[0]).toBe '213'
      expect(cg.version[0]).toBe '3'
      expect(cg.name[0]).toBe 'B2B'
      done()

  it 'paymentInfo', (done) ->
    order =
      paymentInfo:
        paymentID: '7'
        paymentMethod: 'Cash'
    doc = @mapping.mapOrder order
    parseString doc, (err, result) ->
      expect(result.order.paymentInfo).not.toBeUndefined()
      expect(result.order.paymentInfo[0].paymentID[0]).toBe '7'
      expect(result.order.paymentInfo[0].paymentMethod[0]).toBe 'Cash'
      done()

  it 'shippingInfo', (done) ->
    order =
      shippingInfo:
        price:
          currencyCode: 'USD'
          centAmount: 999
        taxRate:
          includedInPrice: true
    doc = @mapping.mapOrder order
    parseString doc, (err, result) ->
      expect(result.order.shippingInfo).not.toBeUndefined()
      expect(result.order.shippingInfo[0].price[0].currencyCode[0]).toBe 'USD'
      expect(result.order.shippingInfo[0].price[0].centAmount[0]).toBe '999'
      expect(result.order.shippingInfo[0].taxRate[0].includedInPrice[0]).toBe 'true'
      done()