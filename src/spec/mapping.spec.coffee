basedir = "../../build/app/"

services = require basedir + "services.js"
{parseString} = require "xml2js"
libxmljs = require "libxmljs"

describe "validateXML", ->
  xit "validate", ->
    xsd = "
    xsdDoc = libxmljs.parseXmlString(xsd)

    xml = "
    xmlDoc = libxmljs.parseXmlString(xml)
    expect(xmlDoc.validate(xsdDoc)).toBe true


describe "#mapOrder", ->
  it "simple", ->
    o = {
      "id":"abc",
      "version":1
    }
    doc = services.mapOrder(o)
    console.log(doc)
    parseString doc, (err, result) ->
      expect(result.order.xsdVersion[0]).toBe "0.6"
      expect(result.order.id[0]).toBe "abc"
      expect(result.order.version[0]).toBe "1"
      expect(result.order.orderState).toBeUndefined()

  it "taxedPrice", ->
    o = {
      "taxedPrice": {
        "totalNet": {
          "currencyCode": "EUR",
          "centAmount": 1000
        },
        "totalGross": {
          "currencyCode": "EUR",
          "centAmount": 1190
        },
        "taxPortions": [{
          "rate": "MwSt",
          "amount": {
            "currencyCode": "EUR",
            "centAmount": 190
          }
        }]
      }
    }
    doc = services.mapOrder(o)
    console.log(doc)
    parseString doc, (err, result) ->
      expect(result.order.taxedPrice).not.toBeUndefined()
      expect(result.order.taxedPrice[0].totalNet[0].currencyCode[0]).toBe "EUR"
      expect(result.order.taxedPrice[0].totalNet[0].centAmount[0]).toBe "1000"
      expect(result.order.taxedPrice[0].totalGross[0].currencyCode[0]).toBe "EUR"
      expect(result.order.taxedPrice[0].totalGross[0].centAmount[0]).toBe "1190"
      expect(result.order.taxedPrice[0].taxPortions[0].rate[0]).toBe "MwSt"
      expect(result.order.taxedPrice[0].taxPortions[0].amount[0].currencyCode[0]).toBe "EUR"
      expect(result.order.taxedPrice[0].taxPortions[0].amount[0].centAmount[0]).toBe "190"

  it "shippingAddress", ->
    o = {
      "shippingAddress": {
        "title": "Prof. Dr."
      }
    }
    doc = services.mapOrder(o)
    console.log(doc)
    parseString doc, (err, result) ->
      expect(result.order.shippingAddress).not.toBeUndefined()
      expect(result.order.shippingAddress[0].title[0]).toBe "Prof. Dr."

  it "billingAddress", ->
    o = {
      "billingAddress": {
        "pOBox": "123456789"
      }
    }
    doc = services.mapOrder(o)
    console.log(doc)
    parseString doc, (err, result) ->
      expect(result.order.billingAddress).not.toBeUndefined()
      expect(result.order.billingAddress[0].pOBox[0]).toBe "123456789"

  it "customerGroup", ->
    o = {
      "customerGroup": {
        "name": "B2B"
      }
    }
    doc = services.mapOrder(o)
    console.log(doc)
    parseString doc, (err, result) ->
      expect(result.order.customerGroup).not.toBeUndefined()
      expect(result.order.customerGroup[0].name[0]).toBe "B2B"

  it "paymentInfo", ->
    o = {
      "paymentInfo": {
        "paymentID": "7"
        "paymentMethod": "Cash"
      }
    }
    doc = services.mapOrder(o)
    console.log(doc)
    parseString doc, (err, result) ->
      expect(result.order.paymentInfo).not.toBeUndefined()
      expect(result.order.paymentInfo[0].paymentID[0]).toBe "7"
      expect(result.order.paymentInfo[0].paymentMethod[0]).toBe "Cash"

  it "shippingInfo", ->
    o = {
      "shippingInfo": {
        "price": {
          "currencyCode": "USD",
          "centAmount": 999
        },
        "taxRate": {
          "includedInPrice": true
        }
      }
    }
    doc = services.mapOrder(o)
    console.log(doc)
    parseString doc, (err, result) ->
      expect(result.order.shippingInfo).not.toBeUndefined()
      expect(result.order.shippingInfo[0].price[0].centAmount[0]).toBe "999"
      expect(result.order.shippingInfo[0].taxRate[0].includedInPrice[0]).toBe "true"