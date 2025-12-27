#!/usr/bin/env bash

# Finds, tracks, and awaits the Pages build associated with the given commit SHA

set -e

find_build_id_for_sha() {
    local builds_json="$1"
    local target_sha="$2"
    echo "$builds_json" | jq -r --arg sha "$target_sha" \
        '.[] | select(.commit == $sha) | .url | split("/")[-1]'
}

extract_status_from_response() {
    echo "$1" | jq -r '.status // empty'
}

wait_for_pages_deployment() {
    local REPO="${1:?missing arg 1: REPO}"
    local TARGET_SHA="${2:?missing arg 2: TARGET_SHA}"
    local BRANCH="${3:?missing arg 3: BRANCH}"
    local TOKEN="${4:?missing arg 4: TOKEN}"

    local PAGES_BUILD_STARTED_TIMEOUT=180
    local PAGES_BUILD_FINISHED_TIMEOUT=180

    if [ ${#TARGET_SHA} -ne 40 ]; then
        echo "Error: Expected 40-character SHA, got ${#TARGET_SHA} characters: $TARGET_SHA"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "jq is required"
        exit 1
    fi

    echo >&2 "Waiting for GitHub Pages deployment to complete"
    echo >&2 "Finding Pages build in repo $REPO for commit $TARGET_SHA..."

    local elapsed=0
    local build_id=""

    local clone_dir
    clone_dir="$(mktemp -d)"
    trap 'rm -rf "$clone_dir"' EXIT

    while [ -z "$build_id" ]; do
        local builds_response
        builds_response=$(
            curl -s \
                -H "Authorization: Bearer $TOKEN" \
                -H "Accept: application/vnd.github+json" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                "https://api.github.com/repos/$REPO/pages/builds?per_page=100"
        )

        # Get the build ID for this commit SHA if present
        build_id=$(find_build_id_for_sha "$builds_response" "$TARGET_SHA")
        if [ -n "$build_id" ] && [ "$build_id" != "null" ]; then
            echo "Found build #$build_id for commit $TARGET_SHA"
            break
        fi

        # Fall back to descendant check if that doesn't immediately work (this commit might have been skipped in favour of a newer one)
        if [ $elapsed -ge 30 ]; then
            echo >&2 "Exact commit build not found after ${elapsed}s"

            if [ ! -d "$clone_dir/.git" ]; then
                echo >&2 "Cloning repository to check for descendant commits..."
                git clone --depth=50 --single-branch --branch="$BRANCH" "https://oauth2:${TOKEN}@github.com/${REPO}.git" "$clone_dir"
                pushd "$clone_dir" > /dev/null
                trap 'popd > /dev/null' RETURN
            else
                echo >&2 "Refreshing clone..."
                git pull
            fi

            # Verify our target commit exists in this branch
            if ! git cat-file -e "${TARGET_SHA}^{commit}" 2> /dev/null; then
                echo >&2 "Error: Repo $REPO on branch $BRANCH does not contain commit $TARGET_SHA"
                return 1
            fi

            # Get the latest commit on this branch
            local latest_sha
            latest_sha=$(git rev-parse HEAD)

            # Check if our target commit is an ancestor of the latest commit
            if ! git merge-base --is-ancestor "$TARGET_SHA" "$latest_sha" 2> /dev/null; then
                echo >&2 "Error: Target commit $TARGET_SHA is not an ancestor of latest commit $latest_sha ($BRANCH has non-linear history)"
                return 1
            fi

            # Look for any build in the response that's a descendant of our target commit
            while IFS= read -r build_commit; do
                if [ -z "$build_commit" ] || [ "$build_commit" = "null" ]; then
                    continue
                fi

                # Check if our target is an ancestor of this build's commit
                if git merge-base --is-ancestor "$TARGET_SHA" "$build_commit" 2> /dev/null; then
                    build_id=$(find_build_id_for_sha "$builds_response" "$build_commit")
                    if [ -n "$build_id" ] && [ "$build_id" != "null" ]; then
                        echo >&2 "Found build #$build_id for commit $build_commit (descendant of $TARGET_SHA)"
                        break 2
                    fi
                fi
            done < <(echo "$builds_response" | jq -r '.[].commit')
        fi

        if [ $elapsed -ge $PAGES_BUILD_STARTED_TIMEOUT ]; then
            echo >&2 "Timed out ($PAGES_BUILD_STARTED_TIMEOUT) waiting for build to start"
            exit 1
        fi

        echo >&2 "No build found - waiting..."
        sleep 10
        elapsed=$((elapsed + 10))
    done

    echo >&2 "Tracking build #$build_id to completion..."
    elapsed=0

    while true; do
        build_response=$(curl -s \
            -H "Authorization: Bearer $TOKEN" \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com/repos/$REPO/pages/builds/$build_id")

        build_status=$(extract_status_from_response "$build_response")

        if [ "$build_status" = "built" ]; then
            echo >&2 "Build status: $build_status"
            exit 0
        elif [ "$build_status" = "errored" ]; then
            echo >&2 "Build status: $build_status"
            exit 1
        fi

        if [ $elapsed -ge $PAGES_BUILD_FINISHED_TIMEOUT ]; then
            echo >&2 "Build status: $build_status"
            echo >&2 "Timed out ($PAGES_BUILD_FINISHED_TIMEOUT) waiting for build to complete"
            exit 1
        fi

        echo >&2 "Build status: $build_status - waiting..."

        sleep 10
        elapsed=$((elapsed + 10))
    done
}

# TODO: What if the deployment was skipped because e.g. there were no changes to deploy? That should return success
# TODO: What if a commit is pushed after finding the build but before it completes? Does that cancel the build we're tracking?
# TODO: Test that the descendant commit logic works as intended (probably by pushing 2 commits to the deployment branch manually and then checking the earlier one can find the later one)
