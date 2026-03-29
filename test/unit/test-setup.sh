#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../lib/assert.sh"

FIXTURES_DIR="$(dirname "$0")/../fixtures/events"

echo >&2 "test setup: pages base URL calculation"
echo >&2 "==============================="

export GITHUB_ENV=$(mktemp)
export GITHUB_OUTPUT=$(mktemp)
export GITHUB_EVENT_NAME="pull_request"
export GITHUB_EVENT_PATH="$FIXTURES_DIR/pr-opened.json"
export GITHUB_REPOSITORY="test-owner/test-repo"
export INPUT_ACTION="deploy"
export INPUT_UMBRELLA_DIR="pr-preview"
export INPUT_PAGES_BASE_URL=""
export INPUT_PAGES_BASE_PATH=""
export INPUT_PR_NUMBER="42"
export INPUT_ACTION_REF="v1.0.0"

node dist/setup.js

env_content=$(cat "$GITHUB_ENV")
output_content=$(cat "$GITHUB_OUTPUT")

echo >&2 "ENV content:"
echo >&2 "$env_content"
echo >&2 "OUTPUT content:"
echo >&2 "$output_content"

assert_contains "$output_content" "deployment_action=deploy"
assert_contains "$output_content" "pages_base_url=test-owner.github.io/test-repo"
assert_contains "$output_content" "preview_url_path=pr-preview/pr-42"
assert_contains "$output_content" "preview_url=https://test-owner.github.io/test-repo/pr-preview/pr-42/"
assert_contains "$output_content" "short_sha=abc1234"
assert_contains "$output_content" "preview_url=https://test-owner.github.io/test-repo/pr-preview/pr-42/?v=abc1234"
assert_contains "$output_content" "action_version=v1.0.0"
echo >&2 "test setup: auto action for close event"
echo >&2 "==============================="

export GITHUB_ENV=$(mktemp)
export GITHUB_OUTPUT=$(mktemp)
export INPUT_ACTION="auto"
export GITHUB_EVENT_PATH="$FIXTURES_DIR/pr-closed.json"

node dist/setup.js

output_content=$(cat "$GITHUB_OUTPUT")
assert_contains "$output_content" "deployment_action=remove"

echo >&2 "test setup: github.io repo URL"
echo >&2 "==============================="

export GITHUB_ENV=$(mktemp)
export GITHUB_OUTPUT=$(mktemp)
export GITHUB_REPOSITORY="myuser/myuser.github.io"
export INPUT_ACTION="deploy"
export GITHUB_EVENT_PATH="$FIXTURES_DIR/pr-opened.json"

node dist/setup.js

output_content=$(cat "$GITHUB_OUTPUT")
assert_contains "$output_content" "pages_base_url=myuser.github.io"
assert_contains "$output_content" "preview_url=https://myuser.github.io/pr-preview/pr-42/"

echo >&2 "test setup: custom pages base URL"
echo >&2 "==============================="

export GITHUB_ENV=$(mktemp)
export GITHUB_OUTPUT=$(mktemp)
export GITHUB_REPOSITORY="test-owner/test-repo"
export INPUT_PAGES_BASE_URL="custom.example.com/site"

node dist/setup.js

output_content=$(cat "$GITHUB_OUTPUT")
assert_contains "$output_content" "pages_base_url=custom.example.com/site"
assert_contains "$output_content" "preview_url=https://custom.example.com/site/pr-preview/pr-42/"

echo >&2 "test setup: push event auto-resolves to deploy with root path"
echo >&2 "==============================="

export GITHUB_ENV=$(mktemp)
export GITHUB_OUTPUT=$(mktemp)
export GITHUB_EVENT_NAME="push"
export GITHUB_EVENT_PATH="$FIXTURES_DIR/push.json"
export GITHUB_REPOSITORY="test-owner/test-repo"
export GITHUB_SHA="fedcba9876543210"
export INPUT_ACTION="auto"
export INPUT_UMBRELLA_DIR="pr-preview"
export INPUT_PAGES_BASE_URL=""
export INPUT_PAGES_BASE_PATH=""
export INPUT_PR_NUMBER=""
export INPUT_ACTION_REF="v1.0.0"

node dist/setup.js

output_content=$(cat "$GITHUB_OUTPUT")

echo >&2 "OUTPUT content:"
echo >&2 "$output_content"

assert_contains "$output_content" "deployment_action=deploy"
assert_contains "$output_content" "preview_file_path="
assert_contains "$output_content" "preview_url=https://test-owner.github.io/test-repo/?v=fedcba9"
assert_contains "$output_content" "short_sha=fedcba9"

echo >&2 "test setup: push event SHA fallback to GITHUB_SHA"
echo >&2 "==============================="

export GITHUB_ENV=$(mktemp)
export GITHUB_OUTPUT=$(mktemp)
export GITHUB_EVENT_NAME="pull_request"
export GITHUB_EVENT_PATH="$FIXTURES_DIR/pr-opened.json"
export GITHUB_SHA="1111111222222233"
export INPUT_ACTION="deploy"
export INPUT_PR_NUMBER="42"

node dist/setup.js

output_content=$(cat "$GITHUB_OUTPUT")
# pr-opened.json has a PR SHA, so it should use that instead of GITHUB_SHA
assert_contains "$output_content" "short_sha=abc1234"
