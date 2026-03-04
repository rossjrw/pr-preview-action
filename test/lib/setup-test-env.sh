#!/usr/bin/env bash

# Set up test environment for integration tests

source "$(dirname "$0")/../../lib/calculate-pages-base-url.sh"

setup_test_env() {
    local pr_identifier="${1:?missing required arg 1: pr_identifier}"

    export TEST_RUN_ID="${GITHUB_RUN_ID:?env var GITHUB_RUN_ID is required}"
    export DEPLOY_REPO="${DEPLOY_REPO:?env var DEPLOY_REPO is required}"
    export PREVIEW_BRANCH="${PREVIEW_BRANCH:?env var PREVIEW_BRANCH is required}"
    export UMBRELLA_DIR="${UMBRELLA_DIR:?env var UMBRELLA_DIR is required}"

    PAGES_BASE_URL=$(calculate_pages_base_url "$DEPLOY_REPO")
    export PAGES_BASE_URL
    export EXPECTED_PATH="$UMBRELLA_DIR/pr-$pr_identifier"
    export EXPECTED_URL="https://$PAGES_BASE_URL/$EXPECTED_PATH/"
}

export -f setup_test_env
