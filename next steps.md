# Next Steps - Parallel Agent Execution Plan (10 Threads)

Date: 2026-03-01
Base commit: `c2ae2e0` on `main`

This document contains 10 detailed prompts you can run in parallel threads against the same repo.

## Global Rules For Every Thread
- Use `docs/prd.md` as product source-of-truth.
- Use `docs/tech.prd.md` for implementation details.
- If docs conflict: prefer `docs/prd.md` and record the conflict in `AGENTS.md` under risks.
- Do not add app windows, onboarding screens, preference panes, update checkers, analytics, telemetry, networking, or microphone/audio input.
- Do not request permissions on launch.
- Do not log keystroke streams or typed content.
- Persist only whitelisted keys already defined in `AGENTS.md`.
- Keep app silent on launch; never auto-play.
- Do not commit directly to `main`.
- Create thread branches with `codex/` prefix.

## Parallel Worktree Setup (Coordinator)
Run this once before starting threads:

```bash
git checkout main
git pull --ff-only

git worktree add ../devnoise-t01 -b codex/t01-state-migration main
git worktree add ../devnoise-t02 -b codex/t02-audio-dsp main
git worktree add ../devnoise-t03 -b codex/t03-audio-engine main
git worktree add ../devnoise-t04 -b codex/t04-global-hotkeys main
git worktree add ../devnoise-t05 -b codex/t05-remap-capture-core main
git worktree add ../devnoise-t06 -b codex/t06-remap-menu-integration main
git worktree add ../devnoise-t07 -b codex/t07-route-sleep-wake main
git worktree add ../devnoise-t08 -b codex/t08-release-scripts main
git worktree add ../devnoise-t09 -b codex/t09-release-workflow main
git worktree add ../devnoise-t10 -b codex/t10-site-docs-qa main
```

## Ownership Matrix
Each thread should primarily edit its owned files to minimize merge conflicts.

| Thread | Branch | Primary Owned Paths |
|---|---|---|
| 01 | `codex/t01-state-migration` | `DevNoise/State/*`, `DevNoise/Persistence/SettingsStore.swift` |
| 02 | `codex/t02-audio-dsp` | `DevNoise/Audio/DSP/*` (new) |
| 03 | `codex/t03-audio-engine` | `DevNoise/Audio/AudioEngineManager.swift`, `DevNoise/Audio/Engine/*` (new) |
| 04 | `codex/t04-global-hotkeys` | `DevNoise/Hotkeys/HotkeyManager.swift`, `DevNoise/Hotkeys/*` |
| 05 | `codex/t05-remap-capture-core` | `DevNoise/Hotkeys/Remap/*` (new), `DevNoise/Permissions/PermissionsManager.swift` (minimal) |
| 06 | `codex/t06-remap-menu-integration` | `DevNoise/UI/MenuBuilder.swift`, `DevNoise/State/*`, `DevNoise/AppDelegate.swift` |
| 07 | `codex/t07-route-sleep-wake` | `DevNoise/Audio/Observers/*` (new), `DevNoise/AppDelegate.swift`, `DevNoise/Audio/*` (minimal) |
| 08 | `codex/t08-release-scripts` | `scripts/*` |
| 09 | `codex/t09-release-workflow` | `.github/workflows/release.yml` (new), `.github/workflows/ci.yml` (minimal) |
| 10 | `codex/t10-site-docs-qa` | `site/*` (new), `vercel.json` (new), `docs/privacy.md`, `docs/troubleshooting.md`, `docs/phase1-qa.md` (new) |

## Recommended Merge Order
To reduce conflicts and rework:
1. Thread 01
2. Thread 02
3. Thread 03
4. Thread 04
5. Thread 05
6. Thread 06
7. Thread 07
8. Thread 08
9. Thread 09
10. Thread 10

---

## Thread 01 Prompt - State Contracts and Persistence Migration

```text
You are Thread 01 for DevNoise Phase 1.

Context:
- Repo root contains docs/prd.md and docs/tech.prd.md.
- Existing app is Phase 0 and compiles.
- You own state contract hardening and persistence migration.

Mission:
Upgrade state and persistence contracts for Phase 1 while preserving strict privacy/persistence constraints.

Files you may edit:
- DevNoise/State/AppModel.swift
- DevNoise/State/Action.swift
- DevNoise/State/Reducer.swift
- DevNoise/State/Store.swift
- DevNoise/Persistence/SettingsStore.swift
- AGENTS.md (only assumptions/risks if needed)

Do not edit:
- Audio DSP implementation files
- Release scripts/workflows
- Site files

Detailed tasks:
1) Depth preset migration
- Replace depth preset model values with product names: Normal, Deep, Super Deep.
- Preserve internal raw values cleanly (example: normal, deep, superDeep).
- Update display titles accordingly.

2) Backward-compatible decode/load migration
- Existing persisted values may include old Phase 0 depth values (light/medium/deep).
- Add migration mapping in SettingsStore load path:
  - light -> normal
  - medium -> deep
  - deep -> superDeep
- If unknown value, fallback to default.
- Do not add new persistence keys.

3) Enforce persistence guardrails
- Verify save/load/reset still use only whitelist keys.
- Ensure playback state is never persisted.
- Keep model default playback as stopped.

4) Action/reducer prep for later threads
- Add any non-UI state/action hooks needed for Phase 1 integration only if pure and generic.
- Keep reducer deterministic and side effects isolated.

5) Regression hardening
- Ensure reset-to-defaults restores depth/noise/volume/hotkeys/tutorial defaults and stopped playback.
- Keep existing behavior for menu checkmarks based on model values.

Acceptance criteria:
- Project builds successfully.
- Persisted old depth values migrate safely.
- No non-whitelisted keys are written.
- Playback state never enters persistence writes.

Validation commands:
- xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build
- rg -n "userDefaults\\.set|removeObject\\(forKey" DevNoise/Persistence/SettingsStore.swift

Final output required:
- Summary of changed files
- Exact migration mapping implemented
- Build result
- Any assumptions recorded in AGENTS.md
```

---

## Thread 02 Prompt - Audio DSP Kernels (No Engine Wiring)

```text
You are Thread 02 for DevNoise Phase 1.

Context:
- Phase 0 app exists with silent AudioEngineManager stub.
- Your work is pure DSP primitives in isolation.

Mission:
Implement procedural noise DSP kernels with no render-time allocation design.

Files you may create/edit:
- DevNoise/Audio/DSP/NoiseGenerator.swift (new)
- DevNoise/Audio/DSP/WhiteNoiseGenerator.swift (new)
- DevNoise/Audio/DSP/PinkNoiseGenerator.swift (new)
- DevNoise/Audio/DSP/BrownNoiseGenerator.swift (new)
- DevNoise/Audio/DSP/GreenNoiseGenerator.swift (new)
- DevNoise/Audio/DSP/PRNG.swift (new)
- DevNoise/Audio/DSP/DepthShaper.swift (new)

Do not edit:
- DevNoise/Audio/AudioEngineManager.swift
- UI/menu/state/reducer files

Detailed tasks:
1) Define shared DSP contracts
- Add protocol(s) and structs for frame generation that can be called from AVAudioSourceNode callbacks.
- API must be allocation-free during render calls.

2) Implement deterministic PRNG
- Fast PRNG suitable for audio noise.
- Independent per-channel state support.
- No Foundation random APIs in render path.

3) Implement noise kernels
- White: uniform random.
- Pink: stable filtered white implementation.
- Brown: integrated white with leak term to avoid runaway drift.
- Green: shaped noise with band-pass-ish emphasis.
- Keep CPU-conscious and deterministic.

4) Implement depth shaping primitives
- Build light-weight shaping coefficients/state for Normal/Deep/Super Deep behavior.
- Provide ramp-capable parameter model so Thread 03 can apply click-free transitions.

5) Render safety constraints
- No heap allocation in sample generation hot path.
- No locks, no file I/O, no Objective-C message sends in render path.

Acceptance criteria:
- New DSP files compile in project.
- Clear API surface for engine integration.
- No per-call allocations in render APIs.

Validation commands:
- xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build
- rg -n "Array\\(|append\\(|DispatchQueue|NS" DevNoise/Audio/DSP || true

Final output required:
- List of DSP types added
- Notes on pink/brown/green algorithm choices
- Render-thread safety checklist
```

---

## Thread 03 Prompt - Real Audio Engine Graph and Transitions

```text
You are Thread 03 for DevNoise Phase 1.

Context:
- Thread 02 provides DSP primitives (or create integration shim if not merged yet).
- Phase 0 AudioEngineManager is stubbed.

Mission:
Implement real AVAudioEngine playback with click-free transitions and no launch audio.

Files you may edit/create:
- DevNoise/Audio/AudioEngineManager.swift
- DevNoise/Audio/Engine/EngineGraph.swift (new)
- DevNoise/Audio/Engine/EnvelopeRamp.swift (new)
- DevNoise/Audio/Engine/TransitionController.swift (new)
- DevNoise/State/Action.swift (only if audio-specific actions needed)
- DevNoise/State/Reducer.swift (minimal effect wiring only)

Do not edit:
- Hotkey remap/menu UX flow
- Release scripts/workflows

Detailed tasks:
1) Build stable AVAudioEngine topology
- Two source nodes (A/B) for crossfade switching.
- Two submixers to control A/B gains.
- Master mixer output.
- Keep topology stable; do not reconnect graph for every change.

2) Implement control surface in AudioEngineManager
- start(), stop(), panicStop()
- setNoiseType(), setDepthPreset(), setVolume()
- Keep launch silent and stopped.

3) Transition timing requirements
- Play fade-in ~120ms.
- Stop fade-out ~120ms then stop engine safely.
- Noise switch crossfade ~150ms A/B.
- Depth preset ramp 50-150ms.
- Volume ramp ~50ms.

4) Click-free behavior
- Use sample-accurate or sufficiently granular envelope ramps.
- Ensure abrupt user actions (rapid toggles) remain stable.

5) Performance/safety
- No render allocations.
- Independent PRNG/state per stereo channel.
- Keep CPU overhead reasonable.

Acceptance criteria:
- Audio plays only after explicit Play.
- All transitions are click-free under normal manual testing.
- No sound on launch.

Validation commands:
- xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build
- Manual: run app, toggle Play/Stop, switch noise/depth/volume quickly

Final output required:
- Graph topology summary
- Transition implementation notes
- Known edge cases and mitigation
```

---

## Thread 04 Prompt - Global Hotkeys via RegisterEventHotKey

```text
You are Thread 04 for DevNoise Phase 1.

Context:
- Hotkey models/validation exist.
- Phase 0 manager is a no-op.

Mission:
Implement working global hotkeys for six default actions without continuous event tap.

Files you may edit/create:
- DevNoise/Hotkeys/HotkeyManager.swift
- DevNoise/Hotkeys/HotkeyModels.swift (minimal, if needed)
- DevNoise/State/Store.swift (for callback injection only)
- DevNoise/AppDelegate.swift (wire manager callback only)

Do not edit:
- Remap capture/menu flow (Thread 05/06)
- Audio DSP/engine internals

Detailed tasks:
1) Implement Carbon-based registration
- Use RegisterEventHotKey for each binding.
- Create robust mapping between HotkeyAction and EventHotKeyID.
- Support re-register and unregister.

2) Dispatch integration
- Expose callback(s) so hotkey events dispatch reducer actions.
- Ensure actions map correctly:
  - Play/Stop
  - Panic
  - Next Noise
  - Cycle Depth
  - Volume Up
  - Volume Down

3) Robust lifecycle
- Safe repeated register/unregister cycles.
- No leaked handlers.
- Graceful behavior if registration fails.

4) Security/privacy constraints
- Do not log raw keyboard events.
- Log only high-level action names for debugging if needed.

Acceptance criteria:
- Global hotkeys trigger mapped actions while app runs.
- Rebinding-ready architecture remains intact.
- Build succeeds.

Validation commands:
- xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build
- Manual: verify each default hotkey action triggers expected behavior

Final output required:
- Registration mechanism summary
- Failure/edge handling summary
- Manual hotkey verification matrix
```

---

## Thread 05 Prompt - Remap Capture Core (Time-Boxed, Permission-Gated)

```text
You are Thread 05 for DevNoise Phase 1.

Context:
- Hotkeys work globally (Thread 04).
- You are implementing remap capture core service only.

Mission:
Build a reusable remap capture manager that captures one final chord in a 5-second explicit listening window.

Files you may edit/create:
- DevNoise/Hotkeys/Remap/RemapCaptureManager.swift (new)
- DevNoise/Hotkeys/Remap/RemapCaptureState.swift (new)
- DevNoise/Hotkeys/Remap/RemapCaptureError.swift (new)
- DevNoise/Permissions/PermissionsManager.swift (only helper APIs if required)

Do not edit:
- Menu UI integration (Thread 06)
- Release scripts/workflows/site

Detailed tasks:
1) Implement capture lifecycle API
- beginCapture(for action, timeout: 5s, completion)
- cancelCapture()
- isCapturing/currentTargetAction

2) Capture constraints
- Capture exactly one final chord result.
- Esc cancels capture.
- Timeout cancels with explicit error.
- Reject invalid chords via existing validation rules.

3) Permission behavior
- Capture should be callable only from explicit user initiation.
- Check permission status on begin.
- If missing permission, return explicit error and do not start capture.
- Do not prompt automatically outside explicit begin call.

4) Privacy behavior
- Never log key streams or raw typed content.
- Persist nothing in this manager.

Acceptance criteria:
- Manager can start/cancel/timeout reliably.
- Produces valid HotkeyChord outputs only.
- Does not require windows.

Validation commands:
- xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build

Final output required:
- Public API summary
- Error model summary
- Permission and privacy guarantees implemented
```

---

## Thread 06 Prompt - Remap and Permissions Menu Integration

```text
You are Thread 06 for DevNoise Phase 1.

Context:
- Thread 05 provides remap capture core.
- You integrate remapping UX into existing menu architecture.

Mission:
Integrate explicit menu-driven remap flow and permissions status/actions into reducer/store/menu without windows.

Files you may edit:
- DevNoise/UI/MenuBuilder.swift
- DevNoise/State/AppModel.swift
- DevNoise/State/Action.swift
- DevNoise/State/Reducer.swift
- DevNoise/State/Store.swift
- DevNoise/AppDelegate.swift

Do not edit:
- Audio DSP internals
- Release scripts/workflows/site

Detailed tasks:
1) Model/action additions
- Add remap state fields (idle/listening/success/failure with brief status text).
- Add actions for begin remap, cancel remap, remap result, remap timeout.

2) Menu UX flow
- Add menu items for each remappable action:
  - Remap Play/Stop...
  - Remap Panic...
  - Remap Next Noise...
  - Remap Cycle Depth...
  - Remap Vol Up...
  - Remap Vol Down...
- Show listening status line when active.
- Show permission state clearly when not granted.
- Include Open System Settings action.

3) Behavior rules
- Enter listening mode only on explicit menu action.
- Time-box listening mode to 5 seconds.
- Esc cancels.
- On successful capture, update model/persistence and re-register hotkeys.
- On error (invalid, collision, permission missing), keep previous binding and show status.

4) Non-negotiables
- No windows.
- No key stream logging.
- No raw key persistence.

Acceptance criteria:
- Full remap flow works from menu only.
- Permission missing path is clear and non-blocking for core menu controls.
- Hotkeys re-register after successful remap.

Validation commands:
- xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build
- Manual: remap one action, verify display updates and hotkey works

Final output required:
- Menu changes summary
- State/action additions summary
- Manual remap test results
```

---

## Thread 07 Prompt - Route Change and Sleep/Wake Stability

```text
You are Thread 07 for DevNoise Phase 1.

Context:
- Real audio engine exists or is in progress.
- Need lifecycle resilience around output changes and power events.

Mission:
Implement route/device change and sleep/wake handling with safe stop/resume behavior.

Files you may edit/create:
- DevNoise/Audio/Observers/RouteObserver.swift (new)
- DevNoise/Audio/Observers/SleepWakeObserver.swift (new)
- DevNoise/Audio/AudioEngineManager.swift (minimal integration points)
- DevNoise/AppDelegate.swift (observer wiring)
- DevNoise/State/Action.swift / Reducer.swift (minimal, only if needed)

Do not edit:
- Remap flow details
- Release scripts/workflows/site

Detailed tasks:
1) Route observer
- Detect relevant audio route/output-device changes.
- Notify audio manager.
- If restart needed, do it safely and maintain click-free behavior.

2) Sleep/wake observer
- On sleep: stop audio safely and track wasPlaying in memory only.
- On wake: resume only if wasPlaying true.
- Never persist wasPlaying.

3) Failure handling
- If resume fails, stay stopped and expose safe status.
- Keep app responsive and stable.

Acceptance criteria:
- Sleep/wake does not leave engine in bad state.
- Route changes do not crash and remain click-free when possible.
- No persistence rule violations.

Validation commands:
- xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build
- Manual lifecycle tests with sleep/wake and output device switch

Final output required:
- Observer architecture summary
- Lifecycle behavior matrix
- Any residual risks
```

---

## Thread 08 Prompt - Real Release Scripts (Build/Sign/Notarize/DMG)

```text
You are Thread 08 for DevNoise Phase 1.

Context:
- Placeholder scripts exist in scripts/.
- Need real local release pipeline.

Mission:
Implement production-ready script pipeline for signed/notarized DMG artifacts.

Files you may edit:
- scripts/build_release.sh
- scripts/codesign.sh
- scripts/notarize.sh
- scripts/staple.sh
- scripts/dmg_build.sh
- scripts/sha256.sh
- scripts/verify_gatekeeper.sh
- README.md (release usage section only)

Do not edit:
- App runtime code
- Workflows (Thread 09)

Detailed tasks:
1) Script conventions
- Use `set -euo pipefail`.
- Add argument/env validation and helpful error messages.
- Keep scripts composable and idempotent where practical.

2) Build script
- Build Release app artifact via xcodebuild.
- Output under `dist/`.

3) Signing and notarization
- Codesign with Developer ID + hardened runtime.
- Notarize with `notarytool`, wait for completion, parse result.
- Staple notarization ticket.

4) DMG and checksum
- Build DMG with Applications symlink.
- Generate SHA-256 sidecar file.
- Add Gatekeeper verification command.

5) Artifact metadata
- Generate/update `dist/latest.json` with version/build/url/checksum fields suitable for site/workflow consumption.

Acceptance criteria:
- Scripts execute end-to-end given valid signing credentials.
- Output artifacts are in `dist/` with clear naming.
- Clear failure messages for missing env vars.

Validation commands:
- bash -n scripts/*.sh
- scripts/build_release.sh (local dry run if possible)

Final output required:
- Required env vars list
- Script execution order
- Example successful artifact tree
```

---

## Thread 09 Prompt - GitHub Tag Release Workflow

```text
You are Thread 09 for DevNoise Phase 1.

Context:
- CI build workflow exists.
- Thread 08 provides real scripts.

Mission:
Add GitHub Actions release workflow for tags `v*` to publish DMG artifacts and metadata.

Files you may edit/create:
- .github/workflows/release.yml (new)
- .github/workflows/ci.yml (only if needed to avoid overlap/duplication)
- README.md (release automation notes only)

Do not edit:
- App runtime code
- Site content (Thread 10)

Detailed tasks:
1) Trigger and platform
- Trigger on push tags matching `v*`.
- Use macOS runner.

2) Build pipeline steps
- Checkout repo.
- Configure toolchain prerequisites.
- Execute scripts from Thread 08 in order.
- Produce `DevNoise.dmg`, `DevNoise.dmg.sha256`, `latest.json`.

3) Release publication
- Create/update GitHub Release for the tag.
- Upload artifacts.
- Use secure secrets handling (no plaintext secrets).

4) Reliability
- Fail fast on missing secrets.
- Keep logs useful but non-sensitive.

Acceptance criteria:
- Tag push can produce release artifacts.
- Workflow file is readable and maintainable.
- Existing CI build workflow remains functional.

Validation commands:
- Validate YAML syntax (locally or by workflow lint if available).
- Dry-run reasoning in PR description.

Final output required:
- Secrets required list
- Release job step summary
- Artifact names produced
```

---

## Thread 10 Prompt - Download Site, Privacy Docs, Troubleshooting, QA Matrix

```text
You are Thread 10 for DevNoise Phase 1.

Context:
- App runtime must stay offline/no telemetry.
- Distribution website can be separate static site on Vercel.

Mission:
Build minimal static download site and complete operational docs for privacy/troubleshooting/QA.

Files you may edit/create:
- site/index.html (new)
- site/styles.css (new)
- site/release-notes.md (new)
- vercel.json (new)
- docs/privacy.md
- docs/troubleshooting.md
- docs/phase1-qa.md (new)
- README.md (site/deploy/docs links section)

Do not edit:
- App runtime code in DevNoise/
- scripts/ and workflows beyond doc references

Detailed tasks:
1) Static site
- Create simple landing page with Download button.
- Button points to `/download`.
- Include version area and release notes link.

2) Redirect behavior
- Configure `vercel.json` redirect `308 /download` to latest artifact URL.
- Default to GitHub Releases latest download URL pattern.

3) Privacy doc hardening
- Explicitly state:
  - no network in app
  - no analytics/telemetry
  - no microphone/audio input
  - no keystroke logging/storage
  - permissions only for global control/remap

4) Troubleshooting expansion
- Add sections for no sound, hotkeys not working, permissions not granted, remap timeout/collision, notarization/Gatekeeper issues.

5) QA matrix
- Create `docs/phase1-qa.md` with manual test matrix:
  - launch silence
  - play/stop fade behavior
  - crossfade/depth ramp checks
  - global hotkeys
  - remap flow
  - sleep/wake
  - route changes
  - release artifact verification

Acceptance criteria:
- Site is static and deployable to Vercel.
- `/download` redirect exists and is clear.
- Documentation is explicit and operator-friendly.

Validation commands:
- Verify `vercel.json` and local file links.
- Markdown/docs lint if available.

Final output required:
- Site file summary
- Redirect target used
- QA matrix coverage summary
```

---

## Coordinator Merge Checklist
Use this after all threads complete:

1. Rebase each thread branch onto latest `main` before merge.
2. Merge in recommended order from this file.
3. After each merge, run:
   - `xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build`
4. After Thread 08-10 merges, run release dry-run checks.
5. Update `CHANGELOG.md` with Phase 1 completion details.
6. Tag release when acceptance criteria are fully met.

