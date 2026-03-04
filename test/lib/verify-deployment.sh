#!/usr/bin/env bash

verify_deployment() {
    local deploy_repo="${1:?missing required arg 1: deploy_repo}"
    local preview_path="${2:?missing required arg 2: preview_path}"
    local token="${3:?missing required arg 3: token}"
    local preview_branch="${4:?missing required arg 4: preview_branch}"

    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    echo >&2 "Cloning repo $deploy_repo branch $preview_branch..."
    if ! git clone --single-branch --branch "$preview_branch" "https://oauth2:${token}@github.com/${deploy_repo}.git" "$temp_dir"; then
        echo >&2 "FAIL: Could not clone $deploy_repo"
        return 1
    fi

    echo >&2 "Checking for preview path: $preview_path"
    if [ ! -d "$temp_dir/$preview_path" ]; then
        echo >&2 "FAIL: Preview path not found: $preview_path"
        return 1
    fi

    echo "$temp_dir/$preview_path"
}

verify_removal() {
    local deploy_repo="${1:?missing required arg 1: deploy_repo}"
    local preview_path="${2:?missing required arg 2: preview_path}"
    local token="${3:?missing required arg 3: token}"
    local preview_branch="${4:?missing required arg 4: preview_branch}"

    if [ -z "$token" ]; then
        echo >&2 "ERROR: GITHUB_TOKEN is required for verify_removal"
        return 1
    fi

    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    echo >&2 "Cloning repo $deploy_repo branch $preview_branch..."
    if ! git clone --single-branch --branch "$preview_branch" "https://oauth2:${token}@github.com/${deploy_repo}.git" "$temp_dir"; then
        echo >&2 "FAIL: Could not clone $deploy_repo"
        return 1
    fi

    echo >&2 "Checking if preview path still exists: $preview_path"
    if [ -d "$temp_dir/$preview_path" ]; then
        echo >&2 "FAIL: Preview path still exists: $preview_path"
        return 1
    fi
}

export -f verify_deployment
export -f verify_removal
