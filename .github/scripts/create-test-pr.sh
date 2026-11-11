#!/usr/bin/env bash

# Create a test PR for validating a contributor's PR
# Usage: ./create-test-pr.sh <PR_NUMBER>

set -e

PR_NUMBER="${1:?Usage: $0 <PR_NUMBER>}"

echo "Creating test PR for #$PR_NUMBER..."

# Fetch the contributor's PR
echo "Fetching PR #$PR_NUMBER..."
git fetch origin pull/"$PR_NUMBER"/head:test-pr-"$PR_NUMBER"-tmp

# Create test branch
git checkout -b test-pr-"$PR_NUMBER" test-pr-"$PR_NUMBER"-tmp

# Clean up temp branch
git branch -D test-pr-"$PR_NUMBER"-tmp

echo ""
echo "✓ Checked out contributor's code in branch: test-pr-$PR_NUMBER"
echo ""
echo "Next steps:"
echo "  1. Write your tests"
echo "  2. Commit them: git commit -am 'Add tests for PR #$PR_NUMBER'"
echo "  3. Run: ./.github/scripts/push-test-pr.sh $PR_NUMBER"
