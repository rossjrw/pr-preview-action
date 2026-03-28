#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../lib/assert.sh"

FIXTURES_DIR="$(dirname "$0")/../fixtures/html"

echo >&2 "test inject-cache-bust: injects script into HTML files"
echo >&2 "==============================="

# Create a temp directory with test HTML files
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Copy multi-page fixture
cp -r "$FIXTURES_DIR/multi-page/." "$tmpdir/"

# Run the injection via a small node script
node -e "
const { injectCacheBustScript } = require('$(pwd)/dist/inject-cache-bust');
injectCacheBustScript('$tmpdir');
"

# Verify script was injected into all HTML files
assert_file_contains "$tmpdir/index.html" "location.search" "index.html should contain cache-bust script"
assert_file_contains "$tmpdir/about.html" "location.search" "about.html should contain cache-bust script"
assert_file_contains "$tmpdir/contact.html" "location.search" "contact.html should contain cache-bust script"

# Verify the script is before </body>
assert_file_contains "$tmpdir/index.html" "</script></body>" "script should be injected before </body>"

# Verify original content is preserved
assert_file_contains "$tmpdir/index.html" "<h1>Home</h1>" "original content should be preserved"
assert_file_contains "$tmpdir/about.html" "<h1>About</h1>" "original content should be preserved"

echo >&2 "test inject-cache-bust: handles nested directories"
echo >&2 "==============================="

tmpdir2=$(mktemp -d)
trap 'rm -rf "$tmpdir" "$tmpdir2"' EXIT

cp -r "$FIXTURES_DIR/nested/." "$tmpdir2/"

node -e "
const { injectCacheBustScript } = require('$(pwd)/dist/inject-cache-bust');
injectCacheBustScript('$tmpdir2');
"

assert_file_contains "$tmpdir2/index.html" "location.search" "nested index.html should contain cache-bust script"

# Non-HTML files should not be modified
assert_file_not_contains "$tmpdir2/assets/script.js" "location.search" "JS files should not be modified"
assert_file_not_contains "$tmpdir2/assets/style.css" "location.search" "CSS files should not be modified"

echo >&2 "test inject-cache-bust: handles empty directory"
echo >&2 "==============================="

tmpdir3=$(mktemp -d)
trap 'rm -rf "$tmpdir" "$tmpdir2" "$tmpdir3"' EXIT

# Should not error on empty directory
node -e "
const { injectCacheBustScript } = require('$(pwd)/dist/inject-cache-bust');
injectCacheBustScript('$tmpdir3');
"

echo >&2 "All inject-cache-bust tests passed!"
