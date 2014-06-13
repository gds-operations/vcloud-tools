#!/bin/bash -x
set -e

git clean -ffdx
bundle install --path "${HOME}/bundles/${JOB_NAME}"
bundle exec rake publish_gem
