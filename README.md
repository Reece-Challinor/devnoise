# DevNoise

DevNoise is a tiny, keyboard-centric macOS menu-bar app for procedural background noise.
It launches silently, displays `DN` in the menu bar, and has no Dock icon or app window.

## What it does

- Generates White, Pink, Brown, and Green noise locally.
- Provides Normal, Deep, and Super Deep tone presets.
- Starts the audio engine only when Play is requested.
- Saves noise type, depth, and volume. Playback always starts stopped.
- Registers six fixed global shortcuts with Carbon; no permissions or remapping are needed.

| Action | Shortcut |
| --- | --- |
| Play / Stop | Control-Command-N |
| Panic Stop | Control-Command-Escape |
| Next Noise | Control-Command-] |
| Cycle Depth | Control-Command-[ |
| Volume Up | Control-Command-= |
| Volume Down | Control-Command-- |

## Build and run

Requires macOS 13 or later and Xcode.

```bash
xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug build
open DevNoise.xcodeproj
```

Run the `DevNoise` scheme from Xcode, then use `DN` in the menu bar. DevNoise intentionally
does not appear in the Dock.

## Verify

```bash
xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' test
xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Release build
```

Manual launch checks are in `docs/phase1-qa.md`; common fixes are in
`docs/troubleshooting.md`.

## Release

A `v*` tag runs tests, builds and signs the app, builds and notarizes the DMG, staples the
notarization tickets, verifies Gatekeeper, and publishes the release artifacts. Run the manual
QA checklist before creating the tag.
