#!/usr/bin/env bash
# Package DevNoise.app in a drag-to-Applications DMG.
# SPDX-License-Identifier: MIT
set -euo pipefail

usage() {
  cat <<'USAGE'
Build a distributable DMG containing DevNoise.app and an Applications symlink.

Usage:
  scripts/dmg_build.sh [path/to/DevNoise.app]

Optional environment:
  DEVNOISE_DIST_DIR         Default: <repo>/dist
  DEVNOISE_DMG_VOLUME_NAME  Default: DevNoise
  DEVNOISE_SIGN_IDENTITY    If set, DMG will also be codesigned
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
DMG_VOLUME_NAME="${DEVNOISE_DMG_VOLUME_NAME:-DevNoise}"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

require_cmd hdiutil
require_cmd ditto
[[ -x "$PLIST_BUDDY" ]] || fail "Required tool missing: $PLIST_BUDDY"

mkdir -p "$DIST_DIR"

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

INFO_PLIST="${APP_PATH}/Contents/Info.plist"
[[ -f "$INFO_PLIST" ]] || fail "Missing Info.plist at: $INFO_PLIST"

BUNDLE_NAME="$("$PLIST_BUDDY" -c 'Print :CFBundleName' "$INFO_PLIST" 2>/dev/null || true)"
VERSION="$("$PLIST_BUDDY" -c 'Print :CFBundleShortVersionString' "$INFO_PLIST" 2>/dev/null || true)"
BUILD_NUMBER="$("$PLIST_BUDDY" -c 'Print :CFBundleVersion' "$INFO_PLIST" 2>/dev/null || true)"

[[ -n "$BUNDLE_NAME" ]] || BUNDLE_NAME="$(basename "$APP_PATH" .app)"
[[ -n "$VERSION" ]] || fail "CFBundleShortVersionString is missing from $INFO_PLIST"
[[ -n "$BUILD_NUMBER" ]] || fail "CFBundleVersion is missing from $INFO_PLIST"

VERSIONED_DMG_PATH="${DIST_DIR}/${BUNDLE_NAME}-${VERSION}-${BUILD_NUMBER}.dmg"
CANONICAL_DMG_PATH="${DIST_DIR}/${BUNDLE_NAME}.dmg"

STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/devnoise-dmg.XXXXXX")"
cleanup() {
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

ditto "$APP_PATH" "${STAGE_DIR}/${BUNDLE_NAME}.app"
ln -s /Applications "${STAGE_DIR}/Applications"

rm -f "$VERSIONED_DMG_PATH" "$CANONICAL_DMG_PATH"

echo "Building DMG: $VERSIONED_DMG_PATH"
hdiutil create \
  -volname "$DMG_VOLUME_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$VERSIONED_DMG_PATH" >/dev/null

if [[ -n "${DEVNOISE_SIGN_IDENTITY:-}" ]]; then
  require_cmd codesign
  echo "Signing DMG with identity: $DEVNOISE_SIGN_IDENTITY"
  codesign --force --timestamp --sign "$DEVNOISE_SIGN_IDENTITY" "$VERSIONED_DMG_PATH"
  codesign --verify --verbose=2 "$VERSIONED_DMG_PATH"
fi

cp -f "$VERSIONED_DMG_PATH" "$CANONICAL_DMG_PATH"

echo "DMG build complete."
echo "- Versioned DMG: $VERSIONED_DMG_PATH"
echo "- Canonical DMG: $CANONICAL_DMG_PATH"
