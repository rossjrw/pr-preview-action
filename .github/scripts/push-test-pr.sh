#!/usr/bin/env bash

# Push test PR and create it on GitHub
# Usage: ./push-test-pr.sh <PR_NUMBER>

set -e

PR_NUMBER="${1:?Usage: $0 <PR_NUMBER>}"
BRANCH="test-pr-$PR_NUMBER"

# Check we're on the right branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo "Error: Not on branch $BRANCH (currently on $CURRENT_BRANCH)"
    exit 1
fi

# Push the branch
echo "Pushing branch $BRANCH..."
git push origin "$BRANCH"

if ! command -v gh &> /dev/null; then
    echo "GitHub CLI not found, skipping PR creation."
    exit 1
fi

echo "Creating draft PR..."

gh pr create --draft --title "Test PR #$PR_NUMBER" --label "tests" --body "*Tests for #$PR_NUMBER
* Must be merged AFTER #$PR_NUMBER

See CONTRIBUTING.md for details and for how to update this PR if the base PR changes.
"

echo ""
echo "✓ Draft PR created"
