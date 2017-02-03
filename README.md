![SPHERE.IO icon](https://admin.sphere.io/assets/images/sphere_logo_rgb_long.png)

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

## General usage
```$xslt
Usage: order-export --projectKey key

Options:
  --projectKey              your SPHERE.IO project-key                                                     [required]
  --clientId                your OAuth client id for the SPHERE.IO API
  --clientSecret            your OAuth client secret for the SPHERE.IO API
  --accessToken             an OAuth access token for the SPHERE.IO API
  --sphereHost              SPHERE.IO API host to connect to
  --sphereProtocol          SPHERE.IO API protocol to connect to
  --sphereAuthHost          SPHERE.IO OAuth host to connect to
  --sphereAuthProtocol      SPHERE.IO OAuth protocol to connect to
  --fetchHours              Number of hours to fetch modified orders                                       [default: 48]
  --createdFrom             UTC datetime from when should orders be fetched                                    
  --createdTo               UTC datetime until when should orders be fetched                               [default: current timestamp]
  --perPage                 Number of orders to be fetched per page                                        [default: 100]
  --standardShippingMethod  Allows to define the fallback shipping method name if order has none           [default: "None"]
  --exportUnsyncedOnly      whether only unsynced orders will be exported or not                           [default: true]
  --targetDir               the folder where exported files are saved                                      [default: "/Users/xjunajan/dev/commercetools/sphere-order-export/exports"]
  --useExportTmpDir         whether to use a system tmp folder to store exported files                     [default: false]
  --csvTemplate             CSV template to define the structure of the export
  --createSyncActions       upload syncInfo update actions for orders exported (only supports sftp upload  [default: false]
  --fileWithTimestamp       whether exported file should contain a timestamp                               [default: false]
  --sftpCredentials         the path to a JSON file where to read the credentials from
  --sftpHost                the SFTP host (overwrite value in sftpCredentials JSON, if given)
  --sftpUsername            the SFTP username (overwrite value in sftpCredentials JSON, if given)
  --sftpPassword            the SFTP password (overwrite value in sftpCredentials JSON, if given)
  --sftpTarget              path in the SFTP server to where to move the worked files
  --sftpContinueOnProblems  ignore errors when processing a file and continue with the next one            [default: false]
  --logLevel                log level for file logging                                                     [default: "info"]
  --logDir                  directory to store logs                                                        [default: "."]
  --logSilent               use console to print messages                                                  [default: false]
  --timeout                 Set timeout for requests                                                       [default: 60000]
  --exportCSVAsStream       Exports CSV as stream (to use for performance reasons)                         [default: false]
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

In general you can get access to any property of the order object. Find a reference in our [API documentation](http://dev.sphere.io/http-api-projects-orders.html#order).

> Note that when at least one `lineItems` header is given the resulting CSV contains a row per lineItem. Otherwise it only contains one row per order.


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
