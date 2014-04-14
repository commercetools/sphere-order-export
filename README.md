sphere-order-xml-export
=======================

[![Build Status](https://travis-ci.org/commercetools/sphere-order-xml-export.png?branch=master)](https://travis-ci.org/commercetools/sphere-order-xml-export) [![Dependency Status](https://david-dm.org/commercetools/sphere-order-xml-export.svg)](https://david-dm.org/commercetools/sphere-order-xml-export) [![devDependency Status](https://david-dm.org/commercetools/sphere-order-xml-export/dev-status.svg)](https://david-dm.org/commercetools/sphere-order-xml-export#info=devDependencies)

This project contains a full functional order export to create separate XMLs from each order. The code supports all possible data points and will be used within an elastic.io workflow. It can be used to connect ERP systems as well as CRM tools to update order data between the different systems.

## How to develop

Install the required dependencies

```bash
npm install
```

Source files are written in `coffeescript`. Use [Grunt](http://gruntjs.com/) to build them

```bash
grunt
```

This will generate source files into `./build` folder.

Make sure to setup the correct environment for `elasticio` integration

```bash
echo '{}' > ${HOME}/elastic.json && touch ${HOME}/.env
```

### Specs

Specs are located under `./src/spec` folder and written as [Jasmine test](http://pivotal.github.io/jasmine/).

To run them simply execute

```bash
jasmine-node --captureExceptions build/test
```

or

```bash
npm test
```

which will also execute `elasticio`
