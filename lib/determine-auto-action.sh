#!/usr/bin/env bash

if [[ $GITHUB_EVENT_NAME != "pull_request" ]]; then
  echo "unknown event $GITHUB_EVENT_NAME; no action to take"
  echo "action=none" >> "$GITHUB_ENV"
  exit 0
fi

echo "event is pull_request"

event_type=$(jq -r ".action" "$GITHUB_EVENT_PATH")
echo "event_type is $event_type"

case $event_type in
  "opened" | "reopened" | "synchronize")
    echo "action=deploy" >> "$GITHUB_ENV"
    ;;
  "closed")
    echo "action=remove" >> "$GITHUB_ENV"
    ;;
  *)
    echo "unknown event type; no action to take"
    echo "action=none" >> "$GITHUB_ENV"
    ;;
esac
