OrderExport = require '../lib/orderexport'
Config = require '../config'

describe '#mapOrder', ->
  beforeEach ->
    @orderExport = new OrderExport Config

  xit 'export base attributes', ->
    template =
      """
      id,orderNumber
      """

    orders =
      [{
        id: 'abc'
        orderNumber: '10001'
        version: 1
        lineItems: [
          id: 'LineItemId-1-1'
          productId: 'ProductId-1-1',
          name:
            { en: 'Product-1-1' },
          variant: {
            variantId: 1,
            sku: 'SKU-1-1',
            images: [],
            attributes: []
          },
          quantity: 1,
          price: {
            country: 'US',
            value: {
              currencyCode: 'USD',
              centAmount: 1190
            }
          },
          taxRate: {
            name: 'Standard Tax Rate',
            amount: 0.19,
            includedInPrice: true,
            id: 'taxRateId',
            country: 'US'
          }
        ],
        customLineItems: [],
        totalPrice: {
          currencyCode: 'USD'
          centAmount: 1190
        },
        taxedPrice: {
          totalNet: {
            currencyCode: 'USD',
            centAmount: 1000
          },
          totalGross: {
            currencyCode: 'USD',
            centAmount: 1190
          },
          taxPortions: [{
            amount: {
              currencyCode: 'USD',
              centAmount: 190
            },
            rate: 0.19
          }]
        },
        shippingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        },
        billingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        }
      },{
        id: 'xyz'
        orderNumber: '10001'
        version: 1
        lineItems: [
          id: 'LineItemId-2-1'
          productId: 'ProductId-2-1',
          name:
            { en: 'Product-2-1' },
          variant: {
            variantId: 1,
            sku: 'SKU-2-1',
            images: [],
            attributes: []
          },
          quantity: 1,
          price: {
            country: 'US',
            value: {
              currencyCode: 'USD',
              centAmount: 2380
            }
          },
          taxRate: {
            name: 'Standard Tax Rate',
            amount: 0.19,
            includedInPrice: true,
            id: 'taxRateId',
            country: 'US'
          }
        ],
        customLineItems: [],
        totalPrice: {
          currencyCode: 'USD'
          centAmount: 2380
        },
        taxedPrice: {
          totalNet: {
            currencyCode: 'USD',
            centAmount: 2000
          },
          totalGross: {
            currencyCode: 'USD',
            centAmount: 2380
          },
          taxPortions: [{
            amount: {
              currencyCode: 'USD',
              centAmount: 380
            },
            rate: 0.19
          }]
        },
        shippingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        },
        billingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        }
      }]

    expectedCSV =
      """
      id,orderNumber
      abc,10001
      xyz,10002
      """

    csv = @orderExport.toCSV template, orders
    expect(csv).toBe expectedCSV

  it 'export prices', ->
    template =
      """
      id,orderNumber,totalPrice,totalNet,totalGross
      """

    orders =
      [{
        id: 'abc'
        orderNumber: '10001'
        version: 1
        lineItems: [
          id: 'LineItemId-1-1'
          productId: 'ProductId-1-1',
          name:
            { en: 'Product-1-1' },
          variant: {
            variantId: 1,
            sku: 'SKU-1-1',
            images: [],
            attributes: []
          },
          quantity: 1,
          price: {
            country: 'US',
            value: {
              currencyCode: 'USD',
              centAmount: 1190
            }
          },
          taxRate: {
            name: 'Standard Tax Rate',
            amount: 0.19,
            includedInPrice: true,
            id: 'taxRateId',
            country: 'US'
          }
        ],
        customLineItems: [],
        totalPrice: {
          currencyCode: 'USD'
          centAmount: 1190
        },
        taxedPrice: {
          totalNet: {
            currencyCode: 'USD',
            centAmount: 1000
          },
          totalGross: {
            currencyCode: 'USD',
            centAmount: 1190
          },
          taxPortions: [{
            amount: {
              currencyCode: 'USD',
              centAmount: 190
            },
            rate: 0.19
          }]
        },
        shippingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        },
        billingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        }
      },{
        id: 'xyz'
        orderNumber: '10001'
        version: 1
        lineItems: [
          id: 'LineItemId-2-1'
          productId: 'ProductId-2-1',
          name:
            { en: 'Product-2-1' },
          variant: {
            variantId: 1,
            sku: 'SKU-2-1',
            images: [],
            attributes: []
          },
          quantity: 1,
          price: {
            country: 'US',
            value: {
              currencyCode: 'USD',
              centAmount: 2380
            }
          },
          taxRate: {
            name: 'Standard Tax Rate',
            amount: 0.19,
            includedInPrice: true,
            id: 'taxRateId',
            country: 'US'
          }
        ],
        customLineItems: [],
        totalPrice: {
          currencyCode: 'USD'
          centAmount: 2380
        },
        taxedPrice: {
          totalNet: {
            currencyCode: 'USD',
            centAmount: 2000
          },
          totalGross: {
            currencyCode: 'USD',
            centAmount: 2380
          },
          taxPortions: [{
            amount: {
              currencyCode: 'USD',
              centAmount: 380
            },
            rate: 0.19
          }]
        },
        shippingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        },
        billingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        }
      }]

    expectedCSV =
      """
      id,orderNumber,totalPrice,totalNet,totalGross
      abc,10001,USD 1190,USD 1000,USD 190
      xyz,10002,USD 2380,USD 2000,USD 380
      """

    csv = @orderExport.toCSV template, orders
    expect(csv).toBe expectedCSV

    it 'export addresses', ->
    template =
      """
      id,orderNumber,billingAddress.firstName,billingAddress.lastName,billingAddress.streetName,billingAddress.streetNumber,billingAddress.postalCode,billingAddress.city,billingAddress.country,shippingAddress.firstName,shippingAddress.lastName,shippingAddress.streetName,shippingAddress.streetNumber,shippingAddress.postalCode,shippingAddress.city,shippingAddress.country,
      """

    orders =
      [{
        id: 'abc'
        orderNumber: '10001'
        version: 1
        lineItems: [
          id: 'LineItemId-1-1'
          productId: 'ProductId-1-1',
          name:
            { en: 'Product-1-1' },
          variant: {
            variantId: 1,
            sku: 'SKU-1-1',
            images: [],
            attributes: []
          },
          quantity: 1,
          price: {
            country: 'US',
            value: {
              currencyCode: 'USD',
              centAmount: 1190
            }
          },
          taxRate: {
            name: 'Standard Tax Rate',
            amount: 0.19,
            includedInPrice: true,
            id: 'taxRateId',
            country: 'US'
          }
        ],
        customLineItems: [],
        totalPrice: {
          currencyCode: 'USD'
          centAmount: 1190
        },
        taxedPrice: {
          totalNet: {
            currencyCode: 'USD',
            centAmount: 1000
          },
          totalGross: {
            currencyCode: 'USD',
            centAmount: 1190
          },
          taxPortions: [{
            amount: {
              currencyCode: 'USD',
              centAmount: 190
            },
            rate: 0.19
          }]
        },
        shippingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        },
        billingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        }
      },{
        id: 'xyz'
        orderNumber: '10001'
        version: 1
        lineItems: [
          id: 'LineItemId-2-1'
          productId: 'ProductId-2-1',
          name:
            { en: 'Product-2-1' },
          variant: {
            variantId: 1,
            sku: 'SKU-2-1',
            images: [],
            attributes: []
          },
          quantity: 1,
          price: {
            country: 'US',
            value: {
              currencyCode: 'USD',
              centAmount: 2380
            }
          },
          taxRate: {
            name: 'Standard Tax Rate',
            amount: 0.19,
            includedInPrice: true,
            id: 'taxRateId',
            country: 'US'
          }
        ],
        customLineItems: [],
        totalPrice: {
          currencyCode: 'USD'
          centAmount: 2380
        },
        taxedPrice: {
          totalNet: {
            currencyCode: 'USD',
            centAmount: 2000
          },
          totalGross: {
            currencyCode: 'USD',
            centAmount: 2380
          },
          taxPortions: [{
            amount: {
              currencyCode: 'USD',
              centAmount: 380
            },
            rate: 0.19
          }]
        },
        shippingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        },
        billingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        }
      }]

    expectedCSV =
      """
      id,orderNumber,billingAddress.firstName,billingAddress.lastName,billingAddress.streetName,billingAddress.streetNumber,billingAddress.postalCode,billingAddress.city,billingAddress.country,shippingAddress.firstName,shippingAddress.lastName,shippingAddress.streetName,shippingAddress.streetNumber,shippingAddress.postalCode,shippingAddress.city,shippingAddress.country
      abc,10001,John,Doe,"Some Street",11,11111,"Some City",US,John,Doe,"Some Street",11,11111,"Some City",US
      xyz,10002,John,Doe,"Some Street",11,11111,"Some City",US,John,Doe,"Some Street",11,11111,"Some City",US
      """

    csv = @orderExport.toCSV template, orders
    expect(csv).toBe expectedCSV

    it 'export lineItems', ->
    template =
      """
      id,orderNumber,lineItems.id,lineItems.productId,lineItems.name.en,lineItems.variant.variantId,lineItems.variant.sku,lineItems.quantity,price
      """

    orders =
      [{
        id: 'abc'
        orderNumber: '10001'
        version: 1
        lineItems: [
          id: 'LineItemId-1-1'
          productId: 'ProductId-1-1',
          name:
            { en: 'Product-1-1' },
          variant: {
            variantId: 1,
            sku: 'SKU-1-1',
            images: [],
            attributes: []
          },
          quantity: 1,
          price: {
            country: 'US',
            value: {
              currencyCode: 'USD',
              centAmount: 1190
            }
          },
          taxRate: {
            name: 'Standard Tax Rate',
            amount: 0.19,
            includedInPrice: true,
            id: 'taxRateId',
            country: 'US'
          }
        ],
        customLineItems: [],
        totalPrice: {
          currencyCode: 'USD'
          centAmount: 1190
        },
        taxedPrice: {
          totalNet: {
            currencyCode: 'USD',
            centAmount: 1000
          },
          totalGross: {
            currencyCode: 'USD',
            centAmount: 1190
          },
          taxPortions: [{
            amount: {
              currencyCode: 'USD',
              centAmount: 190
            },
            rate: 0.19
          }]
        },
        shippingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        },
        billingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        }
      },{
        id: 'xyz'
        orderNumber: '10001'
        version: 1
        lineItems: [
          id: 'LineItemId-2-1'
          productId: 'ProductId-2-1',
          name:
            { en: 'Product-2-1' },
          variant: {
            variantId: 1,
            sku: 'SKU-2-1',
            images: [],
            attributes: []
          },
          quantity: 1,
          price: {
            country: 'US',
            value: {
              currencyCode: 'USD',
              centAmount: 2380
            }
          },
          taxRate: {
            name: 'Standard Tax Rate',
            amount: 0.19,
            includedInPrice: true,
            id: 'taxRateId',
            country: 'US'
          }
        ],
        customLineItems: [],
        totalPrice: {
          currencyCode: 'USD'
          centAmount: 2380
        },
        taxedPrice: {
          totalNet: {
            currencyCode: 'USD',
            centAmount: 2000
          },
          totalGross: {
            currencyCode: 'USD',
            centAmount: 2380
          },
          taxPortions: [{
            amount: {
              currencyCode: 'USD',
              centAmount: 380
            },
            rate: 0.19
          }]
        },
        shippingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        },
        billingAddress: {
          firstName: 'John',
          lastName: 'Doe',
          streetName: 'Some Street',
          streetNumber: '11',
          postalCode: '11111',
          city: 'Some City',
          country: 'US'
        }
      }]

    expectedCSV =
      """
      id,orderNumber,lineItems.id,lineItems.productId,lineItems.name.en,lineItems.variant.variantId,lineItems.variant.sku,lineItems.quantity,price
      abc,10001,,,,,,,
      ,,LineItemId-1-1,ProductId-1-1,Product-1-1,1,SKU-1-1,1,"US USD 1190"
      xyz,10002,,,,,,,
      ,,LineItemId-2-1,ProductId-2-1,Product-2-1,1,SKU-2-1,1,"US USD 2380"
      """

    csv = @orderExport.toCSV template, orders
    expect(csv).toBe expectedCSV
