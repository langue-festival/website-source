#!/bin/bash
set -e

# Pull requests and commits to other branches shouldn't try to deploy
if [ "${TRAVIS_PULL_REQUEST}" != "false" -o "${TRAVIS_BRANCH}" != "master" ]; then
    echo "Skipping deploy."
    exit 0
fi

REPO="$(git config remote.origin.url)"
SSH_REPO="${REPO/https:\/\/github.com\//git@github.com:}"
SHA="$(git rev-parse --verify HEAD)"

git config user.name "travis-ci@langue-festival.github.io"
git config user.email "${COMMIT_AUTHOR_EMAIL}"
git add -A -f assets pages CNAME index.html
git commit -m "Deploy to GitHub Pages: ${SHA}"

# Get the deploy key by using travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY="${!ENCRYPTED_KEY_VAR}"
ENCRYPTED_IV="${!ENCRYPTED_IV_VAR}"
openssl aes-256-cbc -K "${ENCRYPTED_KEY}" -iv "${ENCRYPTED_IV}" -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval $(ssh-agent -s)
ssh-add deploy_key

git push "${SSH_REPO}" master
