#!/usr/bin/env bash
# Staple and validate Apple's notarization tickets.
# SPDX-License-Identifier: MIT
set -euo pipefail

usage() {
  cat <<'USAGE'
Staple notarization ticket to artifacts and validate.

Usage:
  scripts/staple.sh [artifact ...]

If no artifacts are provided, this script staples any app/dmg found in dist/.

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

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || fail "Required command not found: $cmd"
}

latest_dist_artifact() {
  local ext="$1"
  local latest=""
  local candidate

  shopt -s nullglob
  for candidate in "$DIST_DIR"/*."$ext"; do
    [[ -e "$candidate" ]] || continue
    if [[ -z "$latest" || "$candidate" -nt "$latest" ]]; then
      latest="$candidate"
    fi
  done
  shopt -u nullglob

  [[ -n "$latest" ]] || return 1
  printf '%s\n' "$latest"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${DEVNOISE_DIST_DIR:-${REPO_ROOT}/dist}"

require_cmd xcrun

ARTIFACTS=()
if [[ $# -gt 0 ]]; then
  ARTIFACTS=("$@")
else
  if [[ -f "${DIST_DIR}/DevNoise.dmg" ]]; then
    ARTIFACTS+=("${DIST_DIR}/DevNoise.dmg")
  else
    LATEST_DMG="$(latest_dist_artifact dmg || true)"
    [[ -n "$LATEST_DMG" ]] && ARTIFACTS+=("$LATEST_DMG")
  fi

  if [[ -d "${DIST_DIR}/DevNoise.app" ]]; then
    ARTIFACTS+=("${DIST_DIR}/DevNoise.app")
  else
    LATEST_APP="$(latest_dist_artifact app || true)"
    [[ -n "$LATEST_APP" ]] && ARTIFACTS+=("$LATEST_APP")
  fi
fi

[[ ${#ARTIFACTS[@]} -gt 0 ]] || fail "No artifacts found to staple."

for ARTIFACT in "${ARTIFACTS[@]}"; do
  [[ -e "$ARTIFACT" ]] || fail "Artifact not found: $ARTIFACT"
  echo "Stapling: $ARTIFACT"
  xcrun stapler staple "$ARTIFACT"
  xcrun stapler validate "$ARTIFACT"
done

echo "Stapling complete."
