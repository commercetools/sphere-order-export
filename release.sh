#!/bin/bash

set -e

rm -rf build

npm version minor
git checkout production
git merge master
grunt
git add -f build/app/services.js
git commit -m "Add generated code for production environment."
git push origin production

git checkout master
npm version patch
git push origin master
