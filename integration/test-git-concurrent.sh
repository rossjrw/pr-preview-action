#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/setup-test-env.sh"
source "$(dirname "$0")/../lib/verify-deployment.sh"

# test-git-concurrent-1 should be as expected
setup_test_env "test-git-concurrent-1"
deployed_path=$(verify_deployment "$DEPLOY_REPO" "$EXPECTED_PATH" "$GITHUB_TOKEN" "$PREVIEW_BRANCH")
if [ -z "$deployed_path" ]; then
    echo >&2 "FAIL: Deployment for test-git-concurrent-1 not found"
    exit 1
fi
assert_file_exists "$deployed_path/index.html"
assert_file_contains "$deployed_path/index.html" "test-git-concurrent-1"
echo "✓ Concurrent deployment test-git-concurrent-1 verified"

# test-git-concurrent-2 should be have had its contents overwritten by its second deployment
setup_test_env "test-git-concurrent-2"
deployed_path=$(verify_deployment "$DEPLOY_REPO" "$EXPECTED_PATH" "$GITHUB_TOKEN" "$PREVIEW_BRANCH")
if [ -z "$deployed_path" ]; then
    echo >&2 "FAIL: Deployment for test-git-concurrent-2 not found"
    exit 1
fi
assert_file_exists "$deployed_path/index.html"
assert_file_contains "$deployed_path/index.html" "test-git-concurrent-2-redeployed"
echo "✓ Concurrent deployment test-git-concurrent-2 verified"

echo "✓ All concurrent deployments verified"
