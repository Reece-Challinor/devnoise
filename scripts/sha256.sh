#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Generate SHA-256 sidecar file(s) and update dist/latest.json metadata.

Usage:
  scripts/sha256.sh [path/to/artifact]

If artifact is omitted, the latest .dmg in dist/ is used.

Optional environment:
  DEVNOISE_DIST_DIR          Default: <repo>/dist
  DEVNOISE_RELEASE_BASE_URL  If set, URL is <base>/<artifact>
  DEVNOISE_RELEASE_URL       If set, URL is used as-is (overrides base URL)
  DEVNOISE_LATEST_JSON_PATH  Default: <dist>/latest.json
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
LATEST_JSON_PATH="${DEVNOISE_LATEST_JSON_PATH:-${DIST_DIR}/latest.json}"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

require_cmd shasum
[[ -x "$PLIST_BUDDY" ]] || fail "Required tool missing: $PLIST_BUDDY"

ARTIFACT_PATH="${1:-}"
if [[ -z "$ARTIFACT_PATH" ]]; then
  ARTIFACT_PATH="$(latest_dist_artifact dmg || true)"
fi

[[ -n "$ARTIFACT_PATH" ]] || fail "No .dmg found in dist/."
[[ -f "$ARTIFACT_PATH" ]] || fail "Artifact not found: $ARTIFACT_PATH"

ARTIFACT_NAME="$(basename "$ARTIFACT_PATH")"
CHECKSUM="$(shasum -a 256 "$ARTIFACT_PATH" | awk '{print $1}')"
SIDECAR_PATH="${ARTIFACT_PATH}.sha256"
printf '%s  %s\n' "$CHECKSUM" "$ARTIFACT_NAME" > "$SIDECAR_PATH"

echo "SHA-256 generated: $SIDECAR_PATH"

APP_PATH=""
ARTIFACT_STEM="${ARTIFACT_NAME%.*}"
if [[ -d "${DIST_DIR}/${ARTIFACT_STEM}.app" ]]; then
  APP_PATH="${DIST_DIR}/${ARTIFACT_STEM}.app"
elif [[ -d "${DIST_DIR}/DevNoise.app" ]]; then
  APP_PATH="${DIST_DIR}/DevNoise.app"
else
  APP_PATH="$(latest_dist_artifact app || true)"
fi

[[ -n "$APP_PATH" ]] || fail "No matching .app found to extract version/build metadata."
[[ -d "$APP_PATH" ]] || fail "Metadata app path not found: $APP_PATH"

INFO_PLIST="${APP_PATH}/Contents/Info.plist"
[[ -f "$INFO_PLIST" ]] || fail "Missing Info.plist at: $INFO_PLIST"

VERSION="$("$PLIST_BUDDY" -c 'Print :CFBundleShortVersionString' "$INFO_PLIST" 2>/dev/null || true)"
BUILD_NUMBER="$("$PLIST_BUDDY" -c 'Print :CFBundleVersion' "$INFO_PLIST" 2>/dev/null || true)"

[[ -n "$VERSION" ]] || fail "CFBundleShortVersionString is missing from $INFO_PLIST"
[[ -n "$BUILD_NUMBER" ]] || fail "CFBundleVersion is missing from $INFO_PLIST"

if [[ -n "${DEVNOISE_RELEASE_URL:-}" ]]; then
  RELEASE_URL="$DEVNOISE_RELEASE_URL"
elif [[ -n "${DEVNOISE_RELEASE_BASE_URL:-}" ]]; then
  RELEASE_URL="${DEVNOISE_RELEASE_BASE_URL%/}/${ARTIFACT_NAME}"
else
  RELEASE_URL="$ARTIFACT_NAME"
fi

PUBLISHED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$(dirname "$LATEST_JSON_PATH")"
TMP_JSON="${LATEST_JSON_PATH}.tmp"
cat > "$TMP_JSON" <<JSON
{
  "version": "$VERSION",
  "build": "$BUILD_NUMBER",
  "url": "$RELEASE_URL",
  "checksum": "$CHECKSUM",
  "checksumType": "sha256",
  "artifact": "$ARTIFACT_NAME",
  "publishedAt": "$PUBLISHED_AT"
}
JSON
mv "$TMP_JSON" "$LATEST_JSON_PATH"

echo "Metadata updated: $LATEST_JSON_PATH"
