exports.orders =
[{
  id: 'abc'
  orderNumber: '10001'
  version: 1
  lineItems: [
    id: 'LineItemId-1-1'
    productId: 'ProductId-1-1'
    name:
      { en: 'Product-1-1' }
    variant: {
      variantId: 1
      sku: 'SKU-1-1'
      images: []
      attributes: []
    }
    quantity: 1
    price: {
      country: 'US'
      value: {
        currencyCode: 'USD'
        centAmount: 1190
      }
    }
    taxRate: {
      name: 'Standard Tax Rate'
      amount: 0.19
      includedInPrice: true
      id: 'taxRateId'
      country: 'US'
    }
  ]
  customLineItems: []
  totalPrice: {
    currencyCode: 'USD'
    centAmount: 1190
  }
  taxedPrice: {
    totalNet: {
      currencyCode: 'USD'
      centAmount: 1000
    }
    totalGross: {
      currencyCode: 'USD'
      centAmount: 1190
    }
    taxPortions: [{
      amount: {
        currencyCode: 'USD'
        centAmount: 190
      }
      rate: 0.19
    }]
  }
  shippingAddress: {
    firstName: 'John'
    lastName: 'Doe'
    streetName: 'Some Street'
    streetNumber: '11'
    postalCode: '11111'
    city: 'Some City'
    country: 'US'
  }
  billingAddress: {
    firstName: 'John'
    lastName: 'Doe'
    streetName: 'Some Street'
    streetNumber: '11'
    postalCode: '11111'
    city: 'Some City'
    country: 'US'
  }
},{
  id: 'xyz'
  orderNumber: '10001'
  version: 1
  lineItems: [
    id: 'LineItemId-2-1'
    productId: 'ProductId-2-1'
    name:
      { en: 'Product-2-1' }
    variant: {
      variantId: 1
      sku: 'SKU-2-1'
      images: []
      attributes: []
    }
    quantity: 1
    price: {
      country: 'US'
      value: {
        currencyCode: 'USD'
        centAmount: 2380
      }
    }
    taxRate: {
      name: 'Standard Tax Rate'
      amount: 0.19
      includedInPrice: true
      id: 'taxRateId'
      country: 'US'
    }
  ]
  customLineItems: []
  totalPrice: {
    currencyCode: 'USD'
    centAmount: 2380
  }
  taxedPrice: {
    totalNet: {
      currencyCode: 'USD'
      centAmount: 2000
    }
    totalGross: {
      currencyCode: 'USD'
      centAmount: 2380
    }
    taxPortions: [{
      amount: {
        currencyCode: 'USD'
        centAmount: 380
      }
      rate: 0.19
    }]
  }
  shippingAddress: {
    firstName: 'John'
    lastName: 'Doe'
    streetName: 'Some Street'
    streetNumber: '11'
    postalCode: '11111'
    city: 'Some City'
    country: 'US'
  }
  billingAddress: {
    firstName: 'John'
    lastName: 'Doe'
    streetName: 'Some Street'
    streetNumber: '11'
    postalCode: '11111'
    city: 'Some City'
    country: 'US'
  }
}]