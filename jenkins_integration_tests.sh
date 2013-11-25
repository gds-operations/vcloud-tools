#!/bin/bash -x
set -e
bundle install --path "${HOME}/bundles/${JOB_NAME}"

./scripts/generate_fog_conf_file.sh

export FOG_RC=fog_integration_test.config

bundle exec rake integration_test

rm fog_integration_test.config
