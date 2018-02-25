#!/bin/bash
set -e

# Pull requests and commits to other branches shouldn't try to deploy, just build to verify
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "Branch is not master, skipping deploy."
    exit 0
fi

repo="git@github.com:langue-festival/langue-festival.github.io.git"
sha="$(git rev-parse --verify HEAD)"

chmod 600 deploy_key
eval $(ssh-agent -s)
ssh-add deploy_key

cd deploy

git config user.name "travis-ci@langue-festival.github.io"
git config user.email "${COMMIT_AUTHOR_EMAIL}"
git add .
git commit -m "Deploy to GitHub Pages: ${sha}"
git push "${repo}" master
