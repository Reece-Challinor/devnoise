# AGENTS.md

## Scope
These instructions govern all changes in this repository.

## Non-negotiables
- Menu-bar only app. No runtime windows.
- No Dock icon (`LSUIElement = 1`).
- Silent on launch. Never auto-play.
- Procedural audio architecture only.
- No network calls in-app.
- No analytics or telemetry.
- No microphone/audio input.
- Permissions are only requested on explicit user action.
- Never log/store/transmit typed content.
- Never persist playback state.
- No third-party dependencies.
- No update checkers, daemons, launch agents, or background services.

## Persistence Whitelist
Only these UserDefaults keys are allowed:
- `hotkeys.playStop`
- `hotkeys.panicStop`
- `hotkeys.nextNoise`
- `hotkeys.cycleDepth`
- `hotkeys.volumeUp`
- `hotkeys.volumeDown`
- `audio.noiseType`
- `audio.depthPreset`
- `audio.volume`
- `ui.tutorialDismissed`

## Input/Keystroke Rules
- Never capture or persist raw typed content.
- Keep the six fixed Carbon hotkeys; do not add keyboard monitoring or remapping.
- Any debugging output must never include user keystroke streams.

## Real-time Audio Rule (Phase 1 guardrail)
In render callbacks, do not allocate memory, lock mutexes, do file I/O, do network I/O, call Objective-C APIs, or perform blocking work.

## Current Runtime
- Six production Swift files: lifecycle coordinator, model, status menu, settings, hotkeys, and audio.
- The `DN` status item is installed before settings, hotkeys, or audio work.
- Audio is lazy and begins only after an explicit Play command.
- The six global hotkeys are fixed, exclusive Carbon registrations and require no permissions.
- Only noise type, depth, and volume are actively persisted; playback always starts stopped.
- Product constraints in `docs/prd.md` take precedence over implementation details in `docs/tech.prd.md`.

## Operational Commands
### Open project
```bash
open DevNoise.xcodeproj
```

### Build (debug)
```bash
xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug build
```

### Test
```bash
xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' test
```

### Build (release)
```bash
xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Release build
```

### Run release pipeline scripts
```bash
scripts/build_release.sh
scripts/codesign.sh
scripts/dmg_build.sh
scripts/notarize.sh dist/DevNoise.dmg
scripts/staple.sh
scripts/sha256.sh
scripts/verify_gatekeeper.sh
```
