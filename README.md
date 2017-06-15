![commercetools logo](https://cdn.rawgit.com/commercetools/press-kit/master/PNG/72DPI/CT%20logo%20horizontal%20RGB%2072dpi.png)

# Order export

[![NPM](https://nodei.co/npm/sphere-order-export.png?downloads=true)](https://www.npmjs.org/package/sphere-order-export)

[![Build Status](https://secure.travis-ci.org/sphereio/sphere-order-export.png?branch=master)](http://travis-ci.org/sphereio/sphere-order-export) [![NPM version](https://badge.fury.io/js/sphere-order-export.png)](http://badge.fury.io/js/sphere-order-export) [![Coverage Status](https://coveralls.io/repos/sphereio/sphere-order-export/badge.png)](https://coveralls.io/r/sphereio/sphere-order-export) [![Dependency Status](https://david-dm.org/sphereio/sphere-order-export.png?theme=shields.io)](https://david-dm.org/sphereio/sphere-order-export) [![devDependency Status](https://david-dm.org/sphereio/sphere-order-export/dev-status.png?theme=shields.io)](https://david-dm.org/sphereio/sphere-order-export#info=devDependencies)

This module allows to export orders to XML or CSV, with SFTP support.

> By default XML export will result in each file pro order

## Getting started

```bash
$ npm install -g sphere-order-export

# output help screen
$ order-export
```

### SFTP
Exported orders (XML or CSV) can be automatically uploaded to an SFTP server.

When using SFTP you need to provide at least the required `--sftp*` options:
- `--sftpCredentials` (or `--sftpHost`, `--sftpUsername`, `--sftpPassword`)
- `--sftpSource`
- `--sftpTarget`

**Note that only exported SFTP orders are marked as synced (`syncInfo`) with the channel key `OrderXmlFileExport`**

### XML Format (default)
Orders exported in XML will result in **each file pro order** like

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<order>
  <xsdVersion>0.9</xsdVersion>
  <id>a095493f-0750-41fe-9fa7-77cad095fe2a</id>
  <version>1</version>
  <createdAt>2014-10-13T09:20:04.961Z</createdAt>
  <lastModifiedAt>2014-10-13T09:20:04.961Z</lastModifiedAt>
  ...
</order>
```

### CSV Format
Orders exported in CSV are stored in a single file

> At the moment you need to provide a `--csvTemplate` with headers in order to export related fields (see [examples](data)).

```csv
id,orderNumber,totalPrice,totalNet,totalGross
```

The following headers can be used in the CSV template
- `id`
- `orderNumber`
- `totalPrice` -> results in a formated output of the price like `USD 9999`
- `totalPrice.centAmount` -> results in the pure number of `9999` (allows better sorting)
- `totalNet`
- `totalGross`
- `customerGroup`
- `lineItems.*` - eg. `id`, `state` or `supplyChannel`
- `lineItems.variant.*` - eg. `sku` or `images`
- `shippingAddress.*` - eg. `lastName` or `postalCode`
- `billingAddress.*`
- `custom.fields.*` - eg. `custom.fields.fieldName` will export custom field

In general you can get access to any property of the order object. Find a reference in our [API documentation](http://dev.sphere.io/http-api-projects-orders.html#order).

> Note that when at least one `lineItems` header is given the resulting CSV contains a row per lineItem. Otherwise it only contains one row per order.

When exporting order with its line items, all redundant info (eg. general order information) is removed and printed only once in the first rows:
```csv
id,orderNumber,price,lineItems.id,lineItems.productId,billingAddress.firstName
123,10001,USD 5950,,,John
123,10001,,LineItemId-1-1,ProductId-1-1,
123,10001,,LineItemId-1-2,ProductId-1-2,
```

If needed you can specify a `--fillAllRows` parameter which will put general info also to line items rows:
```csv
id,orderNumber,price,lineItems.id,lineItems.productId,billingAddress.firstName
123,10001,USD 5950,,,John
123,10001,USD 5950,LineItemId-1-1,ProductId-1-1,John
123,10001,USD 5950,LineItemId-1-2,ProductId-1-2,John
```

Example with custom fields:
```csv
id,orderNumber,custom.fields.stringField,custom.fields.booleanField
1,10001,abcd,1
2,10002,efgh,
```
Booleans with a `false` value are mapped as an empty strings.


## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).
More info [here](CONTRIBUTING.md)

## Releasing
Releasing a new version is completely automated using the Grunt task `grunt release`.

```javascript
grunt release // patch release
grunt release:minor // minor release
grunt release:major // major release
```

## License
Copyright (c) 2014 SPHERE.IO
Licensed under the [MIT license](LICENSE-MIT).
