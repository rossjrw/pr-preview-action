#!/usr/bin/env bash

declare action pr deployrepo customurl pagesbase umbrella actionref actionrepo token

repo_org=$(echo "$deployrepo" | cut -d "/" -f 1)
repo_name=$(echo "$deployrepo" | cut -d "/" -f 2)

if [ -n "$customurl" ]; then
  pagesurl="$customurl"
elif [ "${repo_org}.github.io" == "$repo_name" ]; then
  pagesurl="${repo_org}.github.io"
else
  pagesurl=$(echo "$deployrepo" | sed 's/\//.github.io\//')
fi

targetdir="$umbrella/pr-$pr"

pagespath=$("$GITHUB_ACTION_PATH/lib/remove-prefix-path.sh" -b "$pagesbase" -o "$targetdir")
if [ -n "$pagesbase" ] && [ "$("$GITHUB_ACTION_PATH/lib/remove-prefix-path.sh" -b "" -o "$targetdir")" = "$pagespath" ]; then
  echo "::warning title=pages-base-path doesn't match::pages-base-path directory ($pagesbase) does not contain umbrella-dir ($umbrella). pages-base-path has been ignored."
  pagespath=$targetdir
fi

if [ "$action" = "auto" ]; then
  echo >&2 "Determining auto action"
  action=$("$GITHUB_ACTION_PATH/lib/determine-auto-action.sh")
  echo >&2 "Auto action is $action"
fi

# Export variables for later use by this action
{
  echo "emptydir=$(mktemp -d)"
  echo "datetime=$(date '+%Y-%m-%d %H:%M %Z')"

  echo "action=$action"
  echo "pr=$pr"

  echo "targetdir=$targetdir"
  echo "pagesurl=$pagesurl"
  echo "pagespath=$pagespath"

  echo "actionref=$actionref"
  echo "actionrepo=$actionrepo"
  echo "action_version=$("$GITHUB_ACTION_PATH/lib/find-current-git-tag.sh" -p "$actionrepo" -f "$actionref")"

  echo "deployrepo=$deployrepo"
  echo "token=$token"
} >>"$GITHUB_ENV"
