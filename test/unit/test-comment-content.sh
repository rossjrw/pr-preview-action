#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../lib/assert.sh"

# Test configuration
export GITHUB_REPOSITORY="test-owner/test-repo"
export GITHUB_SERVER_URL="https://github.com"
export GITHUB_API_URL="https://api.github.com"
export action_version="v1.0.0-test"
export preview_url="https://test-owner.github.io/test-repo/pr-preview/pr-12345/?v=abc1234"
export action_start_time="2025-01-01 12:00 UTC"
export INPUT_PREVIEW_BRANCH="gh-pages"
export INPUT_COMMENT="true"
export INPUT_QR_CODE="true"
export DRY_RUN="true"
export deployment_action="deploy"

comment_file="comment-generated.md"

echo >&2 "test comment: deployment with QR code (default)"
echo >&2 "==============================="
node dist/comment.js > "$comment_file"
cat >&2 "$comment_file"
echo >&2 "==============================="

assert_file_contains "$comment_file" "PR Preview Action"
assert_file_contains "$comment_file" "$action_version"
assert_file_contains "$comment_file" "$preview_url"
assert_file_contains "$comment_file" "pr-preview"
# QR code should be a data URI, not an external URL
# QR code should be a data URI (GIF if ImageMagick available, PNG otherwise)
assert_file_contains "$comment_file" "data:image/"

echo >&2 "test comment: removal"
echo >&2 "==============================="
export deployment_action="remove"
node dist/comment.js > "$comment_file"
cat >&2 "$comment_file"
echo >&2 "==============================="

assert_file_contains "$comment_file" "PR Preview Action"
assert_file_contains "$comment_file" "$action_version"
assert_file_contains "$comment_file" "Preview removed"

echo >&2 "test comment: deployment with QR code disabled"
echo >&2 "==============================="
export deployment_action="deploy"
export INPUT_QR_CODE="false"
node dist/comment.js > "$comment_file"
cat >&2 "$comment_file"
echo >&2 "==============================="

# Should NOT contain a QR code
assert_file_contains "$comment_file" "data:image/" && exit 1 || true
assert_file_contains "$comment_file" "$preview_url"
