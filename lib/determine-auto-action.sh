#!/usr/bin/env bash

if [[ $GITHUB_EVENT_NAME != pull_request ]]; then
  echo "unknown event $GITHUB_EVENT_NAME; no action to take"
  echo "action=none" >> "$GITHUB_ENV"
  exit 0
fi

echo "event is pull_request"

event_type=$(jq -r ".action" "$GITHUB_EVENT_PATH")

if [[ $event_type == synchronized ]]; then
  echo "synchronized event; deploying"
  echo "action=deploy" >> "$GITHUB_ENV"
  exit 0
fi

if [[ $event_type == closed ]]; then
  echo "closed event; removing"
  echo "action=remove" >> "$GITHUB_ENV"
  exit 0
fi

echo "unknown event type $event_type; no action to take"
echo "action=none" >> "$GITHUB_ENV"
exit 0
