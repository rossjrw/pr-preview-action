#!/usr/bin/env bash

helpFunction() {
  echo ""
  echo "Usage: $0 -n event_name -a action"
  echo -e "\t-e The name of the event that started this deployment"
  echo -e "\t-a The sub-action of the event"
  exit 1
} >&2

while getopts "n:a:" opt; do
  case "$opt" in
    n) event_name="$OPTARG" ;;
    a) event_action="$OPTARG" ;;
    ?) helpFunction ;;
  esac
done

if [ -z "$event_name" ] || [ -z "$event_action" ]; then
  echo "some parameters are empty" >&2
  helpFunction
fi

case $event_name in
  "pull_request")
    warnmsg=(
      "Automatic action determination is deprecated. Set the action to"
      "deploy or remove explicitly instead."
    )
    echo "::warning::${warnmsg[*]}" >&2
    ;;
  "pull_request_target" | "workflow_run")
    errmsg=(
      "Automatic action determination is not supported for the"
      "$event_name event for security reasons."
      "To automatically determine the action for internal pull requests,"
      "use the pull_request event."
      "For previews for pull requests from forks, see"
      "https://github.com/rossjrw/pr-preview-action/tree/main/examples/deploy-previews-for-forks"
    )
    echo "::error::${errmsg[*]}" >&2
    exit 1
    ;;
  *)
    errmsg=(
      "Automatic action determination is not supported for the"
      "$event_name event. It is only supported for pull_request."
      "For previews for pull requests from forks, see"
      "https://github.com/rossjrw/pr-preview-action/tree/main/examples/deploy-previews-for-forks."
      "For all other use cases, set the action to deploy or remove explicitly."
      "For more details, see"
      "https://github.com/rossjrw/pr-preview-action/tree/main/examples/basic_usage"
    )
    echo "::error::${errmsg[*]}" >&2
    exit 1
    ;;
esac

case $event_action in
  "opened" | "reopened" | "synchronize") echo "deploy" ;;
  "closed") echo "remove" ;;
  *)
    echo "::warning::unknown event type $event_action; no action to take" >&2
    echo "none"
    ;;
esac
exit 0
