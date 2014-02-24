#!/bin/bash

set -e

BRANCH_NAME='production'

set +e
git branch -D ${BRANCH_NAME}
set -e

rm -rf lib
rm -rf node_modules

npm version patch
git branch ${BRANCH_NAME}
git checkout ${BRANCH_NAME}

npm install
grunt build
rm -rf node_modules
npm install --production
git add -f lib/
git add -f node_modules/
git commit -m "Add generated code and runtime dependencies for elastic.io environment."
git push --force origin ${BRANCH_NAME}

git checkout master

VERSION=$(cat package.json | jq --raw-output .version)
git push origin "v${VERSION}"
npm version patch
npm install
