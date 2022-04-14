#!/usr/bin/env bash

case $GITHUB_EVENT_NAME in
  "pull_request" | "pull_request_target")
    echo "event_type is $GITHUB_EVENT_NAME; proceeding" >&2
    ;;
  *)
    echo "::warning::unknown event $GITHUB_EVENT_NAME; no action to take" >&2
    echo "none"
    exit 0
    ;;
esac

event_type=$(jq -r ".action" "$GITHUB_EVENT_PATH")
echo "event_type is $event_type" >&2

case $event_type in
  "opened" | "reopened" | "synchronize")
    echo "deploy"
    ;;
  "closed")
    echo "remove"
    ;;
  *)
    echo "::warning::unknown event type $event_type; no action to take" >&2
    echo "none"
    ;;
esac
exit 0
