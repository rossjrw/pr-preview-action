#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../../lib/determine-auto-action.sh"
source "$(dirname "$0")/../lib/assert.sh"

assert_action() {
    local event_file
    event_file=$(mktemp)
    echo "{\"action\": \"$2\"}" > "$event_file"

    actual=$(determine_auto_action "$1" "$event_file" 2> /dev/null)
    rm "$event_file"

    assert_equals "$3" "$actual"
}

assert_action "pull_request" "opened" "deploy"
assert_action "pull_request" "reopened" "deploy"
assert_action "pull_request" "synchronize" "deploy"

assert_action "pull_request" "closed" "remove"

assert_action "pull_request" "edited" "none"
assert_action "pull_request" "labeled" "none"
assert_action "pull_request" "unlabeled" "none"
assert_action "pull_request" "assigned" "none"

assert_action "pull_request_target" "opened" "deploy"
assert_action "pull_request_target" "reopened" "deploy"
assert_action "pull_request_target" "synchronize" "deploy"
assert_action "pull_request_target" "closed" "remove"

assert_action "push" "anything" "none"
assert_action "workflow_dispatch" "anything" "none"
assert_action "unknown" "opened" "none"
assert_action "" "opened" "none"
