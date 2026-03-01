# DevNoise

DevNoise is a menu-bar-only macOS app for procedural noise playback with hotkey-first controls.

## Phase 0 status
- Menu bar shell and deterministic app state store are implemented.
- Audio, hotkey registration, and permission requests are skeleton implementations.
- App is silent by default and never auto-plays.

## Build
```bash
xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug build
```

## Run
```bash
open DevNoise.xcodeproj
```
Run the `DevNoise` scheme from Xcode.

## Release pipeline
Required environment variables:
```bash
export DEVNOISE_SIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)"

# Option A (recommended): notarytool keychain profile
export DEVNOISE_NOTARY_KEYCHAIN_PROFILE="AC_NOTARY"

# Option B: Apple ID credentials for notarytool
export DEVNOISE_NOTARY_APPLE_ID="developer@example.com"
export DEVNOISE_NOTARY_TEAM_ID="TEAMID"
export DEVNOISE_NOTARY_APP_PASSWORD="app-specific-password"

# Optional: used when generating dist/latest.json
export DEVNOISE_RELEASE_BASE_URL="https://downloads.example.com/devnoise"
```

Execution order:
```bash
scripts/build_release.sh
scripts/codesign.sh
scripts/dmg_build.sh
scripts/notarize.sh
scripts/staple.sh
scripts/sha256.sh
scripts/verify_gatekeeper.sh
```

Artifacts are written to `dist/`, including a versioned `.app`, versioned `.dmg`, checksum sidecar, and `latest.json`.

## Docs
- Product requirements: `docs/prd.md`
- Technical plan: `docs/tech.prd.md`
- Privacy guarantees: `docs/privacy.md`
- Troubleshooting: `docs/troubleshooting.md`
- Phase 1 manual QA: `docs/phase1-qa.md`
- Download landing page source: `site/index.html`
- Site release notes: `site/release-notes.md`
- Vercel routing/redirect config: `vercel.json`
