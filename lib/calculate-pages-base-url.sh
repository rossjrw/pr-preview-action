#!/usr/bin/env bash

# Calculate GitHub Pages base URL from repository name
# Usage: calculate_pages_base_url "org/repo"
# Returns: The GitHub Pages base URL (e.g., "org.github.io/repo" or "org.github.io")
calculate_pages_base_url() {
    local repo="$1"
    local org
    org=$(echo "$repo" | cut -d "/" -f 1)
    local name
    name=$(echo "$repo" | cut -d "/" -f 2)

    # If repo is user.github.io or org.github.io, Pages URL is just the domain
    if [ "$name" = "${org}.github.io" ]; then
        echo "${org}.github.io"
    else
        # Otherwise it's org.github.io/repo
        echo "${org}.github.io/${name}"
    fi
}
