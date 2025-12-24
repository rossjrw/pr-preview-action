#!/usr/bin/env bash

# Determine deployment action based on GitHub event
# Usage: determine_auto_action "$GITHUB_EVENT_NAME" "$GITHUB_EVENT_PATH"
# Returns: "deploy", "remove", or "none"
determine_auto_action() {
    local event_name="${1:-$GITHUB_EVENT_NAME}"
    local event_path="${2:-$GITHUB_EVENT_PATH}"

    case $event_name in
        "pull_request" | "pull_request_target")
            echo >&2 "event_name is $event_name; proceeding"
            ;;
        *)
            echo >&2 "unknown event $event_name; no action to take"
            echo "none"
            return 0
            ;;
    esac

    local event_type
    event_type=$(jq -r ".action" "$event_path")
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
}
