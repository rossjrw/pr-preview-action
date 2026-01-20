#!/usr/bin/env bash
# shellcheck source-path=..

source "$GITHUB_ACTION_PATH/lib/calculate-pages-base-url.sh"
source "$GITHUB_ACTION_PATH/lib/remove-prefix-path.sh"
source "$GITHUB_ACTION_PATH/lib/determine-auto-action.sh"

declare deployment_action pr_number deployment_repository pages_base_url pages_base_path umbrella_path action_repository action_ref deprecated_custom_url

# Deprecation of custom-url in favour of pages-base-url
if [ -z "$pages_base_url" ] && [ -n "$deprecated_custom_url" ]; then
    pages_base_url=$deprecated_custom_url
fi

# If pages_base_url was not set by the user, try to guess
if [ -z "$pages_base_url" ]; then
    pages_base_url=$(calculate_pages_base_url "$deployment_repository")
fi

preview_file_path="$umbrella_path/pr-$pr_number"

preview_url_path=$(remove_prefix_path "$pages_base_path" "$preview_file_path")
if [ -n "$pages_base_path" ] && [ "$(remove_prefix_path "" "$preview_file_path")" = "$preview_url_path" ]; then
    echo "::warning title=pages-base-path doesn't match::The pages-base-path directory ($pages_base_path) does not contain umbrella-dir ($umbrella_path). pages-base-path has been ignored. The value of umbrella-dir should start with the value of pages-base-path."
    preview_url_path=$preview_file_path
fi

if [ "$deployment_action" = "auto" ]; then
    echo >&2 "Determining auto action"
    deployment_action=$(determine_auto_action "$GITHUB_EVENT_NAME" "$GITHUB_EVENT_PATH")
    echo >&2 "Auto action is $deployment_action"
fi

action_version=$("$GITHUB_ACTION_PATH/lib/find-current-git-tag.sh" -p "$action_repository" -f "$action_ref")
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

    echo "action_repository=$action_repository"
    echo "action_version=$action_version"
    echo "action_start_time=$action_start_time"
} >> "$GITHUB_ENV"

# Export variables for use by later actions in user workflow
{
    echo "deployment_action=$deployment_action"

    echo "pages_base_url=$pages_base_url"
    echo "preview_url_path=$preview_url_path"
    echo "preview_url=https://$pages_base_url/$preview_url_path/"

    echo "action_version=$action_version"
    echo "action_start_timestamp=$action_start_timestamp"
    echo "action_start_time=$action_start_time"
} >> "$GITHUB_OUTPUT"
