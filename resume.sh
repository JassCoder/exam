#!/usr/bin/env bash
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
exec bash "$repo_dir/exam.sh" "$@"
