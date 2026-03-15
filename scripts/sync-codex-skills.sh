#!/usr/bin/env bash

SKILLS=(
  "tinypng"
)

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SOURCE_ROOT="${HOME}/.codex/skills"
TARGET_ROOT="${REPO_ROOT}/skills"

if [[ ! -d "${SOURCE_ROOT}" ]]; then
  echo "Source skills directory not found: ${SOURCE_ROOT}" >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required but not installed." >&2
  exit 1
fi

mkdir -p "${TARGET_ROOT}"

for skill in "${SKILLS[@]}"; do
  source_dir="${SOURCE_ROOT}/${skill}"
  target_dir="${TARGET_ROOT}/${skill}"

  if [[ ! -d "${source_dir}" ]]; then
    echo "Source skill directory not found: ${source_dir}" >&2
    exit 1
  fi

  mkdir -p "${target_dir}"

  echo "Syncing skill: ${skill}"
  echo "source: ${source_dir}"
  echo "target: ${target_dir}"

  rsync -a --delete "${source_dir}/" "${target_dir}/"
done

echo "Sync complete."
