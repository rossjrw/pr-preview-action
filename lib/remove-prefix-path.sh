#!/usr/bin/env bash

# Remove leading dotslash, leading/trailing slash; collapse multiple slashes
normalise_path() {
    echo "$1" | sed -e 's|^\./||g' -e 's|^/||g' -e 's|/*$||g' -e 's|//*|/|g'
}

# Removes a base path from the start of another path
# Usage: remove_prefix_path "base_path" "original_path"
remove_prefix_path() {
    local base_path="$1"
    local original_path="$2"

    base_path=$(normalise_path "$base_path")
    original_path=$(normalise_path "$original_path")

    echo "${original_path#"$base_path"/}"
}
