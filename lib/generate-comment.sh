#!/bin/bash
set -euo pipefail

# Generate comment content for PR preview deployment
# Usage: generate-comment.sh <action_repository> <action_version> <preview_url> <preview_branch> <server_url> <deploy_repository> <action_start_time> <deployment_action>

action_repository=${1:?missing action_repository}
action_version=${2:?missing action_version}
preview_url=${3:?missing preview_url}
preview_branch=${4:?missing preview_branch}
server_url=${5:?missing server_url}
deploy_repository=${6:?missing deploy_repository}
action_start_time=${7:?missing action_start_time}
deployment_action=${8:?missing deployment_action}

if [ "$deployment_action" = "deploy" ]; then
    cat << EOF
[PR Preview Action](https://github.com/${action_repository}) ${action_version}
:---:
| <p></p> :rocket: View preview at <br> ${preview_url} <br><br>
| <h6>Built to branch [\`${preview_branch}\`](${server_url}/${deploy_repository}/tree/${preview_branch}) at ${action_start_time}. <br> Preview will be ready when the [GitHub Pages deployment](${server_url}/${deploy_repository}/deployments) is complete. <br><br> </h6>
EOF

elif [ "$deployment_action" = "remove" ]; then
    cat << EOF
[PR Preview Action](https://github.com/${action_repository}) ${action_version}
:---:
Preview removed because the pull request was closed.
${action_start_time}
EOF
fi
