#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../../lib/wait-for-pages-deployment.sh"
source "$(dirname "$0")/../lib/assert.sh"

# Find build ID for matching commit
builds_response='[
  {"url": "https://api.github.com/repos/test/repo/pages/builds/12345", "status": "building", "commit": "abc123def456"},
  {"url": "https://api.github.com/repos/test/repo/pages/builds/12344", "status": "built", "commit": "oldcommit123"}
]'
target_sha="abc123def456"
build_id=$(find_build_id_for_sha "$builds_response" "$target_sha")
assert_equals "12345" "$build_id"

# Handle commit not found in builds list
builds_response='[
  {"url": "https://api.github.com/repos/test/repo/pages/builds/12344", "status": "built", "commit": "other123"}
]'
target_sha="notfound456"
build_id=$(find_build_id_for_sha "$builds_response" "$target_sha")
assert_equals "" "$build_id"

# Extract status from build response
build_response='{"commit":"abc123","status":"built","url":"https://api.github.com/repos/test/repo/pages/builds/12345"}'
status=$(extract_status_from_response "$build_response")
assert_equals "built" "$status"
