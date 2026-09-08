#!/usr/bin/env bash
# Verify release artifacts against macOS Gatekeeper requirements.
# SPDX-License-Identifier: MIT
set -euo pipefail

usage() {
  cat <<'USAGE'
Verify Gatekeeper assessment and notarization stapling.

Usage:
  scripts/verify_gatekeeper.sh [artifact ...]

If no artifacts are provided, this script checks app/dmg in dist/.

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

require_cmd spctl
require_cmd codesign
if command -v xcrun >/dev/null 2>&1; then
  HAS_XCRUN=1
else
  HAS_XCRUN=0
fi

ARTIFACTS=()
if [[ $# -gt 0 ]]; then
  ARTIFACTS=("$@")
else
  if [[ -d "${DIST_DIR}/DevNoise.app" ]]; then
    ARTIFACTS+=("${DIST_DIR}/DevNoise.app")
  else
    LATEST_APP="$(latest_dist_artifact app || true)"
    [[ -n "$LATEST_APP" ]] && ARTIFACTS+=("$LATEST_APP")
  fi

  if [[ -f "${DIST_DIR}/DevNoise.dmg" ]]; then
    ARTIFACTS+=("${DIST_DIR}/DevNoise.dmg")
  else
    LATEST_DMG="$(latest_dist_artifact dmg || true)"
    [[ -n "$LATEST_DMG" ]] && ARTIFACTS+=("$LATEST_DMG")
  fi
fi

[[ ${#ARTIFACTS[@]} -gt 0 ]] || fail "No artifacts found to verify."

for ARTIFACT in "${ARTIFACTS[@]}"; do
  [[ -e "$ARTIFACT" ]] || fail "Artifact not found: $ARTIFACT"

  case "$ARTIFACT" in
    *.app)
      echo "Gatekeeper assess (app): $ARTIFACT"
      spctl --assess --type execute --verbose=4 "$ARTIFACT"

      echo "Code signature verify (app): $ARTIFACT"
      codesign --verify --deep --strict --verbose=2 "$ARTIFACT"

      if [[ "$HAS_XCRUN" -eq 1 ]]; then
        echo "Stapler validate (app): $ARTIFACT"
        xcrun stapler validate "$ARTIFACT"
      fi
      ;;
    *.dmg)
      echo "Gatekeeper assess (dmg): $ARTIFACT"
      spctl --assess \
        --type open \
        --context context:primary-signature \
        --verbose=4 \
        "$ARTIFACT"

      if codesign --verify --verbose=2 "$ARTIFACT" >/dev/null 2>&1; then
        echo "Code signature verify (dmg): $ARTIFACT"
        codesign --verify --verbose=2 "$ARTIFACT"
      else
        echo "Info: DMG is not independently signed; proceeding with Gatekeeper + stapler checks."
      fi

      if [[ "$HAS_XCRUN" -eq 1 ]]; then
        echo "Stapler validate (dmg): $ARTIFACT"
        xcrun stapler validate "$ARTIFACT"
      fi
      ;;
    *)
      fail "Unsupported artifact type: $ARTIFACT (expected .app or .dmg)"
      ;;
  esac
done

echo "Gatekeeper verification complete."
