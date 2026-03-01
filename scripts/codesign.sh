#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Sign a built app with Developer ID + hardened runtime.

Usage:
  scripts/codesign.sh [path/to/DevNoise.app]

Required environment:
  DEVNOISE_SIGN_IDENTITY   e.g. "Developer ID Application: Example, Inc. (TEAMID)"

Optional environment:
  DEVNOISE_DIST_DIR        Default: <repo>/dist
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

require_cmd codesign

[[ -n "${DEVNOISE_SIGN_IDENTITY:-}" ]] || fail "DEVNOISE_SIGN_IDENTITY is required."

APP_PATH="${1:-}"
if [[ -z "$APP_PATH" ]]; then
  if [[ -d "${DIST_DIR}/DevNoise.app" ]]; then
    APP_PATH="${DIST_DIR}/DevNoise.app"
  else
    APP_PATH="$(latest_dist_artifact app || true)"
  fi
fi

[[ -n "$APP_PATH" ]] || fail "No .app found. Run scripts/build_release.sh first."
[[ -d "$APP_PATH" ]] || fail "App not found at: $APP_PATH"

echo "Signing app: $APP_PATH"
codesign \
  --force \
  --deep \
  --options runtime \
  --timestamp \
  --sign "$DEVNOISE_SIGN_IDENTITY" \
  "$APP_PATH"

echo "Verifying app signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Code signing complete: $APP_PATH"
