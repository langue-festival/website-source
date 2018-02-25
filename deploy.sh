#!/bin/bash
set -e

# Commits to other branches shouldn't try to deploy
if [ "${TRAVIS_BRANCH}" != "master" ]; then
    echo "Branch is not master, skipping deploy."
    exit 0
fi

repo="git@github.com:langue-festival/langue-festival.github.io.git"
sha="$(git rev-parse --verify HEAD)"

# Get the deploy key by using travis's stored variables to decrypt deploy_key.enc
encrypted_key_var="encrypted_${ENCRYPTION_LABEL}_key"
encrypted_iv_var="encrypted_${ENCRYPTION_LABEL}_iv"
encrypted_key="${!encrypted_key_var}"
encrypted_iv="${!encrypted_iv_var}"

openssl aes-256-cbc -K "${encrypted_key}" -iv "${encrypted_iv}" -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval $(ssh-agent -s)
ssh-add deploy_key

cd deploy

git config user.name "travis-ci@langue-festival.github.io"
git config user.email "${COMMIT_AUTHOR_EMAIL}"
git add .
git commit -m "Deploy to GitHub Pages: ${sha}"
git push "${repo}" master
