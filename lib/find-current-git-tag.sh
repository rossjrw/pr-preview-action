#!/usr/bin/env bash

helpFunction() {
  echo ""
  echo "Usage: $0 -p github_repository -f git_ref"
  echo -e "\t-p GitHub repository to clone, format: owner/repo"
  echo -e "\t-f Reference of repository to clone"
  exit 1
}

while getopts "p:f:" opt; do
  case "$opt" in
    p) github_repository="$OPTARG" ;;
    f) git_ref="$OPTARG" ;;
    ?) helpFunction ;;
  esac
done

if [ -z "$github_repository" ] || [ -z "$git_ref" ]; then
  echo "some parameters are empty"
  helpFunction
fi

echo "Cloning repository $github_repository at ref $git_ref"
git clone --bare --single-branch --branch "$git_ref" "https://github.com/$github_repository" bare_pr_preview

cd bare_pr_preview || exit 1

action_version=$(git describe --tags --match "v*.*.*" \
  || git describe --tags \
  || git rev-parse HEAD)

echo "action_version=$action_version" >> "$GITHUB_ENV"
