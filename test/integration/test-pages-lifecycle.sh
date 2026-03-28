#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/setup-test-env.sh"
source "$(dirname "$0")/../lib/verify-deployment.sh"

setup_test_env "test-pages-lifecycle"

test_step="${1:?missing test_step}"

case "$test_step" in
    deployed)
        deployed_path=$(verify_deployment "$DEPLOY_REPO" "$EXPECTED_PATH" "$GITHUB_TOKEN" "$PREVIEW_BRANCH")
        [ -n "$deployed_path" ] || exit 1
        echo "✓ Deployment verified via git"

        assert_url_ok "$EXPECTED_URL"
        assert_url_contains "$EXPECTED_URL" "test-pages-lifecycle"
        echo "✓ Deployment verified via HTTP"

        ;;

    removed)
        assert_url_not_found "$EXPECTED_URL"
        echo "✓ Removal verified via HTTP"
        ;;

    *)
        echo >&2 "ERROR: Invalid test_step: $test_step"
        exit 1
        ;;
esac
