#!/usr/bin/env bash

set -e

echo >&2 "$0: start"

testscript=$(dirname "$0")/../lib/remove-prefix-path.sh

assert() {
  echo >&2 "$1" = "$2"
  if [ "$1" != "$2" ]; then
    echo >&2 "$0: fail"
    exit 1
  fi
}

assert "$($testscript -b "" -o "")" ""
assert "$($testscript -b "" -o a/b/c/d)" a/b/c/d
assert "$($testscript -b "/" -o a/b/c/d)" a/b/c/d
assert "$($testscript -b "/" -o /a/b/c/d)" a/b/c/d
assert "$($testscript -b "//" -o /a/b/c/d)" a/b/c/d
assert "$($testscript -b a/b -o a/b/c/d)" c/d
assert "$($testscript -b ./a/b/ -o a/b/c/d)" c/d
assert "$($testscript -b a/b -o ./a/b/c/d/)" c/d
assert "$($testscript -b ./a//b// -o ./a//b//c//d/)" c/d
assert "$($testscript -b .//a/b -o ./a/b/c/d)" c/d
assert "$($testscript -b /a/b -o a/b/c/d)" c/d
assert "$($testscript -b /a/b/ -o /a/b/c/d/)" c/d
assert "$($testscript -b a/b -o /a/b/c/d)" c/d
assert "$($testscript -b a/b -o c/d/a/b)" c/d/a/b

# If there is no match, replacement with nothing should return the same result
assert "$($testscript -b "e/f" -o a/b/c/d)" "$($testscript -b "" -o a/b/c/d)"

echo >&2 "$0: ok"
