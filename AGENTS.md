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
- No third-party dependencies in Phase 0.
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
- During remap flows, only persist final chord bindings.
- Any debugging output must never include user keystroke streams.

## Real-time Audio Rule (Phase 1 guardrail)
In render callbacks, do not allocate memory, lock mutexes, do file I/O, do network I/O, call Objective-C APIs, or perform blocking work.

## Bootstrapping Notes
### Plan
- [x] Create repository skeleton, docs, scripts, and policy file.
- [x] Create `DevNoise.xcodeproj` macOS app target with `LSUIElement=1`.
- [x] Implement Phase 0 architecture: menu bar shell, store/reducer, persistence, hotkey/permission/audio skeletons.
- [x] Add CI build workflow and release-script placeholders.
- [x] Build and verify app behavior; update assumptions and risks.

### Phase 0 Checklist
- [x] Step 1: Initialize repository skeleton
- [x] Step 2: Create Xcode project
- [x] Step 3: Implement menu-bar shell
- [x] Step 4: Implement core state machine
- [x] Step 5: Implement persistence whitelist
- [x] Step 6: Implement hotkeys skeleton
- [x] Step 7: Implement permissions skeleton
- [x] Step 8: Implement audio skeleton
- [x] Step 9: Add scripts and CI scaffolding
- [x] Step 10: Finalize strict AGENTS rules and operations

## Assumptions Made In Phase 0
- Help action is a non-network local action in Phase 0.
- Global hotkey execution is intentionally no-op until later phases.
- Volume menu uses fixed presets for deterministic checkmark state.
- Default persisted settings are written during app launch so whitelist keys exist with stable defaults.
- Phase 1 depth migration disambiguates legacy persisted `audio.depthPreset=deep` by treating it as old "deep" (`Super Deep`) and persisting current "Deep" as `phase1.deep`.

## Risks / PRD Conflicts
- No explicit conflict between `docs/prd.md` and `docs/tech.prd.md` identified during bootstrap parsing.
- If future conflicts emerge, product constraints in `docs/prd.md` take precedence over implementation details in `docs/tech.prd.md`.

## Operational Commands
### Open project
```bash
open DevNoise.xcodeproj
```

### Build (debug)
```bash
xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug build
```

### Build (release)
```bash
xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Release build
```

### Run release pipeline scripts (placeholders)
```bash
scripts/build_release.sh
scripts/codesign.sh
scripts/notarize.sh
scripts/staple.sh
scripts/dmg_build.sh
scripts/sha256.sh
scripts/verify_gatekeeper.sh
```
