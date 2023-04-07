#!/usr/bin/env bash

helpFunction() {
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
    ?) helpFunction ;;
  esac
done

if [ -z "$github_repository" ] || [ -z "$git_ref" ]; then
  echo >&2 "some parameters are empty"
  helpFunction
fi

echo >&2 "Determining preview action version"
echo >&2 "Cloning repository $github_repository at ref $git_ref"
if git clone --bare --single-branch --branch "$git_ref" "https://github.com/$github_repository" bare_pr_preview; then
  echo >&2 "Finding most specific tag matching tag $git_ref"
  action_version=$(git describe --tags --match "v*.*.*" || git describe --tags || git rev-parse HEAD)
  echo >&2 "Found $action_version"
  echo "action_version=$action_version" >>"$GITHUB_ENV"
else
  echo >&2 "Clone failed; using truncated ref as action version"
  echo "action_version=${git_ref:0:9}" >>"$GITHUB_ENV"
fi
