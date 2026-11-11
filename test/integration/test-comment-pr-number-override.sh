#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../lib/assert.sh"

test_step="${1:?missing test_step}"
dummy_pr_number="${2:?missing dummy_pr_number}"

DEPLOY_REPO="${DEPLOY_REPO:?env var DEPLOY_REPO is required}"
GITHUB_TOKEN="${GITHUB_TOKEN:?env var GITHUB_TOKEN is required}"
TEST_RUN_ID="${TEST_RUN_ID:?missing env var TEST_RUN_ID}"

COMMENT_HEADER="pr-preview"

verify_comment_exists() {
    local pr_number="$1"
    local expected_pattern="$2"

    echo "Fetching comments for PR #$pr_number in $DEPLOY_REPO..."

    local comments_response
    comments_response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$DEPLOY_REPO/issues/$pr_number/comments")

    if echo "$comments_response" | grep -q '"message"'; then
        echo >&2 "FAIL: API error: $(echo "$comments_response" | grep -o '"message": "[^"]*"')"
        return 1
    fi

    local matching_comment
    matching_comment=$(echo "$comments_response" | grep -o "<!-- $COMMENT_HEADER -->.*" | head -1)

    if [ -z "$matching_comment" ]; then
        echo >&2 "FAIL: No comment with header '$COMMENT_HEADER' found on PR #$pr_number"
        echo >&2 "Available comments:"
        echo "$comments_response" | grep -o '"body": "[^"]*"' | head -5
        return 1
    fi

    echo "✓ Found comment with header '$COMMENT_HEADER'"

    if [ -n "$expected_pattern" ]; then
        if echo "$comments_response" | grep -q "$expected_pattern"; then
            echo "✓ Comment contains expected pattern: $expected_pattern"
        else
            echo >&2 "FAIL: Comment does not contain expected pattern: $expected_pattern"
            return 1
        fi
    fi

    local comment_id_value
    comment_id_value=$(echo "$comments_response" | grep -B 20 "<!-- $COMMENT_HEADER -->" | grep -o '"id": [0-9]*' | head -1 | cut -d' ' -f2)
    export COMMENT_ID="$comment_id_value"
    echo "Comment ID: $COMMENT_ID"
}

delete_comment() {
    local pr_number="$1"
    local comment_id="${2:-$COMMENT_ID}"

    if [ -z "$comment_id" ]; then
        echo "No comment ID provided, skipping deletion"
        return 0
    fi

    echo "Deleting comment $comment_id from PR #$pr_number..."

    local delete_response
    delete_response=$(curl -s -w "\n%{http_code}" -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$DEPLOY_REPO/issues/comments/$comment_id")

    local http_code
    http_code=$(echo "$delete_response" | tail -n 1)

    if [ "$http_code" = "204" ]; then
        echo "✓ Comment deleted successfully"
    else
        echo >&2 "WARNING: Failed to delete comment (HTTP $http_code)"
        echo >&2 "$delete_response"
        # Don't fail the test if cleanup fails
    fi
}

case "$test_step" in
    verify-deploy)
        verify_comment_exists "$dummy_pr_number" "run-$TEST_RUN_ID-deployed"
        echo "✓ Deploy comment verified on PR #$dummy_pr_number (pr-number override)"
        ;;

    verify-remove)
        verify_comment_exists "$dummy_pr_number" "Preview removed"
        echo "✓ Remove comment verified on PR #$dummy_pr_number (pr-number override)"
        ;;

    cleanup)
        delete_comment "$dummy_pr_number"
        ;;

    *)
        echo >&2 "ERROR: Invalid test_step: $test_step"
        echo >&2 "Valid steps: verify-deploy, verify-remove, cleanup"
        exit 1
        ;;
esac
