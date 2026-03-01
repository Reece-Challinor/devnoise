#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Build a Release app artifact into dist/.

Usage:
  scripts/build_release.sh

Environment:
  DEVNOISE_PROJECT_PATH      Default: <repo>/DevNoise.xcodeproj
  DEVNOISE_SCHEME            Default: DevNoise
  DEVNOISE_CONFIGURATION     Default: Release
  DEVNOISE_DIST_DIR          Default: <repo>/dist
  DEVNOISE_DERIVED_DATA_DIR  Default: <repo>/.build/release
USAGE
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 0 ]]; then
  echo "error: unexpected arguments: $*" >&2
  usage >&2
  exit 1
fi

fail() {
  echo "error: $*" >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || fail "Required command not found: $cmd"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PROJECT_PATH="${DEVNOISE_PROJECT_PATH:-${REPO_ROOT}/DevNoise.xcodeproj}"
SCHEME="${DEVNOISE_SCHEME:-DevNoise}"
CONFIGURATION="${DEVNOISE_CONFIGURATION:-Release}"
DIST_DIR="${DEVNOISE_DIST_DIR:-${REPO_ROOT}/dist}"
DERIVED_DATA_DIR="${DEVNOISE_DERIVED_DATA_DIR:-${REPO_ROOT}/.build/release}"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

require_cmd xcodebuild
require_cmd ditto
[[ -x "$PLIST_BUDDY" ]] || fail "Required tool missing: $PLIST_BUDDY"
[[ -d "$PROJECT_PATH" ]] || fail "Xcode project not found at: $PROJECT_PATH"

mkdir -p "$DIST_DIR"
mkdir -p "$DERIVED_DATA_DIR"

echo "Reading build settings for scheme '$SCHEME'..."
if ! BUILD_SETTINGS="$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION" -showBuildSettings 2>/dev/null)"; then
  fail "Unable to read build settings. Verify project/scheme/configuration values."
fi

PRODUCT_NAME="$(printf '%s\n' "$BUILD_SETTINGS" | awk -F' = ' '/^[[:space:]]*PRODUCT_NAME = / { print $2; exit }')"
FULL_PRODUCT_NAME="$(printf '%s\n' "$BUILD_SETTINGS" | awk -F' = ' '/^[[:space:]]*FULL_PRODUCT_NAME = / { print $2; exit }')"

if [[ -z "$PRODUCT_NAME" ]]; then
  PRODUCT_NAME="$SCHEME"
fi
if [[ -z "$FULL_PRODUCT_NAME" ]]; then
  FULL_PRODUCT_NAME="${PRODUCT_NAME}.app"
fi

echo "Building $FULL_PRODUCT_NAME ($CONFIGURATION)..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  -destination "generic/platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

BUILT_PRODUCTS_DIR="${DERIVED_DATA_DIR}/Build/Products/${CONFIGURATION}"
BUILT_APP_PATH="${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}"

if [[ ! -d "$BUILT_APP_PATH" ]]; then
  LATEST_APP=""
  shopt -s nullglob
  for CANDIDATE in "$BUILT_PRODUCTS_DIR"/*.app; do
    [[ -d "$CANDIDATE" ]] || continue
    if [[ -z "$LATEST_APP" || "$CANDIDATE" -nt "$LATEST_APP" ]]; then
      LATEST_APP="$CANDIDATE"
    fi
  done
  shopt -u nullglob

  [[ -n "$LATEST_APP" ]] || fail "No .app produced in $BUILT_PRODUCTS_DIR"
  BUILT_APP_PATH="$LATEST_APP"
fi

INFO_PLIST="${BUILT_APP_PATH}/Contents/Info.plist"
[[ -f "$INFO_PLIST" ]] || fail "Missing Info.plist at: $INFO_PLIST"

VERSION="$("$PLIST_BUDDY" -c 'Print :CFBundleShortVersionString' "$INFO_PLIST" 2>/dev/null || true)"
BUILD_NUMBER="$("$PLIST_BUDDY" -c 'Print :CFBundleVersion' "$INFO_PLIST" 2>/dev/null || true)"
APP_BUNDLE_NAME="$(basename "$BUILT_APP_PATH" .app)"

[[ -n "$VERSION" ]] || fail "CFBundleShortVersionString is missing from $INFO_PLIST"
[[ -n "$BUILD_NUMBER" ]] || fail "CFBundleVersion is missing from $INFO_PLIST"

VERSIONED_APP_PATH="${DIST_DIR}/${APP_BUNDLE_NAME}-${VERSION}-${BUILD_NUMBER}.app"
CANONICAL_APP_PATH="${DIST_DIR}/${APP_BUNDLE_NAME}.app"

rm -rf "$VERSIONED_APP_PATH" "$CANONICAL_APP_PATH"
ditto "$BUILT_APP_PATH" "$VERSIONED_APP_PATH"
ditto "$VERSIONED_APP_PATH" "$CANONICAL_APP_PATH"

echo "Build complete."
echo "- Versioned app: $VERSIONED_APP_PATH"
echo "- Canonical app: $CANONICAL_APP_PATH"
