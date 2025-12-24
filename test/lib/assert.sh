#!/usr/bin/env bash

# Common assertion functions for test scripts

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

assert_equals() {
    local expected="$1"
    local actual="$2"
    if [ "$expected" != "$actual" ]; then
        echo -e "${RED}FAIL: expected='$expected', actual='$actual'${RESET}" >&2
        return 1
    fi
    return 0
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}PASS: $message${RESET}" >&2
        return 0
    else
        echo -e "${RED}FAIL: $message (needle='$needle' not in haystack)${RESET}" >&2
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"

    if [ -f "$file" ]; then
        echo -e "${GREEN}PASS: $message${RESET}" >&2
        return 0
    else
        echo -e "${RED}FAIL: $message${RESET}" >&2
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local needle="$2"
    local message="${3:-File should contain: $needle}"

    if [ ! -f "$file" ]; then
        echo -e "${RED}FAIL: File does not exist: $file${RESET}" >&2
        return 1
    fi

    content=$(cat "$file")
    assert_contains "$content" "$needle" "$message"
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory should exist: $dir}"

    if [ -d "$dir" ]; then
        echo -e "${GREEN}PASS: $message${RESET}" >&2
        return 0
    else
        echo -e "${RED}FAIL: $message${RESET}" >&2
        return 1
    fi
}

# Assert URL returns 200 (with retries for GitHub Pages build lag)
assert_url_ok() {
    local url="$1"
    local message="${2:-URL should return 200}"
    local max_retries="${3:-6}"
    local retry_delay="${4:-5}"

    for ((i = 1; i <= max_retries; i++)); do
        status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2> /dev/null || echo "000")
        [ "$status" = "200" ] && return 0
        sleep "$retry_delay"
    done

    echo -e "${RED}FAIL: $message (status $status)${RESET}" >&2
    return 1
}

assert_url_contains() {
    local url="$1"
    local needle="$2"
    local message="${3:-URL should contain: $needle}"

    content=$(curl -s "$url" 2> /dev/null || echo "")
    [ -n "$content" ] || {
        echo -e "${RED}FAIL: Could not fetch URL${RESET}" >&2
        return 1
    }
    assert_contains "$content" "$needle" "$message"
}

assert_url_not_found() {
    local url="$1"
    local message="${2:-URL should return 404}"
    local max_retries="${3:-6}"
    local retry_delay="${4:-3}"

    for ((i = 1; i <= max_retries; i++)); do
        status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2> /dev/null || echo "000")
        [ "$status" = "404" ] && return 0
        sleep "$retry_delay"
    done

    echo -e "${RED}FAIL: $message (status $status)${RESET}" >&2
    return 1
}
