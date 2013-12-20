#!/bin/bash

set -e

rm -rf lib

npm version minor
git checkout production
git merge master
grunt test
git add -f lib/services.js
git commit -m "Add generated code for production environment."
git push origin production

git checkout master
npm version patch
git push origin master
