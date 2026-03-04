#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/setup-test-env.sh"
source "$(dirname "$0")/../lib/verify-deployment.sh"

setup_test_env "test-git-lifecycle"

test_step="${1:?missing test_step}"

case "$test_step" in
    deployed)
        verification_token="${2:?missing verification_token}"
        deployed_path=$(verify_deployment "$DEPLOY_REPO" "$EXPECTED_PATH" "$GITHUB_TOKEN" "$PREVIEW_BRANCH")
        [ -n "$deployed_path" ] || exit 1
        assert_file_exists "$deployed_path/index.html"
        assert_file_contains "$deployed_path/index.html" "$verification_token"
        echo "✓ Initial deployment verified via git"
        ;;

    removed)
        if verify_removal "$DEPLOY_REPO" "$EXPECTED_PATH" "$GITHUB_TOKEN" "$PREVIEW_BRANCH"; then
            echo "✓ Removal verified via git"
        else
            echo >&2 "FAIL: Removal verification failed"
            exit 1
        fi
        ;;

    *)
        echo >&2 "ERROR: Invalid test_step: $test_step"
        exit 1
        ;;
esac
