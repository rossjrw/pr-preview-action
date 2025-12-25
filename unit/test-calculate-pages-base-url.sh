#!/usr/bin/env bash

set -e

source "$(dirname "$0")/../../lib/calculate-pages-base-url.sh"
source "$(dirname "$0")/../lib/assert.sh"

assert_equals "$(calculate_pages_base_url "user/repo")" "user.github.io/repo"
assert_equals "$(calculate_pages_base_url "user/user.github.io")" "user.github.io"
assert_equals "$(calculate_pages_base_url "orgname/orgname.github.io")" "orgname.github.io"
assert_equals "$(calculate_pages_base_url "myorg/myproject")" "myorg.github.io/myproject"
assert_equals "$(calculate_pages_base_url "user/my-repo-name")" "user.github.io/my-repo-name"
assert_equals "$(calculate_pages_base_url "user/my.repo.name")" "user.github.io/my.repo.name"
