#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Submit an artifact for notarization and wait for completion.

Usage:
  scripts/notarize.sh [path/to/artifact]

Artifact selection when omitted:
  1) Latest .dmg in dist/
  2) Latest .app in dist/ (zipped before submission)

Auth options (choose one):
  A) DEVNOISE_NOTARY_KEYCHAIN_PROFILE (recommended)
     Optional: DEVNOISE_NOTARY_KEYCHAIN
  B) DEVNOISE_NOTARY_APPLE_ID + DEVNOISE_NOTARY_TEAM_ID + DEVNOISE_NOTARY_APP_PASSWORD

Optional environment:
  DEVNOISE_DIST_DIR        Default: <repo>/dist
  DEVNOISE_NOTARY_LOG_DIR  Default: <dist>/notary-logs
  DEVNOISE_NOTARY_LOG_PATH Default: <notary-log-dir>/<artifact>.notary.json
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
NOTARY_LOG_DIR="${DEVNOISE_NOTARY_LOG_DIR:-${DIST_DIR}/notary-logs}"

require_cmd xcrun
require_cmd ditto

mkdir -p "$DIST_DIR" "$NOTARY_LOG_DIR"

ARTIFACT_PATH="${1:-}"
if [[ -z "$ARTIFACT_PATH" ]]; then
  ARTIFACT_PATH="$(latest_dist_artifact dmg || true)"
fi
if [[ -z "$ARTIFACT_PATH" ]]; then
  ARTIFACT_PATH="$(latest_dist_artifact app || true)"
fi

[[ -n "$ARTIFACT_PATH" ]] || fail "No notarization target found. Build/sign and create a DMG first."
[[ -e "$ARTIFACT_PATH" ]] || fail "Artifact not found at: $ARTIFACT_PATH"

NOTARY_AUTH_ARGS=()
if [[ -n "${DEVNOISE_NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  NOTARY_AUTH_ARGS=(--keychain-profile "$DEVNOISE_NOTARY_KEYCHAIN_PROFILE")
  if [[ -n "${DEVNOISE_NOTARY_KEYCHAIN:-}" ]]; then
    NOTARY_AUTH_ARGS+=(--keychain "$DEVNOISE_NOTARY_KEYCHAIN")
  fi
else
  [[ -n "${DEVNOISE_NOTARY_APPLE_ID:-}" ]] || fail "Set DEVNOISE_NOTARY_KEYCHAIN_PROFILE or DEVNOISE_NOTARY_APPLE_ID."
  [[ -n "${DEVNOISE_NOTARY_TEAM_ID:-}" ]] || fail "DEVNOISE_NOTARY_TEAM_ID is required when using Apple ID auth."
  [[ -n "${DEVNOISE_NOTARY_APP_PASSWORD:-}" ]] || fail "DEVNOISE_NOTARY_APP_PASSWORD is required when using Apple ID auth."
  NOTARY_AUTH_ARGS=(
    --apple-id "$DEVNOISE_NOTARY_APPLE_ID"
    --team-id "$DEVNOISE_NOTARY_TEAM_ID"
    --password "$DEVNOISE_NOTARY_APP_PASSWORD"
  )
fi

SUBMIT_PATH="$ARTIFACT_PATH"
if [[ "$ARTIFACT_PATH" == *.app ]]; then
  SUBMIT_PATH="${DIST_DIR}/$(basename "${ARTIFACT_PATH%.app}").zip"
  rm -f "$SUBMIT_PATH"
  ditto -c -k --keepParent "$ARTIFACT_PATH" "$SUBMIT_PATH"
  echo "Prepared app zip for notarization: $SUBMIT_PATH"
fi

ARTIFACT_NAME="$(basename "$ARTIFACT_PATH")"
SAFE_ARTIFACT_NAME="${ARTIFACT_NAME// /_}"
LOG_PATH="${DEVNOISE_NOTARY_LOG_PATH:-${NOTARY_LOG_DIR}/${SAFE_ARTIFACT_NAME}.notary.json}"

echo "Submitting for notarization: $SUBMIT_PATH"
if ! NOTARY_OUTPUT="$(xcrun notarytool submit "$SUBMIT_PATH" "${NOTARY_AUTH_ARGS[@]}" --wait --output-format json 2>&1)"; then
  printf '%s\n' "$NOTARY_OUTPUT" > "$LOG_PATH"
  fail "Notarization command failed. See log: $LOG_PATH"
fi

printf '%s\n' "$NOTARY_OUTPUT" > "$LOG_PATH"

STATUS="$(printf '%s\n' "$NOTARY_OUTPUT" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
SUBMISSION_ID="$(printf '%s\n' "$NOTARY_OUTPUT" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"

[[ -n "$STATUS" ]] || fail "Unable to parse notarization response. See log: $LOG_PATH"

if [[ "$STATUS" != "Accepted" ]]; then
  fail "Notarization status is '$STATUS'. See log: $LOG_PATH"
fi

echo "Notarization accepted."
echo "- Submission ID: ${SUBMISSION_ID:-unknown}"
echo "- Log: $LOG_PATH"
