#!/usr/bin/env bash

declare deployment_action pr_number deployment_repository pages_base_url pages_base_path umbrella_path github_action_ref github_action_repository deprecated_custom_url

# Deprecation of custom-url in favour of pages-base-url
if [ -z "$pages_base_url" ] && [ -n "$deprecated_custom_url" ]; then
  pages_base_url=$deprecated_custom_url
fi

# If pages_base_url was not set by the user, try to guess
if [ -z "$pages_base_url" ]; then
  # Either .github.io or .github.io/repo
  repo_org=$(echo "$deployment_repository" | cut -d "/" -f 1)
  repo_name=$(echo "$deployment_repository" | cut -d "/" -f 2)
  if [ "$repo_name" = "${repo_org}.github.io" ]; then
    pages_base_url="${repo_org}.github.io"
  else
    pages_base_url=$(echo "$deployment_repository" | sed -e 's/\//.github.io\//')
  fi
fi

preview_file_path="$umbrella_path/pr-$pr_number"

preview_url_path=$("$GITHUB_ACTION_PATH/lib/remove-prefix-path.sh" -b "$pages_base_path" -o "$preview_file_path")
if [ -n "$pages_base_path" ] && [ "$("$GITHUB_ACTION_PATH/lib/remove-prefix-path.sh" -b "" -o "$preview_file_path")" = "$preview_url_path" ]; then
  echo "::warning title=pages-base-path doesn't match::The pages-base-path directory ($pages_base_path) does not contain umbrella-dir ($umbrella_path). pages-base-path has been ignored. The value of umbrella-dir should start with the value of pages-base-path."
  preview_url_path=$preview_file_path
fi

if [ "$deployment_action" = "auto" ]; then
  echo >&2 "Determining auto action"
  deployment_action=$("$GITHUB_ACTION_PATH/lib/determine-auto-action.sh")
  echo >&2 "Auto action is $deployment_action"
fi

action_version=$("$GITHUB_ACTION_PATH/lib/find-current-git-tag.sh" -p "$github_action_repository" -f "$github_action_ref")
action_start_timestamp=$(date '+%s')
action_start_time=$(date '+%Y-%m-%d %H:%M %Z')

# Export variables for later use by this action
{
  echo "empty_dir_path=$(mktemp -d)"
  echo "deployment_action=$deployment_action"

  echo "preview_file_path=$preview_file_path"
  echo "pages_base_url=$pages_base_url"
  echo "preview_url_path=$preview_url_path"
  echo "preview_url=https://$pages_base_url/$preview_url_path/"

  echo "action_repository=$github_action_repository"
  echo "action_version=$action_version"
  echo "action_start_time=$action_start_time"
} >>"$GITHUB_ENV"

# Export variables for use by later actions in user workflow
{
  echo "deployment_action=$deployment_action"

  echo "pages_base_url=$pages_base_url"
  echo "preview_url_path=$preview_url_path"
  echo "preview_url=https://$pages_base_url/$preview_url_path/"

  echo "action_version=$action_version"
  echo "action_start_timestamp=$action_start_timestamp"
  echo "action_start_time=$action_start_time"
} >>"$GITHUB_OUTPUT"
