#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/setup-test-env.sh"
source "$(dirname "$0")/../lib/verify-deployment.sh"

# Test custom umbrella-dir deployment
export UMBRELLA_DIR="${CUSTOM_UMBRELLA_DIR:?missing CUSTOM_UMBRELLA_DIR}"
setup_test_env "test-git-custom-umbrella"

deployed_path=$(verify_deployment "$DEPLOY_REPO" "$EXPECTED_PATH" "$GITHUB_TOKEN" "$PREVIEW_BRANCH")
[ -n "$deployed_path" ] || exit 1

assert_file_exists "$deployed_path/index.html"
assert_file_contains "$deployed_path/index.html" "test-git-custom-umbrella"

echo "✓ Custom umbrella-dir verified via git"
