#!/usr/bin/env bash

SKILLS=(
  "fable"
  "max"
  "name"
  "sub"
  "tinypng"
  "turn"
)

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TARGET_ROOT="${REPO_ROOT}/skills"

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required but not installed." >&2
  exit 1
fi

mkdir -p "${TARGET_ROOT}"

for skill in "${SKILLS[@]}"; do
  source_dir="${HOME}/.agents/skills/${skill}"
  if [[ ! -d "${source_dir}" ]]; then
    source_dir="${HOME}/.codex/skills/${skill}"
  fi
  target_dir="${TARGET_ROOT}/${skill}"

  if [[ ! -d "${source_dir}" ]]; then
    if [[ -d "${target_dir}" ]]; then
      echo "Skipping skill without a global source: ${skill}"
      continue
    fi
    echo "Source skill directory not found for: ${skill}" >&2
    exit 1
  fi

  mkdir -p "${target_dir}"

  echo "Syncing skill: ${skill}"
  echo "source: ${source_dir}"
  echo "target: ${target_dir}"

  rsync -a --delete "${source_dir}/" "${target_dir}/"
done

echo "Sync complete."
