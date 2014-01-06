#!/bin/bash

set -e

rm -rf lib

npm version patch
git checkout production
git merge master

grunt build
git add -f lib/
git commit -m "Add generated code for elastic.io environment."
git push origin production

git checkout master
npm version patch
git push origin master
