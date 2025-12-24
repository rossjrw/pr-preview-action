#!/usr/bin/env bash

# Get the commit SHA that was just deployed to the target branch
#
# Required environment variables:
#   DEPLOY_REPO - Repository in owner/repo format
#   DEPLOY_BRANCH - Branch name (e.g., gh-pages)
#   DEPLOY_TOKEN - GitHub token for API access

set -e

if [ -z "$DEPLOY_REPO" ] || [ -z "$DEPLOY_BRANCH" ] || [ -z "$DEPLOY_TOKEN" ]; then
    echo "Error: DEPLOY_REPO, DEPLOY_BRANCH, and DEPLOY_TOKEN are required"
    exit 1
fi

# Get the latest commit SHA from the deployment branch
DEPLOYED_SHA=$(curl -s -H "Authorization: token $DEPLOY_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$DEPLOY_REPO/git/refs/heads/$DEPLOY_BRANCH" \
    | grep -o '"sha": "[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$DEPLOYED_SHA" ]; then
    echo "Error: Failed to get commit SHA from $DEPLOY_BRANCH"
    exit 1
fi

# Verify we got a full-length SHA (40 characters)
if [ ${#DEPLOYED_SHA} -ne 40 ]; then
    echo "Error: Expected 40-character SHA, got ${#DEPLOYED_SHA} characters: $DEPLOYED_SHA"
    exit 1
fi

echo "Deployed commit: $DEPLOYED_SHA"
echo "deployed_commit_sha=$DEPLOYED_SHA" >> "$GITHUB_OUTPUT"
