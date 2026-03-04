#!/usr/bin/env bash

set -euo pipefail

help() {
    echo ""
    echo "Usage: $0 -p github_repository -f git_ref"
    echo -e "\t-p GitHub repository to clone, format: owner/repo"
    echo -e "\t-f Reference of repository to clone"
    exit 1
} >&2

while getopts "p:f:" opt; do
    case "$opt" in
        p) github_repository="$OPTARG" ;;
        f) git_ref="$OPTARG" ;;
        ?) help ;;
    esac
done

if [ -z "$github_repository" ] || [ -z "$git_ref" ]; then
    echo >&2 "some parameters are empty"
    help
fi

echo >&2 "Determining Git tag for $github_repository@$git_ref"

case $git_ref in
    refs/pull/*)
        # If the ref is a github virtual pull request merge, this is not a valid git ref
        # Although this script is meant to be portable, action_ref being a PR merge can only happen for PRs to the action repo - in which case it is already checked out
        echo >&2 "Assuming that's *this* repository..."
        if eval "$(git rev-parse --is-shallow-repository)"; then
            git fetch --prune --unshallow
        fi
        git_ref=HEAD
        ;;
    *)
        echo >&2 "Cloning repository $github_repository"
        clone_dir="$(mktemp -d)"
        trap 'rm -rf "$clone_dir"' EXIT
        git clone --bare "https://github.com/$github_repository" "$clone_dir"
        cd "$clone_dir"
        ;;
esac

action_version=$(git describe --tags --match "v*.*.*" "$git_ref" || git describe --tags "$git_ref" || git rev-parse HEAD)

echo "$action_version"
exit 0
