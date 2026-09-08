#!/usr/bin/env bash
# Submit a DevNoise artifact to Apple's notarization service.
# SPDX-License-Identifier: MIT
set -euo pipefail

usage() {
  cat <<'USAGE'
Submit an artifact for notarization and report progress until completion.

Usage:
  scripts/notarize.sh [path/to/artifact]

Artifact selection when omitted:
  1) Latest .dmg in dist/
  2) Latest .app in dist/ (zipped before submission)

Required environment:
  DEVNOISE_NOTARY_KEYCHAIN_PROFILE  Stored notarytool credential profile

Optional environment:
  DEVNOISE_NOTARY_KEYCHAIN  Keychain containing the stored profile

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

[[ -n "${DEVNOISE_NOTARY_KEYCHAIN_PROFILE:-}" ]] || \
  fail "DEVNOISE_NOTARY_KEYCHAIN_PROFILE is required."

NOTARY_AUTH_ARGS=(--keychain-profile "$DEVNOISE_NOTARY_KEYCHAIN_PROFILE")
if [[ -n "${DEVNOISE_NOTARY_KEYCHAIN:-}" ]]; then
  NOTARY_AUTH_ARGS+=(--keychain "$DEVNOISE_NOTARY_KEYCHAIN")
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
if ! SUBMIT_OUTPUT="$(xcrun notarytool submit "$SUBMIT_PATH" "${NOTARY_AUTH_ARGS[@]}" --output-format json 2>&1)"; then
  printf '%s\n' "$SUBMIT_OUTPUT" > "$LOG_PATH"
  fail "Notarization command failed. See log: $LOG_PATH"
fi

printf '%s\n' "$SUBMIT_OUTPUT" > "$LOG_PATH"

SUBMISSION_ID="$(printf '%s\n' "$SUBMIT_OUTPUT" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
[[ -n "$SUBMISSION_ID" ]] || fail "Unable to parse Apple's submission ID. See log: $LOG_PATH"

echo "Upload complete."
echo "- Apple submission ID: $SUBMISSION_ID"
echo "- Apple may take several hours; checking once per minute."

while true; do
  if ! NOTARY_OUTPUT="$(xcrun notarytool info "$SUBMISSION_ID" "${NOTARY_AUTH_ARGS[@]}" --output-format json 2>&1)"; then
    printf '%s\n' "$NOTARY_OUTPUT" > "$LOG_PATH"
    fail "Unable to check notarization status for $SUBMISSION_ID. See log: $LOG_PATH"
  fi

  printf '%s\n' "$NOTARY_OUTPUT" > "$LOG_PATH"
  STATUS="$(printf '%s\n' "$NOTARY_OUTPUT" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  [[ -n "$STATUS" ]] || fail "Unable to parse notarization status. See log: $LOG_PATH"

  echo "Apple notarization status: $STATUS (submission: $SUBMISSION_ID)"

  case "$STATUS" in
    Accepted)
      break
      ;;
    "In Progress")
      sleep 60
      ;;
    Invalid|Rejected)
      xcrun notarytool log "$SUBMISSION_ID" "${NOTARY_AUTH_ARGS[@]}" > "$LOG_PATH" 2>&1 || true
      fail "Notarization status is '$STATUS'. See log: $LOG_PATH"
      ;;
    *)
      fail "Unexpected notarization status '$STATUS'. See log: $LOG_PATH"
      ;;
  esac
done

echo "Notarization accepted."
echo "- Submission ID: $SUBMISSION_ID"
echo "- Log: $LOG_PATH"
