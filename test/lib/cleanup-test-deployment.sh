#!/usr/bin/env bash

# Cleanup utility for integration tests
# Removes test deployments from the target repository

set -e

cleanup_deployment() {
    local deploy_repo="${1:?missing required arg 1: deploy_repo}"
    local preview_branch="${2:?missing required arg 2: preview_branch}"
    local token="${3:?missing required arg 3: token}"
    shift 3
    local paths_to_remove=("$@")

    if [ ${#paths_to_remove[@]} -eq 0 ]; then
        echo "No paths specified for cleanup"
        return 0
    fi

    local temp_dir
    temp_dir=$(mktemp -d)

    echo "Cloning $deploy_repo (branch: $preview_branch) for cleanup..."
    if ! git clone --single-branch --branch "$preview_branch" \
        "https://oauth2:${token}@github.com/${deploy_repo}.git" "$temp_dir" 2> /dev/null; then
        echo "Failed to clone repository for cleanup"
        rm -rf "$temp_dir"
        return 1
    fi

    cd "$temp_dir"

    local removed_any=false
    for path in "${paths_to_remove[@]}"; do
        if [ -e "$path" ]; then
            echo "Removing: $path"
            rm -rf "$path"
            removed_any=true
        fi
    done

    if [ "$removed_any" = true ]; then
        git config user.name "GitHub Actions"
        git config user.email "actions@github.com"
        git add .

        if ! git diff --staged --quiet; then
            git commit -m "Cleanup test deployments 🧹"
            git push
            echo "✓ Cleanup committed and pushed"
        else
            echo "No changes to commit"
        fi
    else
        echo "No paths found to clean up"
    fi

    cd - > /dev/null
    rm -rf "$temp_dir"
}

export -f cleanup_deployment
