#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../../lib/remove-prefix-path.sh"
source "$(dirname "$0")/../lib/assert.sh"

assert_equals "$(remove_prefix_path "" "")" ""
assert_equals "$(remove_prefix_path "" "a/b/c/d")" a/b/c/d
assert_equals "$(remove_prefix_path "/" "a/b/c/d")" a/b/c/d
assert_equals "$(remove_prefix_path "/" "/a/b/c/d")" a/b/c/d
assert_equals "$(remove_prefix_path "//" "/a/b/c/d")" a/b/c/d
assert_equals "$(remove_prefix_path "a/b" "a/b/c/d")" c/d
assert_equals "$(remove_prefix_path "./a/b/" "a/b/c/d")" c/d
assert_equals "$(remove_prefix_path "a/b" "./a/b/c/d/")" c/d
assert_equals "$(remove_prefix_path "./a//b//" "./a//b//c//d/")" c/d
assert_equals "$(remove_prefix_path ".//a/b" "./a/b/c/d")" c/d
assert_equals "$(remove_prefix_path "/a/b" "a/b/c/d")" c/d
assert_equals "$(remove_prefix_path "/a/b/" "/a/b/c/d/")" c/d
assert_equals "$(remove_prefix_path "a/b" "/a/b/c/d")" c/d
assert_equals "$(remove_prefix_path "a/b" "c/d/a/b")" c/d/a/b
assert_equals "$(remove_prefix_path "e/f" "a/b/c/d")" "$(remove_prefix_path "" "a/b/c/d")"
