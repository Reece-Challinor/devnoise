# DevNoise Final Assessment (Phase 1)

Date: 2026-03-01  
Agent: DevNoise Final Assessment Agent  
Repository: `/Users/reecechallinor/Development/Projects/devnoise`

## Executive Summary
- Assessment type: read-only audit + static validation + build validation.
- Preflight state: repository is **dirty** on `main` and **ahead 21** commits from `origin/master`.
- Thread merge history exists for `t01, t02, t03, t04 (local variant), t05, t06, t07, t08, t10`; no merge evidence for `t09`.
- Required deliverables have blocking gaps:
  - `release.yml` missing (Thread 09 failure).
  - Green noise is implemented in DSP/engine internals but not exposed by app state/menu (PRD/TECH_PRD drift).
  - Panic hotkey dispatches soft stop (`togglePlayback`) instead of `panicStop`.
  - Canonical planning docs are currently deleted in working tree (`next steps.md`, `next-steps-master-merge.md`).

## Readiness Verdict
**NO-GO**

Rationale: unresolved P0/P1 findings against authoritative requirements (`docs/prd.md`, `docs/tech.prd.md`, `AGENTS.md`, and thread prompts from `next steps.md`).

## 1) Preflight

### Branch, status, worktrees, and branches
- Command: `git rev-parse --abbrev-ref HEAD`
- Output: `main`

- Command: `git status --short --branch`
- Output:
  - `## main...origin/master [ahead 21]`
  - ` M .DS_Store`
  - ` D "next steps.md"`
  - ` D next-steps-master-merge.md`

- Command: `git worktree list --porcelain`
- Output:
  - `worktree /Users/reecechallinor/Development/Projects/devnoise`
  - `branch refs/heads/main`

- Command: `git branch -vv --all`
- Output:
  - local: `main`
  - remotes: `origin/master`

### codex/t01..t10 existence and merge state
- Command: loop over `codex/t01 ... codex/t10` with `git show-ref` (local + remote)
- Output: all 10 branches reported `local no` and `remote no`.

### Uncommitted changes by active worktree
- Command: iterate all worktrees and run `git -C <wt> status --short --branch`
- Output for `/Users/reecechallinor/Development/Projects/devnoise`:
  - `## main...origin/master [ahead 21]`
  - ` M .DS_Store`
  - ` D "next steps.md"`
  - ` D next-steps-master-merge.md`

### Merge evidence for thread work
- Command: `git log --oneline --merges --decorate`
- Output includes:
  - `merge(t01-state-migration)`
  - `merge(t02-audio-dsp)`
  - `merge(t03-audio-engine)`
  - `merge(t05-remap-capture-core)`
  - `merge(t06-remap-menu-integration)`
  - `merge(t07-route-sleep-wake)`
  - `merge(t08-release-scripts)`
  - `merge(t10-site-docs-qa)`
  - `merge(t04-global-hotkeys-local)`
- No merge entry for `t09`.

## 2) Structural and File Audit

### Tracked file inventory and expected layout
- Command: `git ls-files`
- Result: tracked app/docs/scripts/site/CI assets are present; `.build/...` build outputs are also tracked.

- Command: required-path presence loop
- Output highlights:
  - `PRESENT`:
    - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise`
    - `/Users/reecechallinor/Development/Projects/devnoise/docs/prd.md`
    - `/Users/reecechallinor/Development/Projects/devnoise/docs/tech.prd.md`
    - `/Users/reecechallinor/Development/Projects/devnoise/scripts/*.sh`
    - `/Users/reecechallinor/Development/Projects/devnoise/.github/workflows/ci.yml`
    - `/Users/reecechallinor/Development/Projects/devnoise/site/*`
    - `/Users/reecechallinor/Development/Projects/devnoise/vercel.json`
  - `MISSING`:
    - `/Users/reecechallinor/Development/Projects/devnoise/.github/workflows/release.yml`
    - `/Users/reecechallinor/Development/Projects/devnoise/next steps.md` (deleted in working tree)
    - `/Users/reecechallinor/Development/Projects/devnoise/next-steps-master-merge.md` (deleted in working tree)

### Duplicate app roots check
- Command: `find . -maxdepth 3 -type d -name 'DevNoise' -o -name '*.app'`
- Output:
  - `./DevNoise`
  - `./dist/DevNoise-0.1.0-1.app`
  - `./dist/DevNoise.app`
- Assessment: no duplicate source app root; `.app` bundles are under `dist/` as release artifacts.

### Info.plist, project, scheme integrity
- Command: `plutil -p DevNoise/Info.plist`
- Output includes `"LSUIElement" => true`.

- Command: `xcodebuild -project DevNoise.xcodeproj -list`
- Output: project/target/configurations/scheme resolve successfully.

- Command: `plutil -lint DevNoise/Info.plist`
- Output: `OK`

- Command: `xmllint --noout DevNoise.xcodeproj/xcshareddata/xcschemes/DevNoise.xcscheme`
- Output: `xcscheme xml: OK`

## 3) Thread-by-Thread Deliverable Audit

### Matrix
| Thread | Status | Summary |
|---|---|---|
| 01 State contracts + persistence migration | PASS | Depth migration + whitelist persistence implemented. |
| 02 DSP primitives + no-alloc design surface | PASS | DSP kernels and depth shaper implemented in `DevNoise/Audio/DSP/*`. |
| 03 Audio engine graph + transitions | PASS | Real engine graph/transitions implemented and project builds. |
| 04 Global hotkeys | FAIL | Panic hotkey mapping does not dispatch `panicStop`. |
| 05 Remap capture core | PASS | Capture manager + state/error models implemented. |
| 06 Remap menu/state integration | PASS | Menu-driven remap flows and permission-state UX wired in reducer/UI. |
| 07 Route change + sleep/wake | PASS | Observers and lifecycle wiring implemented. |
| 08 Real release scripts | BLOCKED | Scripts implemented and syntax-valid; end-to-end sign/notarize not executable without credentials. |
| 09 Tag release workflow | FAIL | `.github/workflows/release.yml` missing. |
| 10 Site/privacy/troubleshooting/QA | PASS | Site + docs + QA matrix present. |

### Exact files touched per thread (commit evidence)

Thread 01 (`53ceac6`):
- `/Users/reecechallinor/Development/Projects/devnoise/AGENTS.md`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Persistence/SettingsStore.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/AppModel.swift`
- Missing items: none.

Thread 02 (`f6b2c4f`):
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise.xcodeproj/project.pbxproj`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/DSP/NoiseGenerator.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/DSP/PRNG.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/DSP/WhiteNoiseGenerator.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/DSP/PinkNoiseGenerator.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/DSP/BrownNoiseGenerator.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/DSP/GreenNoiseGenerator.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/DSP/DepthShaper.swift`
- Missing items: none.

Thread 03 (`3afcf68`, plus post-merge fix `53c73c0`):
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise.xcodeproj/project.pbxproj`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/AudioEngineManager.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/Engine/EngineGraph.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/Engine/EnvelopeRamp.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/Engine/TransitionController.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Action.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Reducer.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Store.swift`
- Missing items: none in thread-owned scope.

Thread 04 (`22317be`, merged as `t04-global-hotkeys-local`):
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/AppDelegate.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Hotkeys/HotkeyManager.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Store.swift`
- Also touched unrelated files: `.DS_Store`, `.next-steps-master-merge.md.swp`, `next steps.md`, `next-steps-master-merge.md`, `scripts/merge_all_threads_to_main.sh`.
- Missing/failed item: panic action mapping correctness (see findings).

Thread 05 (`fe411fc`):
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Hotkeys/Remap/RemapCaptureManager.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Hotkeys/Remap/RemapCaptureState.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Hotkeys/Remap/RemapCaptureError.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Permissions/PermissionsManager.swift`
- Missing items: none.

Thread 06 (`e83b9a1`):
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/AppDelegate.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Action.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/AppModel.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Reducer.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/UI/MenuBuilder.swift`
- Missing items: none in static file presence; architecture drift noted (RemapCaptureManager unused).

Thread 07 (`1c978e3`):
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise.xcodeproj/project.pbxproj`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/AppDelegate.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/AudioEngineManager.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/Observers/RouteObserver.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/Observers/SleepWakeObserver.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Action.swift`
- `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Reducer.swift`
- Missing items: none.

Thread 08 (`75366d4`):
- `/Users/reecechallinor/Development/Projects/devnoise/scripts/build_release.sh`
- `/Users/reecechallinor/Development/Projects/devnoise/scripts/codesign.sh`
- `/Users/reecechallinor/Development/Projects/devnoise/scripts/notarize.sh`
- `/Users/reecechallinor/Development/Projects/devnoise/scripts/staple.sh`
- `/Users/reecechallinor/Development/Projects/devnoise/scripts/dmg_build.sh`
- `/Users/reecechallinor/Development/Projects/devnoise/scripts/sha256.sh`
- `/Users/reecechallinor/Development/Projects/devnoise/scripts/verify_gatekeeper.sh`
- `/Users/reecechallinor/Development/Projects/devnoise/README.md`
- `/Users/reecechallinor/Development/Projects/devnoise/dist/*` artifacts
- Additional commit noise: 453 tracked files under `/Users/reecechallinor/Development/Projects/devnoise/.build/...`
- Missing items: runtime notarization/signing verification blocked by missing credentials.

Thread 09:
- Expected file: `/Users/reecechallinor/Development/Projects/devnoise/.github/workflows/release.yml`
- Missing items: `release.yml` absent; no `t09` commit/merge evidence.

Thread 10 (`c55ff7d`):
- `/Users/reecechallinor/Development/Projects/devnoise/site/index.html`
- `/Users/reecechallinor/Development/Projects/devnoise/site/styles.css`
- `/Users/reecechallinor/Development/Projects/devnoise/site/release-notes.md`
- `/Users/reecechallinor/Development/Projects/devnoise/vercel.json`
- `/Users/reecechallinor/Development/Projects/devnoise/docs/privacy.md`
- `/Users/reecechallinor/Development/Projects/devnoise/docs/troubleshooting.md`
- `/Users/reecechallinor/Development/Projects/devnoise/docs/phase1-qa.md`
- `/Users/reecechallinor/Development/Projects/devnoise/README.md`
- Missing items: none.

## 4) Non-Negotiable Policy Checks

| Check | Result | Evidence |
|---|---|---|
| Menu-bar only / no runtime windows | PASS | File: `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/AppDelegate.swift:5-46`; Command: `rg -n "NSWindow|WindowGroup|NSPanel" DevNoise` returned no matches. |
| No Dock icon (`LSUIElement=1`) | PASS | File: `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Info.plist`; Command: `plutil -p DevNoise/Info.plist` => `"LSUIElement" => true`. |
| Silent on launch / never auto-play | PASS | File: `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Reducer.swift:5-13` (`.appLaunched` has no `.audioStart`), `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/AppModel.swift:96-100` default stopped. |
| Procedural audio architecture | PASS | Files: `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/Engine/EngineGraph.swift`, `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/DSP/*`; no loop assets present in `DevNoise/`. |
| No network calls in-app | PASS | Command: `rg -n "URLSession|NWConnection|http://|https://" DevNoise` found no runtime network calls (only plist doctype URL). |
| No analytics/telemetry | PASS | Command: `rg -n "analytics|telemetry|mixpanel|firebase|sentry|amplitude" DevNoise` found none. |
| No microphone/audio input | PASS | Command: `rg -n "inputNode|AVAudioRecorder|AVCaptureAudio|AVAudioSession|microphone|record" DevNoise` found none. |
| Permissions only on explicit user action | PASS | Files: `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Reducer.swift:74-81`, `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Permissions/PermissionsManager.swift:10-16`. Launch path uses prompt false. |
| No keystroke stream logging/storage | PASS | Files: `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/AppDelegate.swift:117-136`, `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Hotkeys/HotkeyManager.swift:178-181`; logs contain action names only, not raw key streams. |
| UserDefaults writes whitelist-only | PASS | File: `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Persistence/SettingsStore.swift:11-37,85-103`; Command: `rg -n "UserDefaults|set\(|removeObject" DevNoise` shows writes only in SettingsStore keys. |
| Playback state never persisted | PASS | File: `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Persistence/SettingsStore.swift:81` forces `.stopped`; no `playbackState` writes in `save(model:)`. |

## 5) Build and Static Validation

### Executed checks
- `xcodebuild -project DevNoise.xcodeproj -list` -> success.
- `xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build` -> `** BUILD SUCCEEDED **`.
- `bash -n scripts/*.sh` -> success (no syntax errors).
- YAML parse: `ruby -ryaml -e "YAML.load_file(...)"` for `.github/workflows/ci.yml` -> OK.
- `plutil -lint DevNoise/Info.plist` -> OK.
- `xmllint --noout DevNoise.xcodeproj/xcshareddata/xcschemes/DevNoise.xcscheme` -> OK.

### Failures / blocked validation
- Missing workflow file: `.github/workflows/release.yml` (FAIL).
- End-to-end release validation (codesign/notarize/staple with Apple credentials) not executable in this audit context (BLOCKED).

## 6) Behavioral Readiness Assessment (Inferred)

### Positive integration evidence
- Reducer/store/effects wiring is coherent for launch, playback, noise/depth/volume, hotkeys, remap state, and permission refresh:
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Reducer.swift`
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Store.swift`
- Audio transitions and stable graph topology are implemented:
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/Engine/TransitionController.swift`
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/Engine/EngineGraph.swift`
- Sleep/wake + route observer lifecycle hooks are connected in app delegate.

### Integration mismatches / gaps
- Panic hotkey path routes to `.togglePlayback`, not `.panicStop`:
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Store.swift:101-104`
- Green noise is not selectable in the app model/menu (`NoiseType` lacks `.green`), despite DSP/engine support and PRD requirements:
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/AppModel.swift:17-21`
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/Engine/EngineGraph.swift:127-142,317-326`
- `RemapCaptureManager` exists but is not integrated into runtime flow (AppDelegate uses separate NSEvent monitors):
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Hotkeys/Remap/RemapCaptureManager.swift`
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/AppDelegate.swift:84-99`

## 7) Manual Xcode Test Plan (Concise)

1. Launch behavior
- Launch app from Xcode.
- Verify no window, no Dock icon, and no sound for 10s.

2. Menu state updates
- Open menu, confirm status line updates between Stopped/Playing.
- Confirm permissions line reflects trust state.

3. Audio transitions
- Play -> verify fade-in (~120ms), no click.
- Stop -> verify fade-out (~120ms), no click.
- Switch noise repeatedly (including expected Green once exposed) -> verify crossfade (~150ms).
- Switch depth presets -> verify smooth ramp (50-150ms).
- Change volume presets rapidly -> verify smooth ramp (~50ms).

4. Hotkeys
- Verify all six defaults globally from another app.
- Specifically verify Panic performs immediate cut and state recovery.

5. Remap + permissions
- Without Accessibility: start remap; verify clear failure/status and settings action.
- Grant Accessibility; remap one action within 5s and verify hotkey re-registers.
- Validate timeout and Esc cancel behavior.

6. Sleep/wake and route change
- While playing, sleep then wake; verify recover/resume policy.
- While playing, change output route (speakers/headphones/Bluetooth); verify stability.

7. Release tooling smoke
- Run in order: `scripts/build_release.sh`, `scripts/codesign.sh`, `scripts/dmg_build.sh`, `scripts/notarize.sh`, `scripts/staple.sh`, `scripts/sha256.sh`, `scripts/verify_gatekeeper.sh` with valid credentials.
- Verify artifact names and Gatekeeper assessments.

## 8) Findings (Severity Ordered)

### P0

1. Missing required tag release workflow (Thread 09 failure)
- File evidence: missing `/Users/reecechallinor/Development/Projects/devnoise/.github/workflows/release.yml`.
- Command evidence:
  - Presence check output: `MISSING .github/workflows/release.yml`
  - `ls -la .github/workflows` shows only `ci.yml`
  - `git log --oneline --grep='t09'` returned no commit evidence.
- Impact: release automation acceptance criteria in `docs/tech.prd.md:913-917` are not met.

2. Green noise required by PRD/TECH_PRD is not exposed in app state/menu
- File evidence:
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/AppModel.swift:17-21` defines `NoiseType` as only `white`, `pink`, `brown`.
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/UI/MenuBuilder.swift:152-162` menu uses `NoiseType.allCases`, so Green cannot appear.
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Audio/Engine/EngineGraph.swift:127-142,317-326` includes internal green implementation.
- Command evidence:
  - `rg -n "case green|green" DevNoise/State DevNoise/UI DevNoise/Audio`
- Impact: fails PRD MVP scope (`docs/prd.md` noise types include White/Pink/Brown/Green).

### P1

3. Panic hotkey behavior is incorrect (soft toggle instead of hard panic)
- File evidence:
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Store.swift:101-104`
    - `.panicStop` hotkey path dispatches `.togglePlayback` when playing.
- Command evidence:
  - `nl -ba DevNoise/State/Store.swift`
- Impact: violates panic stop intent in PRD acceptance (`docs/prd.md:324,393`).

4. Canonical planning docs are missing in working tree
- File evidence: missing
  - `/Users/reecechallinor/Development/Projects/devnoise/next steps.md`
  - `/Users/reecechallinor/Development/Projects/devnoise/next-steps-master-merge.md`
- Command evidence:
  - `git status --short --branch` shows both as deleted.
  - `ls -l "next steps.md" next-steps-master-merge.md` returns "No such file or directory".
- Impact: required assessment references are absent from current checkout.

### P2

5. Remap capture core is implemented but not integrated
- File evidence:
  - Exists: `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Hotkeys/Remap/RemapCaptureManager.swift`
  - Runtime uses alternate capture path: `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/AppDelegate.swift:84-99`
- Command evidence:
  - `rg -n "RemapCaptureManager|RemapCaptureState|RemapCaptureError" DevNoise` only finds declarations, no runtime call-sites.
- Impact: architecture drift and duplicated capture logic increase maintenance and behavior divergence risk.

6. Version/documentation drift across runtime and site artifacts
- File evidence:
  - `/Users/reecechallinor/Development/Projects/devnoise/README.md:5-8` still labels "Phase 0 status".
  - `/Users/reecechallinor/Development/Projects/devnoise/site/index.html:26` shows `v0.3.0 (Phase 1)`.
  - `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Info.plist` + `/Users/reecechallinor/Development/Projects/devnoise/dist/latest.json` are `0.1.0`.
- Command evidence:
  - `nl -ba README.md`, `nl -ba site/index.html`, `plutil -p DevNoise/Info.plist`, `cat dist/latest.json`.
- Impact: operator/release confusion and potential mismatch in published expectations.

### P3

7. Build artifacts are committed/tracked in repository
- File evidence: tracked `.build/...` entries and commit `75366d4` touching 453 `.build` files.
- Command evidence:
  - `git ls-files` includes `.build/*`
  - per-commit summary shows `FILES_CHANGED 471` with `453 .build` in `75366d4`.
- Impact: repository noise, merge friction, and non-source churn.

## 9) Conflicts / Drift vs PRD, TECH_PRD, AGENTS
- `docs/prd.md` / `docs/tech.prd.md`: requires Green noise in MVP; app state/menu currently expose only three noise types.
- `docs/tech.prd.md`: requires release workflow on tags (`release.yml`); file is missing.
- `AGENTS.md`: canonical references include `next steps.md` and `next-steps-master-merge.md`; both are currently deleted in working tree.
- `docs/prd.md`: Panic Stop should be immediate; hotkey path performs toggle-based stop.

## 10) Blockers and Exact Remediation Actions
1. Add Green to app-level `NoiseType`, reducer/store/menu wiring, and persistence compatibility.
- Update `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/AppModel.swift`
- Validate menu exposure in `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/UI/MenuBuilder.swift`
- Re-run build + manual audio transition checks.

2. Correct panic dispatch path.
- Change `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/State/Store.swift` to dispatch `.panicStop` for `HotkeyAction.panicStop`.
- Verify immediate cut behavior in manual hotkey tests.

3. Implement Thread 09 release workflow.
- Add `/Users/reecechallinor/Development/Projects/devnoise/.github/workflows/release.yml` with `on: push: tags: v*` and script pipeline.
- Validate YAML and artifact upload contract (`DevNoise.dmg`, `.sha256`, `latest.json`).

4. Restore missing canonical planning docs in working tree.
- Restore `/Users/reecechallinor/Development/Projects/devnoise/next steps.md`
- Restore `/Users/reecechallinor/Development/Projects/devnoise/next-steps-master-merge.md`

5. Integrate remap core service to remove duplicate capture paths.
- Wire `/Users/reecechallinor/Development/Projects/devnoise/DevNoise/Hotkeys/Remap/RemapCaptureManager.swift` into app flow; retire redundant monitor logic in AppDelegate.

6. Complete manual Phase 1 QA in Xcode using `/Users/reecechallinor/Development/Projects/devnoise/docs/phase1-qa.md`, then update readiness.

## 11) Command Log Appendix (Commands + Key Outputs)

### Preflight
- `pwd` -> `/Users/reecechallinor/Development/Projects/devnoise`
- `git rev-parse --abbrev-ref HEAD` -> `main`
- `git status --short --branch` -> dirty (`.DS_Store` modified; two docs deleted)
- `git worktree list --porcelain` -> one active worktree at repo root
- `git branch -vv --all` -> only local `main`, remote `origin/master`
- loop `git show-ref` for `codex/t01..t10` -> all missing local/remote
- per-worktree status loop -> confirmed same dirty status in active worktree

### Canonical docs and planning files
- `wc -l AGENTS.md docs/prd.md docs/tech.prd.md CHANGELOG.md "next steps.md" next-steps-master-merge.md` -> two missing-file errors for next-step docs
- `ls -l "next steps.md" next-steps-master-merge.md` -> both missing
- `git show HEAD:"next steps.md" | sed -n ...` -> recovered canonical thread prompts from HEAD
- `git show HEAD:next-steps-master-merge.md | sed -n ...` -> recovered merge plan from HEAD

### Structure
- `ls -la` -> top-level inventory
- `git ls-files` -> 522 tracked files, includes `.build` and `dist`
- `find . -maxdepth 3 -type d | sort` -> directory inventory
- presence loop for required paths -> `release.yml` missing; both next-step docs missing in worktree

### Thread/merge evidence
- `git log --oneline --decorate --graph --max-count=80` -> merged thread history
- `git log --oneline --merges --decorate` -> no `t09` merge
- `git log --oneline --grep='t09'` -> no output
- commit file listings (`git show --name-only`) for `53ceac6`, `f6b2c4f`, `3afcf68`, `22317be`, `fe411fc`, `e83b9a1`, `1c978e3`, `75366d4`, `c55ff7d`

### Policy/search checks
- `rg -n "NSWindow|WindowGroup|NSPanel" DevNoise` -> no matches
- `rg -n "URLSession|NWConnection|http://|https://|analytics|telemetry..." DevNoise` -> no runtime network/telemetry matches
- `rg -n "inputNode|AVAudioRecorder|AVCaptureAudio|microphone" DevNoise` -> no matches
- `rg -n "UserDefaults|set\(|removeObject\(forKey" DevNoise` -> only `SettingsStore.swift`
- `rg -n "NSLog|print\(|os_log" DevNoise` -> logs only in AppDelegate/Store/HotkeyManager
- `rg -n "RemapCaptureManager|RemapCaptureState|RemapCaptureError" DevNoise` -> declaration-only references
- `rg -n "case green|green" DevNoise/State DevNoise/UI DevNoise/Audio` -> green in engine internals only

### Build/static validation
- `xcodebuild -project DevNoise.xcodeproj -list` -> success
- `xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build` -> `BUILD SUCCEEDED`
- `bash -n scripts/*.sh` -> success
- `ruby -ryaml -e "YAML.load_file(...)"` for `ci.yml` -> OK
- `if [[ -f .github/workflows/release.yml ]]; then ...` -> `release.yml MISSING`
- `plutil -lint DevNoise/Info.plist` -> OK
- `plutil -lint DevNoise.xcodeproj/xcshareddata/xcschemes/DevNoise.xcscheme` -> not plist-compatible check
- `xmllint --noout DevNoise.xcodeproj/xcshareddata/xcschemes/DevNoise.xcscheme` -> XML OK

### Artifact/release snapshot
- `ls -la dist && find dist -maxdepth 2 -type f | sort` -> DMGs + latest.json present
- `cat dist/latest.json` -> current metadata points to `0.1.0` / `DevNoise-0.1.0-1.dmg`

