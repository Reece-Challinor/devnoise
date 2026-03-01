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

## Docs
- Product requirements: `docs/prd.md`
- Technical plan: `docs/tech.prd.md`
- Privacy guarantees: `docs/privacy.md`
- Troubleshooting: `docs/troubleshooting.md`
