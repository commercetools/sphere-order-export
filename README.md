sphere-order-export
===================

[![Build Status](https://travis-ci.org/sphereio/sphere-order-export.png?branch=master)](https://travis-ci.org/sphereio/sphere-order-export) [![Coverage Status](https://coveralls.io/repos/sphereio/sphere-order-export/badge.png)](https://coveralls.io/r/sphereio/sphere-order-export) [![Dependency Status](https://david-dm.org/sphereio/sphere-order-export.svg)](https://david-dm.org/sphereio/sphere-order-export) [![devDependency Status](https://david-dm.org/sphereio/sphere-order-export/dev-status.svg)](https://david-dm.org/sphereio/sphere-order-export#info=devDependencies)

This project contains a component to export your orders from a SPHERE.IO project. The resulting format can either be a set of XML files - one per order - or one CSV file containing the selected list of orders.

You may use this component eg. to export each order to your CRM resp. ERP system or create a pick list.
For automation purpose the tool allows you to inact with a SFTP server in order to deliver the exported files to a location where other systems can read from.


# Setup

* install [NodeJS](http://support.sphere.io/knowledgebase/articles/307722-install-nodejs-and-get-a-component-running) (platform for running application)

### From scratch

* install [npm](http://gruntjs.com/getting-started) (NodeJS package manager, bundled with node since version 0.6.3!)
* install [grunt-cli](http://gruntjs.com/getting-started) (automation tool)
*  resolve dependencies using `npm`
```bash
$ npm install
```
* build javascript sources
```bash
$ grunt build
```

### From ZIP

* Just download the ready to use application as [ZIP](https://github.com/sphereio/sphere-order-export/archive/latest.zip)
* Extract the latest.zip with `unzip sphere-order-export-latest.zip`
* Change into the directory `cd sphere-order-export-latest`

## General Usage

```
$ node lib/run.js help
Usage: node ./lib/run.js --projectKey key --clientId id --clientSecret secret

Options:
  --projectKey              your SPHERE.IO project-key                                                                                                                        [required]
  --clientId                your OAuth client id for the SPHERE.IO API
  --clientSecret            your OAuth client secret for the SPHERE.IO API
  --sphereHost              SPHERE.IO API host to connecto to
  --fetchHours              Number of hours to fetch modified orders                                                                                                          [default: 0]
  --standardShippingMethod  Allows to define the fallback shipping method name of order has none                                                                              [default: "None"]
  --useExportTmpDir         whether to use a tmp folder to store resulting XML files in or not (if no, files will be created under './exports')                               [default: false]
  --csvTemplate             CSV template to define the structure of the export. If present only one CSV file will be generated. If not present the tool generates XML files.
  --sftpCredentials         the path to a JSON file where to read the credentials from
  --sftpHost                the SFTP host (overwrite value in sftpCredentials JSON, if given)
  --sftpUsername            the SFTP username (overwrite value in sftpCredentials JSON, if given)
  --sftpPassword            the SFTP password (overwrite value in sftpCredentials JSON, if given)
  --sftpTarget              path in the SFTP server to where to move the worked files
  --logLevel                log level for file logging                                                                                                                        [default: "info"]
  --logDir                  directory to store logs                                                                                                                           [default: "."]
  --logSilent               use console to print messages                                                                                                                     [default: false]
  --timeout                 Set timeout for requests                                                                                                                          [default: 60000]
```

### CSV export

To export a list of orders you have to define a CSV template and pass the path to it via the `--csvTemplate` argument.

#### CSV format

The following headers can be used in the CSV template
- id
- orderNumber
- totalPrice -> results in a formated output of the price like `USD 9999`
- totalPrice.centAmount -> results in the pure number of `9999` - allows better sorting
- totalNet
- totalGross
- lineItems.*
- lineItems.variant.*
- shippingAddress.*
- billingAddress.*

In general you can get access to any property of the order object. Find a reference in our [API documentation](http://dev.sphere.io/http-api-projects-orders.html#order).

> Note that when at least one `lineItems` header is given the resulting CSV contains a row per lineItem. Otherwise it only contains one row per order.

### XML export

Using the XML export generates for each order one XML file contain all it's details.
Use this option to sync the SPHERE.IO orders with any external system.

To ensure that you won't export your orders twice the tool stores the file name it exported the order to in the `syncInfo` of that order.

### SFTP upload

To use this tool as a background task we built in an SFTP connector that automatically uploads the exported orders to an SFTP location defined by the `--sftp*` arguments.
