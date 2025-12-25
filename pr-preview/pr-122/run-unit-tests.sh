#!/usr/bin/env bash

set -e

test_count=0
passed_count=0
failed_count=0
failed_tests=()

for testscript in test/unit/test-*.sh; do
    if [ -f "$testscript" ]; then
        test_count=$((test_count + 1))
        test_name=$(basename "$testscript")

        if bash "$testscript"; then
            passed_count=$((passed_count + 1))
            echo "✓ $test_name"
        else
            failed_count=$((failed_count + 1))
            failed_tests+=("$test_name")
            echo "✗ $test_name"
        fi

        echo ""
    fi
done

echo "Total tests: $test_count"
echo "Passed: $passed_count"
echo "Failed: $failed_count"

if [ $failed_count -gt 0 ]; then
    for test in "${failed_tests[@]}"; do
        echo "  - $test"
    done
    exit 1
fi
