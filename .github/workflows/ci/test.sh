#!/usr/bin/env bash

# CI run only: run the specs of the changed code first, then everything, and report all failures.

set -o pipefail

# shellcheck disable=SC1091
source /etc/profile.d/rvm.sh
# shellcheck disable=SC1091
source .gitlab/environment.env

FAILED=()

function check() {
  local NAME=$1
  shift
  echo "::group::$NAME"
  if "$@"; then
    echo "CHECK OK: $NAME"
  else
    echo "CHECK FAILED: $NAME"
    FAILED+=("$NAME")
  fi
  echo "::endgroup::"
}

check "db init" bundle exec rake zammad:db:init
check "affected specs" bundle exec rspec \
  spec/requests/channels_email_microsoft_graph_notification_spec.rb \
  spec/models/channel_spec.rb \
  spec/lib/external_credential/microsoft_graph_spec.rb \
  spec/services/service/system/set_email_notification_configuration_spec.rb \
  spec/requests/external_credentials_spec.rb \
  spec/requests/channels_email_spec.rb \
  spec/requests/getting_started_spec.rb \
  spec/lib/email_helper_spec.rb \
  spec/lib/notification_factory/mailer_spec.rb
check "assets precompile" bundle exec rake assets:precompile
check "front end tests" pnpm test
check "db init" bundle exec rake zammad:db:init
check "rspec" bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb" -t ~searchindex -t ~integration -t ~required_envs

echo "FAILED CHECKS (${#FAILED[@]}): ${FAILED[*]}"
[ ${#FAILED[@]} -eq 0 ]
