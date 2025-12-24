#!/usr/bin/env bash

set -e

echo >&2 "$0: start"

source "$(dirname "$0")/../lib/remove-prefix-path.sh"

assert() {
    echo >&2 "$1" = "$2"
    if [ "$1" != "$2" ]; then
        echo >&2 "$0: fail"
        exit 1
    fi
}

assert "$(remove_prefix_path "" "")" ""
assert "$(remove_prefix_path "" "a/b/c/d")" a/b/c/d
assert "$(remove_prefix_path "/" "a/b/c/d")" a/b/c/d
assert "$(remove_prefix_path "/" "/a/b/c/d")" a/b/c/d
assert "$(remove_prefix_path "//" "/a/b/c/d")" a/b/c/d
assert "$(remove_prefix_path "a/b" "a/b/c/d")" c/d
assert "$(remove_prefix_path "./a/b/" "a/b/c/d")" c/d
assert "$(remove_prefix_path "a/b" "./a/b/c/d/")" c/d
assert "$(remove_prefix_path "./a//b//" "./a//b//c//d/")" c/d
assert "$(remove_prefix_path ".//a/b" "./a/b/c/d")" c/d
assert "$(remove_prefix_path "/a/b" "a/b/c/d")" c/d
assert "$(remove_prefix_path "/a/b/" "/a/b/c/d/")" c/d
assert "$(remove_prefix_path "a/b" "/a/b/c/d")" c/d
assert "$(remove_prefix_path "a/b" "c/d/a/b")" c/d/a/b
assert "$(remove_prefix_path "e/f" "a/b/c/d")" "$(remove_prefix_path "" "a/b/c/d")"

echo >&2 "$0: ok"
