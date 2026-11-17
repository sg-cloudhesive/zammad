#!/usr/bin/env bash

set -o errexit
set -o pipefail

# shellcheck disable=SC1091
source /etc/profile.d/rvm.sh # ensure RVM is loaded

# CI run only: the CI image ships a newer Ruby than this branch requires.
mkdir -p /usr/local/rvm/src /usr/local/rvm/archives /usr/local/rvm/log /usr/local/rvm/tmp
set +o errexit
rvm install "ruby-$(cat .ruby-version)"
rvm use "ruby-$(cat .ruby-version)"
set -o errexit
ruby -v
ruby -v | grep -q "ruby $(cat .ruby-version)"

bundle config set --local deployment 'true'
bundle install -j "$(nproc)"
pnpm install
bundle exec ruby .gitlab/configure_environment.rb
bundle exec rake zammad:db:init
