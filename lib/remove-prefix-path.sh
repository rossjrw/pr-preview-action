#!/usr/bin/env bash

set -e

help() {
  echo ""
  echo "Removes a base path from the start of another path."
  echo "Usage: $0 -b base_path -o original_path"
  echo -e "\t-b Base path to remove"
  echo -e "\t-o Path to remove base path from; must start with base path"
  exit 1
} >&2

while getopts "b:o:" opt; do
  case "$opt" in
  b) base_path="$OPTARG" ;;
  o) original_path="$OPTARG" ;;
  ?) help ;;
  esac
done

# Remove leading dotslash, leading/trailing slash; collapse multiple slashes
normalise_path() {
  echo "$1" | sed -e 's|^\./||g' -e 's|^/||g' -e 's|/*$||g' -e 's|//*|/|g'
}

base_path=$(normalise_path "$base_path")
original_path=$(normalise_path "$original_path")

echo "${original_path#"$base_path"/}"
exit 0
