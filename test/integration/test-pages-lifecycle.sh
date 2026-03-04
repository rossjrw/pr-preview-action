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

        # Test wait-for-pages-lifecycle.sh can find the completed build
        echo "Testing wait script can find existing build..."

        DEPLOYED_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/$DEPLOY_REPO/git/refs/heads/$PREVIEW_BRANCH" \
            | grep -o '"sha": "[^"]*"' | head -1 | cut -d'"' -f4)

        echo "Testing with commit: ${DEPLOYED_SHA:0:7}"

        bash "$(dirname "$0")/../../lib/wait-for-pages-deployment.sh" \
            "$DEPLOY_REPO" \
            "$DEPLOYED_SHA" \
            "$PREVIEW_BRANCH" \
            "$GITHUB_TOKEN" \
            30

        echo "✓ Wait script successfully found and verified the build"
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
