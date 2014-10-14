#!/bin/bash

set -e

VERSION=$(cat package.json | jq --raw-output .version)
PKG_NAME=$(cat package.json | jq --raw-output .name)
BRANCH_NAME='production'

echo "About to release ${PKG_NAME} - v${VERSION} to ${BRANCH_NAME} branch!"

cleanup() {
  set +e
  echo "Cleaning up"
  rm -rf package
  rm "${PKG_NAME}"-*
  set -e
}

# cleanup
cleanup

set +e
git branch -D ${BRANCH_NAME}
set -e

# install all deps
echo "Installing all deps"
npm install &>/dev/null
echo "Building sources"
grunt build &>/dev/null

# package npm and extract it
echo "Packaging locally"
npm pack
tar -xzf "${PKG_NAME}-${VERSION}.tgz"

cd package
# install production deps (no devDeps)
echo "Installing only production deps"
npm install --production &>/dev/null
# push everything inside package to selected branch
git init
git remote add origin git@github.com:sphereio/${PKG_NAME}.git
git add -A &>/dev/null
git commit -m "Release packaged version ${VERSION} to ${BRANCH_NAME} branch" &>/dev/null
echo "About to push to ${BRANCH_NAME} branch"
git push --force origin master:${BRANCH_NAME}
cd -

# cleanup
cleanup

echo "Congratulations, the package has been successfully released to branch ${BRANCH_NAME}"
