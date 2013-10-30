querystring = require "querystring"
builder     = require "xmlbuilder"

debug = (msg)-> console.log "DEBUG: #{msg}"

exports.process = (msg, cfg, next)->
  debug "process"
  exports.mapOrders(msg.body, next)

exports.mapOrders = (json, finish)->
  orders = json.results
  debug "mapOrders: #{orders.length}"

  now = new Buffer(new Date().toISOString()).toString("base64")
  data =
    body: {}
    attachments:
      "touch-timestamp.txt":
        content: now

  for order in orders
    xmlOrder = exports.mapOrder(order)
    debug(xmlOrder)
    fileName = "#{order.id}.xml"
    base64 = new Buffer(xmlOrder).toString("base64")
    data.attachments[fileName] =
      content: base64

  finish(null, data)

exports.mapOrder = (order)->
  debug("mapOrder: #{order.id}") if order.id

  xml = builder.create("order", { "version": "1.0", "encoding": "UTF-8", "standalone": true })
  xml.e("xsdVersion").t("0.6")
  attribs = [ "id", "version", "createdAt", "lastModifiedAt", "customerId", "customerEmail",
              "eevoCusomterId", "country", "orderState", "shipmentState", "paymentState" ]

  for attr in attribs
    exports.add(xml, order, attr)

  if order.taxedPrice
    price = order.taxedPrice
    xPrice = xml.e("taxedPrice")
    exports.money(xPrice, price, "totalNet")
    exports.money(xPrice, price, "totalGross")

    for tax in price.taxPortions
      xT = xPrice.e("taxPortions")
      xT.e("rate").t(tax.rate)
      exports.money(xT, tax, "amount")

  if order.shippingAddress
    exports.mapAddress(xml.e("shippingAddress"), order.shippingAddress)

  if order.billingAddress
    exports.mapAddress(xml.e("billingAddress"), order.billingAddress)

  exports.customerGroup(xml, order)

  if order.paymentInfo
    pi = order.paymentInfo
    xPi = xml.e("paymentInfo")
    exports.add(xPi, pi, "paymentMethod")
    exports.add(xPi, pi, "paymentID")

  if order.shippingInfo
    si = order.shippingInfo
    xSi = xml.e("shippingInfo")
    exports.add(xSi, si, "shippingMethodName")
    exports.add(xSi, si, "trackingData")

    exports.money(xSi, si, "price")
    exports.taxRate(xSi, si)

  if order.lineItems
    for lineItem in order.lineItems
      xLi = xml.e("lineItems")
      exports.add(xLi, lineItem, "id")
      exports.add(xLi, lineItem, "productId")
      exports.add(xLi, lineItem.name, "de", "name")

      variant = lineItem.variant
      xVariant = xLi.e("variant")
      exports.add(xVariant, variant, "id")
      exports.add(xVariant, variant, "sku")
      if variant.prices
        for price in variant.prices
          exports.priceElem(xVariant.e("prices"), price)

      if variant.attributes
        for attr in variant.attributes
          exports.attributes(xVariant.e("attributes"), attr)

      exports.price(xLi, lineItem)
      exports.add(xLi, lineItem, "quantity")
      exports.taxRate(xLi, lineItem)

  if order.customLineItems
    for customLineItem in order.customLineItems
      exports.customLineItem(xml.e("customLineItems"), customLineItem)

  xml.end(pretty: true, indent: "  ", newline: "\n")

exports.customLineItem = (xml, elem)->
  exports.add(xml, elem, "id")
  exports.add(xml, elem.name, "de", "name")
  exports.money(xml, elem, "money")
  exports.add(xml, elem, "slug")
  exports.add(xml, elem, "quantity")

  #    "taxCategory" : {
  #      "id" : "2246b2fb-0531-47dd-84ec-c004d7fef3ce",
  #     "typeId" : "tax-category"
  #    }

exports.attributes = (xml, elem)->
  xml.e("name").t(elem.name).up()
    .e("value").t(elem.value)

exports.money = (xml, elem, name)->
  xml.e(name)
    .e("currencyCode").t(elem[name].currencyCode).up()
    .e("centAmount").t(elem[name].centAmount)

exports.price = (xml, elem)->
  exports.priceElem(xml.e("price"), elem.price)

exports.priceElem = (xP, p)->
  exports.money(xP, p, "value")
  exports.add(xP, p, "country")
  exports.customerGroup(xP, p)

exports.taxRate = (xml, elem)->
  tr = elem.taxRate
  xTr = xml.e("taxRate")
  attribs = [ "id", "name", "amount", "includedInPrice", "country", "state" ]
  for attr in attribs
    exports.add(xTr, tr, attr)

exports.customerGroup = (xml, elem)->
  cg = elem.customerGroup
  if cg
    xCg = xml.e("customerGroup")
    exports.add(xCg, cg, "id")
    exports.add(xCg, cg, "version")
    exports.add(xCg, cg, "name")

exports.mapAddress = (xml, address)->
  attribs = [ "id", "title", "salutation", "firstName", "lastName", "streetName", "streetNumber", "additionalStreetInfo", "postalCode",
              "city", "region", "state", "country", "company", "department", "building", "apartment", "pOBox", "phone", "mobile", "email" ]
  for attr in attribs
    exports.add(xml, address, attr)

exports.add = (xml, elem, attr, xAttr)->
  xAttr = attr unless xAttr

  value = elem[attr]
  xml.e(xAttr).t(value).up() if value
