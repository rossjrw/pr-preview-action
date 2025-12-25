#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../lib/assert.sh"

# Test comment generation by running setup and generating comments
# This simulates what the action does without actually deploying anything

test_deployment_action="${1:-deploy}"

echo "Testing comment generation for action: $test_deployment_action"

# Set up environment for main.sh - all must be provided
export GITHUB_ACTION_PATH="${GITHUB_ACTION_PATH:?missing GITHUB_ACTION_PATH}"
export deployment_action="$test_deployment_action"
export umbrella_path="${umbrella_path:?missing umbrella_path}"
export pages_base_url="${pages_base_url-}"
export pages_base_path="${pages_base_path-}"
export pr_number="${pr_number:?missing pr_number}"
export github_action_ref="${github_action_ref:?missing github_action_ref}"
export github_action_repository="${github_action_repository:?missing github_action_repository}"
export deployment_repository="${deployment_repository:?missing deployment_repository}"
export token="${token:?missing token}"
export deprecated_custom_url="${deprecated_custom_url-}"

# Create temporary files for GitHub Actions environment if not in GHA
if [ -z "$GITHUB_ENV" ]; then
    export GITHUB_ENV=$(mktemp)
    trap "rm -f $GITHUB_ENV" EXIT
fi
if [ -z "$GITHUB_OUTPUT" ]; then
    export GITHUB_OUTPUT=$(mktemp)
    trap "rm -f $GITHUB_OUTPUT" EXIT
fi

# Run the setup script to generate environment variables
source lib/main.sh

# Read environment variables from GITHUB_ENV (handle values with spaces)
while IFS='=' read -r key value; do
    [ -n "$key" ] && export "$key=$value"
done < "$GITHUB_ENV"

# Generate the comment using the same script the action uses
comment_file="comment-generated-${test_deployment_action}.md"
bash lib/generate-comment.sh \
    "$action_repository" \
    "$action_version" \
    "$preview_url" \
    "gh-pages" \
    "https://github.com" \
    "$deployment_repository" \
    "$action_start_time" \
    "$test_deployment_action" \
    > "$comment_file"

echo "=== Generated $test_deployment_action comment content ==="
cat "$comment_file"
echo "========================================"

# Verify the comment contains expected content
if [ "$test_deployment_action" = "deploy" ]; then
    assert_file_contains "$comment_file" "PR Preview Action"
    assert_file_contains "$comment_file" "$action_version"
    assert_file_contains "$comment_file" "$preview_url"
    assert_file_contains "$comment_file" "Built to branch"
    assert_file_contains "$comment_file" "pr-$pr_number"
    echo "✓ Deploy comment content verified"
elif [ "$test_deployment_action" = "remove" ]; then
    assert_file_contains "$comment_file" "PR Preview Action"
    assert_file_contains "$comment_file" "$action_version"
    assert_file_contains "$comment_file" "Preview removed"
    echo "✓ Removal comment content verified"
fi
