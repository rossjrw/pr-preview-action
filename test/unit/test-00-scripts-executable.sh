#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../lib/assert.sh"

# This test validates that all test scripts are executable
# This ensures that test scripts can be run directly and helps catch permission issues early

test_root="$(dirname "$0")/.."
failed_scripts=()
checked_count=0

echo "Checking test script permissions..."

# Check all shell scripts in test directories
for script in \
    "$test_root"/unit/test-*.sh \
    "$test_root"/integration/test-*.sh \
    "$test_root"/lib/*.sh; do

    if [ -f "$script" ]; then
        checked_count=$((checked_count + 1))
        script_name=$(basename "$script")

        if [ ! -x "$script" ]; then
            echo "✗ $script_name is not executable"
            failed_scripts+=("$script")
        fi
    fi
done

echo "Checked $checked_count test scripts"

if [ ${#failed_scripts[@]} -gt 0 ]; then
    echo ""
    echo "The following scripts are not executable:"
    for script in "${failed_scripts[@]}"; do
        echo "  - $script"
    done
    echo ""
    echo "Fix with: chmod +x <script>"
    exit 1
fi

echo "✓ All test scripts are executable"
