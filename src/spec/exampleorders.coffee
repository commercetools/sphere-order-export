exports.orders =
[{
  id: 'abc'
  createdAt: '1970-01-01T00:00:00.001Z'
  lastModifiedAt: '1970-01-01T00:00:00.002Z'
  orderNumber: '10001'
  version: 1
  lineItems: [{
    id: 'LineItemId-1-1'
    productId: 'ProductId-1-1'
    name:
      { en: 'Product-1-1' }
    variant: {
      variantId: 1
      sku: 'SKU-1-1'
      images: [{
        url: "http://www.example.org/image-1-1-1.jpg"
        dimensions: {
          w: 0
          h: 0
        }
      },{
        url: "http://www.example.org/image-1-1-2.jpg"
        dimensions: {
          w: 0
          h: 0
        }
      },{
        url: "http://www.example.org/image-1-1-3.jpg"
        dimensions: {
          w: 0
          h: 0
        }
      }]
      attributes: []
    }
    quantity: 2
    price: {
      country: 'US'
      value: {
        currencyCode: 'USD'
        centAmount: 1190
      }
    }
    state: [{
      quantity: 1
      state: {
        typeId: 'state'
        id: 'state-1'
        obj: {
          key: 'firstState'
        }
      }
    },{
      quantity: 1
      state: {
        typeId: 'state'
        id: 'state-2'
        obj: {
          key: 'secondState'
        }
      }
    }]
    taxRate: {
      name: 'Standard Tax Rate'
      amount: 0.19
      includedInPrice: true
      id: 'taxRateId'
      country: 'US'
    }
  },{
    id: 'LineItemId-1-2'
    productId: 'ProductId-1-2'
    name:
      { en: 'Product-1-2' }
    variant: {
      variantId: 2
      sku: 'SKU-1-2'
      images: []
      attributes: []
    }
    quantity: 3
    price: {
      country: 'US'
      value: {
        currencyCode: 'USD'
        centAmount: 1190
      }
    }
    state: [{
      quantity: 1
      state: {
        typeId: 'state'
        id: 'state-1'
        obj: {
          key: 'firstState'
        }
      }
    },{
      quantity: 1
      state: {
        typeId: 'state'
        id: 'state-1'
        obj: {
          key: 'secondState'
        }
      }
    },{
      quantity: 1
      state: {
        typeId: 'state'
        id: 'state-3'
        obj: {
          key: 'thirdState'
        }
      }
    }]
    taxRate: {
      name: 'Standard Tax Rate'
      amount: 0.19
      includedInPrice: true
      id: 'taxRateId'
      country: 'US'
    }
    supplyChannel: {
      typeId: "channel"
      id: "channel-2"
      obj: {
        key: "secondChannel"
      }
    }
  }]
  customLineItems: []
  totalPrice: {
    currencyCode: 'USD'
    centAmount: 5950
  }
  taxedPrice: {
    totalNet: {
      currencyCode: 'USD'
      centAmount: 5000
    }
    totalGross: {
      currencyCode: 'USD'
      centAmount: 5950
    }
    taxPortions: [{
      amount: {
        currencyCode: 'USD'
        centAmount: 950
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
  shippingInfo: {
    price: {
      centAmount: 499
      currencyCode: "USD"
    }
    shippingRate: {
      price: {
        centAmount: 499
        currencyCode: "USD"
      }
      freeAbove: {
        centAmount: 20000
        currencyCode: "USD"
      }
    }
    taxRate: {
      name: 'Standard Tax Rate'
      amount: 0.19
      includedInPrice: true
      id: 'taxRateId'
      country: 'US'
    }
    taxCategory: {
      typeId: 'tax-category'
      id: 'taxCategoryId'
    }
    deliveries: [{
      id: 'delivery-1-1'
      createdAt: '1970-01-01T00:00:00.003Z'
      items: [{
        id: 'LineItemId-1-1'
        quantity: 1
      }
      {
        id: 'LineItemId-1-2'
        quantity: 1
      }]
    }]
  }
},{
  id: 'xyz'
  orderNumber: '10002'
  createdAt: '1970-01-01T00:00:00.004Z'
  lastModifiedAt: '1970-01-01T00:00:00.005Z'
  version: 1
  lineItems: [{
    id: 'LineItemId-2-1'
    productId: 'ProductId-2-1'
    name:
      { en: 'Product-2-1' }
    variant: {
      variantId: 1
      sku: 'SKU-2-1'
      images: [{
        url: "http://www.example.org/image-2-1-1.jpg"
        dimensions: {
          w: 0
          h: 0
        }
      }]
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
    state: [{
      quantity: 1
      state: {
        typeId: 'state'
        id: 'state-1'
        obj: {
          key: 'firstState'
        }
      }
    }]
    taxRate: {
      name: 'Standard Tax Rate'
      amount: 0.19
      includedInPrice: true
      id: 'taxRateId'
      country: 'US'
    }
    supplyChannel: {
      typeId: "channel"
      id: "channel-2"
      obj: {
        key: "secondChannel"
      }
    }
  }]
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
  customerGroup: {
    typeId: 'customer-group'
    id: 'customer-group-2'
    obj: {
      name: 'cool customers'
    }
  }
  shippingAddress: {
    firstName: 'Jane'
    lastName: 'Doe'
    streetName: 'Some Other Street '
    streetNumber: '22'
    postalCode: '22222'
    city: 'Some Other City'
    country: 'US'
  }
  billingAddress: {
    firstName: 'Jane'
    lastName: 'Doe'
    streetName: 'Some Other Street '
    streetNumber: '22'
    postalCode: '22222'
    city: 'Some Other City'
    country: 'US'
  }
  shippingInfo: {
    price: {
      centAmount: 499
      currencyCode: "USD"
    }
    shippingRate: {
      price: {
        centAmount: 499
        currencyCode: "USD"
      }
      freeAbove: {
        centAmount: 20000
        currencyCode: "USD"
      }
    }
    taxRate: {
      name: 'Standard Tax Rate'
      amount: 0.19
      includedInPrice: true
      id: 'taxRateId'
      country: 'US'
    }
    taxCategory: {
      typeId: 'tax-category'
      id: 'taxCategoryId'
    }
    deliveries: [{
      id: 'deliveryId-2-1'
      createdAt: '1970-01-01T00:00:00.006Z'
      items: [{
        id: 'LineItemId-2-1'
        quantity: 1
      }]
    }]
  }
}]