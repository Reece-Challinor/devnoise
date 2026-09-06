#!/usr/bin/env bash
# Generate a portable SHA-256 sidecar for a release artifact.
# SPDX-License-Identifier: MIT
set -euo pipefail

usage() {
  cat <<'USAGE'
Generate a SHA-256 sidecar for a release artifact.

Usage:
  scripts/sha256.sh [path/to/artifact]

When omitted, the newest DMG in dist/ is used. The output is written beside
the artifact as <artifact>.sha256.

Optional environment:
  DEVNOISE_DIST_DIR  Default: <repo>/dist
USAGE
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

fail() {
  echo "error: $*" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${DEVNOISE_DIST_DIR:-${REPO_ROOT}/dist}"

command -v shasum >/dev/null 2>&1 || fail "Required command not found: shasum"

ARTIFACT_PATH="${1:-}"
if [[ -z "$ARTIFACT_PATH" ]]; then
  LATEST_ARTIFACT=""
  shopt -s nullglob
  for candidate in "$DIST_DIR"/*.dmg; do
    if [[ -z "$LATEST_ARTIFACT" || "$candidate" -nt "$LATEST_ARTIFACT" ]]; then
      LATEST_ARTIFACT="$candidate"
    fi
  done
  shopt -u nullglob
  ARTIFACT_PATH="$LATEST_ARTIFACT"
fi

[[ -n "$ARTIFACT_PATH" ]] || fail "No DMG found in $DIST_DIR."
[[ -f "$ARTIFACT_PATH" ]] || fail "Artifact not found: $ARTIFACT_PATH"

ARTIFACT_NAME="$(basename "$ARTIFACT_PATH")"
SIDECAR_PATH="${ARTIFACT_PATH}.sha256"
CHECKSUM="$(shasum -a 256 "$ARTIFACT_PATH" | awk '{print $1}')"
printf '%s  %s\n' "$CHECKSUM" "$ARTIFACT_NAME" > "$SIDECAR_PATH"

echo "SHA-256 generated: $SIDECAR_PATH"
