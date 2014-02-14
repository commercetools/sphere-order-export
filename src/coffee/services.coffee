builder = require 'xmlbuilder'

class Mapping

  BASE64 = 'base64'

  debug: (msg) ->
    console.log "DEBUG: #{msg}"

  process: (msg, cfg, next) ->
    @debug 'process'
    @mapOrders(msg.body, next)

  mapOrders: (json, finish) ->
    orders = json.results
    @debug "mapOrders: #{orders.length}"

    now = new Buffer(new Date().toISOString()).toString(@BASE64)
    data =
      body: {}
      attachments:
        'touch-timestamp.txt':
          content: now

    for order in orders
      xmlOrder = @mapOrder(order)
      @debug(xmlOrder)
      fileName = "#{order.id}.xml"
      base64 = new Buffer(xmlOrder).toString(@BASE64)
      data.attachments[fileName] =
        content: base64

    finish(null, data)

  mapOrder: (order) ->
    @debug("mapOrder: #{order.id}") if order.id

    xml = builder.create("order", { "version": "1.0", "encoding": "UTF-8", "standalone": true })
    xml.e("xsdVersion").t("0.8")

    xml.e("externalCustomerId").t("UNKNOWN").up()

    attribs = [ "id", "version", "createdAt", "lastModifiedAt", "customerId", "customerEmail",
                "country", "orderState", "shipmentState", "paymentState" ]

    for attr in attribs
      @add(xml, order, attr)

    if order.taxedPrice
      price = order.taxedPrice
      xPrice = xml.e("taxedPrice")
      @money(xPrice, price, "totalNet")
      @money(xPrice, price, "totalGross")

      for tax in price.taxPortions
        xT = xPrice.e("taxPortions")
        xT.e("rate").t(tax.rate)
        @money(xT, tax, "amount")

    if order.shippingAddress
      @mapAddress(xml.e("shippingAddress"), order.shippingAddress)

    if order.billingAddress
      @mapAddress(xml.e("billingAddress"), order.billingAddress)

    @customerGroup(xml, order)

    if order.paymentInfo
      pi = order.paymentInfo
      xPi = xml.e("paymentInfo")
      @add(xPi, pi, "paymentMethod")
      @add(xPi, pi, "paymentID")

    if order.shippingInfo
      si = order.shippingInfo
      xSi = xml.e("shippingInfo")
      @add(xSi, si, "shippingMethodName")
      @add(xSi, si, "trackingData")

      @money(xSi, si, "price")
      @taxRate(xSi, si)

    if order.lineItems
      for lineItem in order.lineItems
        xLi = xml.e("lineItems")
        @add(xLi, lineItem, "id")
        @add(xLi, lineItem, "productId")
        @add(xLi, lineItem.name, "de", "name")

        variant = lineItem.variant
        xVariant = xLi.e("variant")
        @add(xVariant, variant, "id")
        @add(xVariant, variant, "sku")
        if variant.prices
          for price in variant.prices
            @priceElem(xVariant.e("prices"), price)

        if variant.attributes
          for attr in variant.attributes
            @attributes(xVariant.e("attributes"), attr)

        # Adds sku again directly to the lineItem
        @add(xLi, variant, "sku")

        @price(xLi, lineItem)
        @add(xLi, lineItem, "quantity")

        # Adds lineItem price
        @lineItemPrice xLi, lineItem.price.value.centAmount, lineItem.quantity, lineItem.price.value.currencyCode

        @taxRate(xLi, lineItem)

    if order.customLineItems
      for customLineItem in order.customLineItems
        @customLineItem(xml.e("customLineItems"), customLineItem)

    xml.end(pretty: true, indent: "  ", newline: "\n")

  customLineItem: (xml, elem) ->
    @add(xml, elem, "id")
    @add(xml, elem.name, "de", "name")
    @money(xml, elem, "money")
    @add(xml, elem, "slug")
    @add(xml, elem, "quantity")
    @lineItemPrice xml, elem.money.centAmount, elem.quantity, elem.money.currencyCode
    @taxRate(xml, elem)

  attributes: (xml, elem) ->
    xml.e("name").t(elem.name).up()
      .e("value").t(elem.value)

  money: (xml, elem, name) ->
    xml.e(name)
      .e("currencyCode").t(elem[name].currencyCode).up()
      .e("centAmount").t(elem[name].centAmount)

  price: (xml, elem, name="price") ->
    @priceElem(xml.e(name), elem.price)

  priceElem: (xP, p) ->
    @money(xP, p, "value")
    @add(xP, p, "country")
    @customerGroup(xP, p)

  lineItemPrice: (xml, centAmount, quantity, currencyCode) ->
    total = centAmount * quantity
    p =
      price:
        value:
          currencyCode: currencyCode
          centAmount: total
    @price(xml, p, "lineItemPrice")

  taxRate: (xml, elem) ->
    tr = elem.taxRate
    xTr = xml.e("taxRate")
    attribs = [ "id", "name", "amount", "includedInPrice", "country", "state" ]
    for attr in attribs
      @add(xTr, tr, attr)

  customerGroup: (xml, elem) ->
    cg = elem.customerGroup
    if cg
      xCg = xml.e("customerGroup")
      @add(xCg, cg, "id")
      if cg.obj
        @add(xCg, cg.obj, "version")
        @add(xCg, cg.obj, "name")

  mapAddress: (xml, address) ->
    attribs = [ "id", "title", "salutation", "firstName", "lastName", "streetName", "streetNumber", "additionalStreetInfo", "postalCode",
                "city", "region", "state", "country", "company", "department", "building", "apartment", "pOBox", "phone", "mobile", "email" ]
    for attr in attribs
      @add(xml, address, attr)

  add: (xml, elem, attr, xAttr) ->
    xAttr = attr unless xAttr

    value = elem[attr]
    xml.e(xAttr).t(value).up() if value

module.exports = Mapping