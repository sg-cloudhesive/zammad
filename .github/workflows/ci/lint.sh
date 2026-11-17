#!/usr/bin/env bash

# CI run only: run every check and report all failures, instead of stopping at the first one.

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

function po_syntax() {
  local RESULT=0
  for FILE in i18n/zammad.pot; do msgfmt -o /dev/null -c "$FILE" || RESULT=1; done
  return $RESULT
}

check "po syntax" po_syntax
check "pot catalog consistency" bundle exec rails generate zammad:translation_catalog --check
check "brakeman" bundle exec brakeman -o /dev/stdout -o tmp/brakeman-report.html
check "zeitwerk" bundle exec rails zeitwerk:check
check "graphql api consistency" .gitlab/check_graphql_api_consistency.sh
check "rubocop todos" bundle exec .dev/rubocop/validate_todos.rb
check "rubocop" bundle exec rubocop --parallel
check "coffeelint" bash -c 'coffeelint --rules ./.dev/coffeelint/rules/* app/'
check "type check" pnpm lint:ts
check "eslint" pnpm lint:js
check "stylelint" pnpm lint:css

echo "FAILED CHECKS (${#FAILED[@]}): ${FAILED[*]}"
[ ${#FAILED[@]} -eq 0 ]
