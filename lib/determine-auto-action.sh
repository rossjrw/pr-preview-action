#!/usr/bin/env bash

case $GITHUB_EVENT_NAME in
"pull_request" | "pull_request_target")
  echo >&2 "event_name is $GITHUB_EVENT_NAME; proceeding"
  ;;
*)
  echo >&2 "unknown event $GITHUB_EVENT_NAME; no action to take"
  echo "none"
  exit 0
  ;;
esac

event_type=$(jq -r ".action" "$GITHUB_EVENT_PATH")
echo >&2 "event_type is $event_type"

case $event_type in
"opened" | "reopened" | "synchronize")
  echo "deploy"
  ;;
"closed")
  echo "remove"
  ;;
*)
  echo >&2 "unknown event type $event_type; no action to take"
  echo "none"
  ;;
esac
