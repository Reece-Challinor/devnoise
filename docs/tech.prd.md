# devnoise TECH.PR D (v0.1.0)
Tech PRD / build prompt for an AI coding agent

Version: 0.1.0  
Date: 2026-03-01  
Owner: Reece  
Status: Canonical technical scope for repo scaffolding + Phase 0/1 execution

---

## 0) What this file is

This document is the **first contextual prompt** an AI coding agent reads to build the devnoise repository from zero.

It translates `devnoise PRD (v0.3.0)` into an implementation-oriented plan:
- architecture
- module boundaries
- state machine
- hotkeys + permissions
- audio graph + click-free transition rules
- persistence schema
- build/sign/notarize/DMG pipeline
- hosting + download strategy
- Phase 0 and Phase 1 execution prompts

Hard constraints inherited from the product PRD:
- menu bar only, no windows
- silent on launch
- procedural audio only (no bundled loops)
- no network inside the app (distribution site can be online)
- no analytics, no telemetry, no microphone/audio input
- allow Accessibility permission (and possibly Input Monitoring) for global keyboard behavior
- no storing/transmitting typed content; capture is explicit and time-boxed for remapping

---

## 1) High-level implementation goal

Build a macOS menu-bar utility that:
- registers global hotkeys for Play/Stop, Panic Stop, noise selection, depth, volume
- generates continuous masking noise using `AVAudioEngine` and a procedural source
- supports click-free fades/crossfades and depth ramps without allocations in the render callback
- persists only whitelisted settings via `UserDefaults`
- ships as a Developer ID–signed, notarized app packaged in a DMG
- publishes DMG + checksum to a static download site (suggested: Vercel)

---

## 2) Platform + toolchain requirements

### 2.1 Xcode / Swift
- Swift 5.9+ (whatever ships with the active Xcode)
- macOS deployment target: set to a modern baseline (e.g., macOS 13+) unless you explicitly want older support

### 2.2 Frameworks
- AppKit: `NSStatusItem`, `NSMenu`, status bar lifecycle
- SwiftUI: optional for menu item views, but keep minimal (menu is the UI; no windows)
- AVFoundation: `AVAudioEngine`, `AVAudioSourceNode`, `AVAudioMixerNode`
- ApplicationServices: for Accessibility trust check `AXIsProcessTrustedWithOptions`  [oai_citation:0‡Apple Developer](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions?language=objc&utm_source=chatgpt.com)
- Carbon (optional): for global hotkeys via `RegisterEventHotKey` (old but common). Note: Carbon hotkey registration is often described as deprecated in community discussions.  [oai_citation:1‡GitHub](https://github.com/keepassxreboot/keepassxc/issues/3310?utm_source=chatgpt.com)

### 2.3 Security / distribution
- Developer ID signing and notarization are required for Gatekeeper-friendly distribution.  [oai_citation:2‡Apple Developer](https://developer.apple.com/developer-id/?utm_source=chatgpt.com)
- Notarization workflow should use Apple’s documented approach.  [oai_citation:3‡Apple Developer](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution?utm_source=chatgpt.com)

---

## 3) Repo structure (scaffold target)

Repo must be clean and boring. No magic.
# devnoise TECH.PR D (v0.1.0)
Tech PRD / build prompt for an AI coding agent

Version: 0.1.0  
Date: 2026-03-01  
Owner: Reece  
Status: Canonical technical scope for repo scaffolding + Phase 0/1 execution

---

## 0) What this file is

This document is the **first contextual prompt** an AI coding agent reads to build the devnoise repository from zero.

It translates `devnoise PRD (v0.3.0)` into an implementation-oriented plan:
- architecture
- module boundaries
- state machine
- hotkeys + permissions
- audio graph + click-free transition rules
- persistence schema
- build/sign/notarize/DMG pipeline
- hosting + download strategy
- Phase 0 and Phase 1 execution prompts

Hard constraints inherited from the product PRD:
- menu bar only, no windows
- silent on launch
- procedural audio only (no bundled loops)
- no network inside the app (distribution site can be online)
- no analytics, no telemetry, no microphone/audio input
- allow Accessibility permission (and possibly Input Monitoring) for global keyboard behavior
- no storing/transmitting typed content; capture is explicit and time-boxed for remapping

---

## 1) High-level implementation goal

Build a macOS menu-bar utility that:
- registers global hotkeys for Play/Stop, Panic Stop, noise selection, depth, volume
- generates continuous masking noise using `AVAudioEngine` and a procedural source
- supports click-free fades/crossfades and depth ramps without allocations in the render callback
- persists only whitelisted settings via `UserDefaults`
- ships as a Developer ID–signed, notarized app packaged in a DMG
- publishes DMG + checksum to a static download site (suggested: Vercel)

---

## 2) Platform + toolchain requirements

### 2.1 Xcode / Swift
- Swift 5.9+ (whatever ships with the active Xcode)
- macOS deployment target: set to a modern baseline (e.g., macOS 13+) unless you explicitly want older support

### 2.2 Frameworks
- AppKit: `NSStatusItem`, `NSMenu`, status bar lifecycle
- SwiftUI: optional for menu item views, but keep minimal (menu is the UI; no windows)
- AVFoundation: `AVAudioEngine`, `AVAudioSourceNode`, `AVAudioMixerNode`
- ApplicationServices: for Accessibility trust check `AXIsProcessTrustedWithOptions`  [oai_citation:0‡Apple Developer](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions?language=objc&utm_source=chatgpt.com)
- Carbon (optional): for global hotkeys via `RegisterEventHotKey` (old but common). Note: Carbon hotkey registration is often described as deprecated in community discussions.  [oai_citation:1‡GitHub](https://github.com/keepassxreboot/keepassxc/issues/3310?utm_source=chatgpt.com)

### 2.3 Security / distribution
- Developer ID signing and notarization are required for Gatekeeper-friendly distribution.  [oai_citation:2‡Apple Developer](https://developer.apple.com/developer-id/?utm_source=chatgpt.com)
- Notarization workflow should use Apple’s documented approach.  [oai_citation:3‡Apple Developer](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution?utm_source=chatgpt.com)

---

## 3) Repo structure (scaffold target)

Repo must be clean and boring. No magic.
devnoise/
README.md
LICENSE
AGENTS.md
docs/
prd.md                      # copy of devnoise PRD v0.3.0
tech.prd.md                 # this file
privacy.md                  # explicit privacy + permissions explanation
troubleshooting.md          # common issues (permissions, audio route)
DevNoise.xcodeproj/ or DevNoise.xcworkspace/
DevNoise/                     # app target sources
App/
DevNoiseApp.swift         # @main entry, app lifecycle
AppDelegate.swift         # NSApplicationDelegate, status item
StatusBar/
StatusBarController.swift
MenuBuilder.swift
MenuActionRouter.swift
Core/
AppState.swift            # state machine + reducers
Defaults.swift            # default settings + validation
Persistence/
SettingsStore.swift     # UserDefaults wrapper + keys
Hotkeys/
HotkeyModels.swift      # chord model + serialization
HotkeyManager.swift     # global hotkeys + dispatch
HotkeyCapture.swift     # listening mode capture (permission-gated)
Permissions/
PermissionsManager.swift
Accessibility.swift
InputMonitoring.swift   # if needed
Audio/
AudioEngineManager.swift
Noise/
NoiseSourceNode.swift
NoiseDSP.swift
NoiseTypes.swift
DepthProfiles.swift
GainEnvelope.swift
Routing/
RouteObserver.swift     # output device changes, interruptions
scripts/
build_release.sh
codesign.sh
notarize.sh
staple.sh
dmg_build.sh
verify_gatekeeper.sh
sha256.sh
.github/
workflows/
ci.yml
release.yml
site/                          # optional: static download site deployed on Vercel
vercel.json
public/
index.html
latest.json                # version metadata
release-notes.md
Notes:
- Keep app code in `DevNoise/` and avoid “helpers everywhere.”
- `AGENTS.md` is a strict instruction file for future agents working in this repo.

---

## 4) Architectural overview

### 4.1 The system is 5 subsystems
1) **Status/Menu UI**: builds the menu, shows current state, routes actions
2) **State Machine**: the single source of truth for “playing vs stopped,” current noise, depth, volume, and transient transitions
3) **Hotkeys**: global action triggers + in-menu remap capture
4) **Audio**: engine + procedural source + transitions (fade/crossfade/ramp)
5) **Distribution tooling**: scripts + CI to produce signed/notarized DMG and publish artifacts

Everything is driven by state + actions. The menu reflects state, and hotkeys dispatch actions.

---

## 5) App state machine (explicit)

### 5.1 State model
Use a simple, explicit state struct.

```swift
struct AppModel {
  var playback: PlaybackState
  var noiseType: NoiseType
  var depth: DepthPreset
  var volume: Float  // 0.0 - 1.0
  var permissions: PermissionsState
  var hotkeys: HotkeyBindings
  var tutorialDismissed: Bool
}

enum PlaybackState {
  case stopped
  case starting(startedAt: Date)
  case playing
  case stopping(startedAt: Date)
  case switchingNoise(from: NoiseType, to: NoiseType, startedAt: Date)
  case changingDepth(from: DepthPreset, to: DepthPreset, startedAt: Date)
  case engineRecovering(reason: String)
}
5.2 Action model
enum Action {
  case togglePlay
  case panicStop
  case setNoise(NoiseType)
  case cycleNoise
  case setDepth(DepthPreset)
  case cycleDepth
  case volumeUp
  case volumeDown
  case setVolume(Float)

  case openHelp
  case openPermissionsHelp
  case openSystemSettingsAccessibility
  case openSystemSettingsInputMonitoring

  case beginRemap(action: HotkeyAction)
  case cancelRemap
  case commitRemap(action: HotkeyAction, chord: HotkeyChord)

  case resetDefaults
  case quit

  // system events
  case audioRouteChanged
  case systemWillSleep
  case systemDidWake
  case audioEngineError(String)
  case permissionsChanged(PermissionsState)
}
enum Action {
  case togglePlay
  case panicStop
  case setNoise(NoiseType)
  case cycleNoise
  case setDepth(DepthPreset)
  case cycleDepth
  case volumeUp
  case volumeDown
  case setVolume(Float)

  case openHelp
  case openPermissionsHelp
  case openSystemSettingsAccessibility
  case openSystemSettingsInputMonitoring

  case beginRemap(action: HotkeyAction)
  case cancelRemap
  case commitRemap(action: HotkeyAction, chord: HotkeyChord)

  case resetDefaults
  case quit

  // system events
  case audioRouteChanged
  case systemWillSleep
  case systemDidWake
  case audioEngineError(String)
  case permissionsChanged(PermissionsState)
}
5.3 Transition rules (non-negotiable)
	•	Launch: always stopped and silent.
	•	togglePlay:
	•	stopped → starting → playing (after fade-in completes)
	•	playing → stopping → stopped (after fade-out completes)
	•	panicStop:
	•	any state → stopped immediately (hard cut, then reset engine state to safe stopped)
	•	setNoise(new):
	•	if stopped: set noiseType only (no audio)
	•	if playing: switch with crossfade (switchingNoise state)
	•	setDepth(new):
	•	if stopped: set depth only
	•	if playing: ramp EQ parameters or ramp gain shaping (changingDepth state)
	•	Any audio engine failure:
	•	transition to engineRecovering
	•	attempt restart and return to stopped (do not auto-play)

5.4 Timing constants (from PRD)
	•	fade in: 120ms
	•	fade out: 120ms
	•	crossfade: 150ms
	•	depth ramp: 50–150ms
	•	absolutely no pop/click

Implement as constants in one place:
AudioConstants.swift

⸻

6) Menu UI spec (exact labels)

Top-level menu structure (compact):
	1.	Play / Stop  (shows binding, e.g. “Play  ⌃⌘N”)
	2.	Noise ▸
	•	White
	•	Pink
	•	Brown
	•	Green
	3.	Depth ▸
	•	Normal
	•	Deep
	•	Super Deep
	4.	Volume ▸
	•	Volume Up
	•	Volume Down
	•	(optional) “Set to 25% / 50% / 75%”
	5.	Shortcuts ▸
	•	Cheat Sheet (disabled item with current mappings)
	•	Remap ▸
	•	Play/Stop…
	•	Panic Stop…
	•	Next Noise…
	•	Cycle Depth…
	•	Volume Up…
	•	Volume Down…
	•	(optional) “Reset Shortcuts to Defaults”
	6.	Reset to Defaults
	7.	Help ▸
	•	Why permissions are needed
	•	Privacy statement
	•	Troubleshooting
	8.	Quit

State indicator:
	•	Status bar icon changes between “stopped” and “playing”
	•	Also allow a disabled top menu line: “Status: Playing (Pink / Deep)” to remove ambiguity

No windows. No preference screens. No onboarding modal.

⸻

7) Hotkeys (defaults + rules)

7.1 Hotkey actions

Define these as canonical:
	•	Play/Stop toggle
	•	Panic Stop
	•	Next Noise (cycle)
	•	Depth Cycle
	•	Volume Up
	•	Volume Down
	•	(optional) Direct noise selection (White/Pink/Brown/Green)

7.2 Default mappings (chosen to avoid common conflicts)

These are the defaults the agent should implement, with validation to prevent conflicts inside devnoise.

Action
Default
Play/Stop
Control + Command + N  (⌃⌘N)
Panic Stop
Control + Command + Escape (⌃⌘⎋)
Next Noise
Control + Command + ] (⌃⌘])
Cycle Depth
Control + Command + [ (⌃⌘[)
Volume Up
Control + Command + = (⌃⌘=)
Volume Down
Control + Command + - (⌃⌘-)
Rationale:
	•	avoids Spotlight (⌘Space), Alfred/Raycast defaults, common IDE mappings
	•	avoids Option-only and Shift-only
	•	includes Control or Command as required

7.3 Validation rules (enforced on remap)
	•	chord must include Command or Control
	•	chord cannot be single key
	•	reject Option-only and Shift-only
	•	reject collisions with existing devnoise bindings
	•	warn (do not block) if the chord equals known “common conflicts” list

7.4 Two hotkey mechanisms (recommended)

To minimize continuous “keylogger vibe” while still allowing permission use:

Mechanism A (always-on core hotkeys): global hotkeys via RegisterEventHotKey (no event tap running continuously).
Mechanism B (permission-gated capture): event tap only during “Listening mode” for remapping, time-boxed to 5 seconds.

This matches the PRD requirement: explicit capture, time-boxed, no logging, and still allows Accessibility permission for other keyboard-driven features.

Note: Carbon hotkeys are often cited as “deprecated,” but they still work widely; the agent should isolate this behind HotkeyManager for future swaps.  ￼

⸻

8) Permissions strategy (Accessibility + Input Monitoring)

8.1 What’s required
	•	Accessibility permission is allowed and expected.
	•	Input Monitoring may be needed depending on how global key events are captured (event tap monitoring). The PRD allows it if needed.

Accessibility trust check:
	•	Use AXIsProcessTrustedWithOptions to check and optionally trigger the prompt.  ￼

8.2 Rule: never store typed content

Even when permissions are granted:
	•	do not write keystrokes to disk
	•	do not print keys to logs
	•	do not include typed content in crash reports
	•	capture only a chord for shortcut binding, then discard immediately

8.3 UX: how permissions are explained

Menu items under Help:
	•	“Why permissions are needed”
	•	“Privacy statement”

Menu items under Shortcuts:
	•	“Open System Settings for Accessibility…”
	•	“Open System Settings for Input Monitoring…” (only shown if needed)

Because Apple’s APIs don’t always deep-link cleanly across OS versions, implement:
	•	best-effort deep link
	•	fallback: open System Settings root Privacy & Security pane or show a small instruction text in menu help (still no windows)

(Deep linking is messy; keep this robust, not clever. Developer forum threads show this is a common pain point.)  ￼

8.4 When to request permission
	•	Do NOT request on launch.
	•	Request when user initiates an action that requires it:
	•	entering remap “Listening mode” (if using global event tap)
	•	enabling “extended keyboard features” (if later added)
	•	If permission missing, menu shows “Permissions: Not Granted” status and disables remap until granted.

⸻

9) Audio subsystem (most important technical detail)

9.1 Audio engine topology

Use AVAudioEngine with:
	•	AVAudioSourceNode generating the noise samples in real time
	•	a mixer chain that allows:
	•	volume control
	•	crossfade between two sources (for noise switching)
	•	depth shaping (EQ or filter shaping) with ramped parameter changes

Recommended topology:
SourceA (NoiseSourceNode) -> MixerA -> MasterMixer -> Output
SourceB (NoiseSourceNode) -> MixerB -> MasterMixer -> Output
	When switching noise type:
	•	configure SourceB to new noise
	•	start SourceB at 0 gain
	•	crossfade MixerA down while MixerB up over 150ms
	•	then swap roles (A becomes B) and stop the old node if desired

This avoids “reconfiguring a live node” mid-stream, which can cause clicks.

9.2 Procedural noise generation rules
	•	No audio files.
	•	No allocations in render callback.
	•	Use deterministic PRNG per channel:
	•	e.g., xorshift32 with two seeds for L/R
	•	White noise: uniform distribution [-1, 1]
	•	Pink noise: filtered white with stable filter (e.g., Paul Kellet style IIR or biquad chain)
	•	Brown noise: integrated white noise with leak to prevent drift
	•	Green noise: shape around mid frequencies (common approach: apply band-pass-ish shaping to white/pink)

Important: implement these as pure DSP structs with fixed-size state.

9.3 Depth presets (Normal / Deep / Super Deep)

Depth is spectral shaping for masking, not volume.

Implement depth as a small set of filter coefficient presets applied post-noise:
	•	Normal: mild shaping
	•	Deep: stronger low-mid emphasis
	•	Super Deep: strongest shaping

Depth changes must ramp 50–150ms (no sudden coefficient jumps). Options:
	•	interpolate filter coefficients over N frames
	•	or crossfade between two filter instances over N frames (safer)

9.4 Click-free fades/crossfades

The primary “no clicks” strategy:
	•	never hard-toggle node connections mid-render
	•	use gain envelopes with per-sample increments

Implement GainEnvelope:
	•	currentGain, targetGain, rampSamplesRemaining
	•	each render call updates the gain smoothly, multiplied into samples

For crossfade:
	•	one envelope for MixerA gain, one for MixerB gain

9.5 Volume

Volume is a separate master gain applied post-shaping.
	•	store 0.0–1.0
	•	step size (example): 0.05 per hotkey
	•	clamp [0, 1]
	•	volume changes can ramp over ~50ms to avoid zipper noise

9.6 Stereo decorrelation (avoid hard mono)

Simple and effective:
	•	use independent PRNG seeds per channel
	•	optionally add a tiny fractional delay or phase shaping, but avoid complexity

9.7 Route changes + sleep/wake

Implement observer:
	•	on output route change: keep playing if possible; if engine restarts, fade in cleanly
	•	on sleep: stop engine safely (fade out optional); store “wasPlayingBeforeSleep” only in memory (NOT persisted)
	•	on wake: if wasPlayingBeforeSleep, resume with fade-in; if errors occur, go to stopped

⸻

10) Persistence (UserDefaults keys)

Only whitelist keys:
hotkeys.playStop
hotkeys.panicStop
hotkeys.nextNoise
hotkeys.cycleDepth
hotkeys.volumeUp
hotkeys.volumeDown

audio.noiseType          # enum string
audio.depthPreset        # enum string
audio.volume             # float

ui.tutorialDismissed     # bool
Rules:
	•	never persist “isPlaying”
	•	reset defaults clears these keys and applies default bindings + audio settings

⸻

11) Logging + privacy posture (repo-level)

11.1 Logging
	•	Use os_log with a minimal subsystem/category.
	•	Never log keystrokes.
	•	Never log raw audio samples.
	•	Keep logs behind DEBUG where possible.

11.2 No network inside the app
	•	no update checks
	•	no telemetry
	•	no analytics
	•	no remote config

Hosting a DMG is external. The app remains offline.

⸻

12) Distribution: build, sign, notarize, DMG

12.1 Build pipeline overview

The repo must support:
	•	local release build to .app
	•	codesign .app with Developer ID
	•	notarize the signed .app (or DMG, depending on packaging)
	•	staple the notarization ticket
	•	package into DMG
	•	verify Gatekeeper acceptance

Apple’s notarization docs are the source of truth.  ￼
Developer ID signing overview.  ￼

12.2 Script responsibilities (in scripts/)
	•	build_release.sh
	•	builds Release using xcodebuild
	•	outputs build/DevNoise.app
	•	codesign.sh
	•	signs the .app with Developer ID Application
	•	enables hardened runtime
	•	verifies signature (codesign --verify --deep --strict)
	•	notarize.sh
	•	uses xcrun notarytool submit ... --wait
	•	stores log output for CI artifacts
	•	staple.sh
	•	xcrun stapler staple DevNoise.app (and DMG if desired)
	•	dmg_build.sh
	•	creates DevNoise.dmg with a predictable volume name
	•	includes /Applications symlink
	•	copies app into DMG
	•	sha256.sh
	•	generates DevNoise.dmg.sha256
	•	verify_gatekeeper.sh
	•	uses spctl --assess --type open --verbose DevNoise.app (and/or DMG)

12.3 CI release flow (GitHub Actions)

release.yml triggered on tag v*:
	•	build Release
	•	sign
	•	notarize
	•	staple
	•	build DMG
	•	compute sha256
	•	upload artifacts:
	•	DevNoise.dmg
	•	DevNoise.dmg.sha256
	•	latest.json (version metadata)

Even if DMG hosting is Vercel, GitHub Releases is a good durable artifact store; Vercel can redirect to it.

⸻

13) Hosting DMG “somewhere” (Vercel suggested)

13.1 Simple, modern approach

Use a tiny static download site deployed on Vercel that:
	•	serves a landing page
	•	exposes a stable URL like /download
	•	redirects /download to the latest DMG artifact location

Vercel supports redirects via vercel.json.  ￼

Recommended:
	•	https://devnoise.app/download → 308 redirect to a versioned artifact URL
	•	https://devnoise.app/latest.json → metadata including version, sha256, release notes

13.2 Where the DMG actually lives

Pick one of these (agent should implement option A by default):

A) GitHub Releases as origin (recommended default)
	•	Pros: reliable, versioned, integrates with CI
	•	Vercel site just redirects /download to the latest GitHub release DMG

B) Vercel Blob as origin
	•	Pros: single provider, easy link stability
	•	Cons: cost, operational details
	•	Still keep checksums and versioning

C) S3/R2 as origin
	•	Pros: cheapest/most scalable
	•	Cons: more infra

Agent default: A (GitHub Releases), plus Vercel redirect.

13.3 Best practices for downloads
	•	Always publish:
	•	DMG
	•	SHA-256 checksum file
	•	release notes
	•	latest.json metadata
	•	Make /download stable and never break it (redirect it)
	•	Prefer status code 308 for permanent redirect (Vercel docs recommend 307/308 to avoid ambiguity).  ￼

⸻

14) AGENTS.md (must exist day 0)

The agent must create AGENTS.md containing:
	•	“Do not add windows”
	•	“Do not add network”
	•	“Do not log keystrokes”
	•	“No allocations in render callback”
	•	“All audio transitions must be click-free”
	•	“All persisted keys must match whitelist”
	•	“Any permission prompt must be user-initiated”
	•	“Prefer deterministic, testable state machine; avoid ‘random side effects’”

Also include “how to run locally” and “how to build DMG release.”

⸻

15) Testing plan (Phase 1 minimum)

15.1 Manual test checklist
	•	launch: silent
	•	Play/Stop hotkey works with other apps focused
	•	Panic Stop always works and immediately silences audio
	•	noise switch crossfades without click
	•	depth change ramps without click
	•	volume change ramps without zipper noise
	•	sleep/wake behavior stable
	•	output device change stable (AirPods connect/disconnect)
	•	permissions missing:
	•	app still usable via menu
	•	remap disabled or prompts user
	•	no repeated nag prompts

15.2 Automated tests (keep minimal)
	•	unit tests for:
	•	hotkey serialization/deserialization
	•	state machine transitions
	•	persistence whitelist keys
	•	avoid heavy audio unit tests initially; focus on deterministic logic

⸻

16) Phase prompts for an AI coding agent

These are the exact “work prompts” to feed into the coding agent, in order.

⸻

Phase 0 Prompt (scaffold + spine)

Goal: create a compiling macOS menu-bar-only app repo with state machine, menu UI, settings persistence skeleton, hotkey skeleton, permissions checks skeleton, distribution scripts skeleton, and AGENTS.md. Audio can be stubbed (no sound) but architecture must be in place.

Prompt to agent (paste as-is):

PHASE 0: Build devnoise repo scaffolding and non-audio spine

You are building a macOS app called DevNoise from scratch in Swift using Xcode. The app is menu-bar only (no Dock icon, no windows). The menu is the UI. The app must launch silent and remain silent until user presses Play. Do not add any networking, analytics, telemetry, or microphone/audio input.

Create a GitHub-ready repository with this structure:
	•	README.md, LICENSE, docs/prd.md (copy summary), docs/tech.prd.md (reference), docs/privacy.md, docs/troubleshooting.md
	•	AGENTS.md (strict rules for future agents)
	•	DevNoise Xcode project with one macOS app target
	•	Source folders: App/, StatusBar/, Core/, Persistence/, Hotkeys/, Permissions/, Audio/, scripts/, .github/workflows/

Implement the following in Phase 0:
	1.	Menu-bar-only app shell

	•	Create NSStatusItem with an NSMenu.
	•	No windows. Do not create Settings scenes or any UI windows.
	•	Hide Dock icon: set LSUIElement in Info.plist.

	2.	State machine spine

	•	Implement AppModel, PlaybackState, NoiseType, DepthPreset.
	•	Implement Action enum.
	•	Implement a reducer function reduce(model:inout, action:) that updates state.
	•	Add an Action dispatcher that the menu and hotkeys call into.

	3.	Menu builder

	•	Build the menu exactly as specified:
	•	Play/Stop
	•	Noise submenu (White, Pink, Brown, Green)
	•	Depth submenu (Normal, Deep, Super Deep)
	•	Volume submenu (Up/Down)
	•	Shortcuts submenu (cheat sheet + Remap submenu)
	•	Reset to Defaults
	•	Help submenu (Why permissions, Privacy, Troubleshooting)
	•	Quit
	•	Menu items must reflect current state (checkmarks, title changes).
	•	Include a subtle status line: “Status: Stopped” / “Status: Playing (Noise / Depth)”.

	4.	Persistence skeleton

	•	Implement SettingsStore using UserDefaults.
	•	Create keys exactly from the whitelist:
	•	hotkeys.* (6 bindings)
	•	audio.noiseType, audio.depthPreset, audio.volume
	•	ui.tutorialDismissed
	•	Do not persist isPlaying.
	•	Implement Reset to Defaults: clears keys and restores default model values.

	5.	Hotkeys skeleton

	•	Define HotkeyAction enum and HotkeyChord model.
	•	Implement serialization (store chord in UserDefaults).
	•	Implement HotkeyManager with stubs:
	•	registerAll() and unregisterAll() compile but can be no-op in Phase 0.
	•	Dispatches actions to the reducer when hotkeys trigger.
	•	Set default mappings:
	•	Toggle Play: ⌃⌘N
	•	Panic Stop: ⌃⌘Esc
	•	Next Noise: ⌃⌘]
	•	Cycle Depth: ⌃⌘[
	•	Volume Up: ⌃⌘=
	•	Volume Down: ⌃⌘-
	•	Implement validation rules for remap (even if capture not implemented yet):
	•	requires Command or Control
	•	reject single-key
	•	reject Option-only, Shift-only
	•	reject collisions within devnoise

	6.	Permissions skeleton

	•	Implement PermissionsManager with:
	•	isAccessibilityTrusted() using AXIsProcessTrustedWithOptions
	•	a method to “request” accessibility (trigger prompt if possible)
	•	store a permissions state in the model
	•	Do not request permissions on launch.
	•	Add menu items under Help to explain permissions and open System Settings (best-effort).

	7.	Audio subsystem skeleton

	•	Create AudioEngineManager with methods:
	•	start() (should not play sound in Phase 0)
	•	stop()
	•	setNoiseType, setDepth, setVolume
	•	Wire Play/Stop actions to call audio manager, but keep it silent/stubbed (no engine start required yet).

	8.	Distribution scripts skeleton

	•	Add scripts: build_release.sh, codesign.sh, notarize.sh, staple.sh, dmg_build.sh, sha256.sh, verify_gatekeeper.sh
	•	Scripts can be placeholders but must include comments for required commands.

	9.	CI skeleton

	•	Add .github/workflows/ci.yml that builds the Xcode project on push.
	•	Add release.yml placeholder for tag builds.

Deliverables at the end of Phase 0:
	•	The app builds and runs, shows menu bar icon, menu works, state updates, persistence works.
	•	No audio output occurs.
	•	AGENTS.md exists and is strict.
	•	Scripts exist with clear TODOs.

Do not add extra features, windows, or network. Keep it minimal and correct.

⸻

Phase 1 Prompt (hotkeys + real audio + DMG release)

Goal: implement real procedural noise audio engine with click-free transitions, implement working global hotkeys, implement remap listening mode using permission-gated capture, and implement a real signing/notarization/DMG pipeline plus a simple Vercel site with /download redirect.

Prompt to agent (paste as-is):

PHASE 1: Implement real audio, hotkeys, remap capture, and release pipeline

Continue from the Phase 0 repo. Implement the actual devnoise MVP:

A) Audio engine (real)
	1.	Use AVAudioEngine with two AVAudioSourceNode noise generators (A and B) feeding two mixers into a master mixer.
	2.	Implement procedural noise generation:
	•	White: PRNG uniform
	•	Pink: IIR filtered white (stable, no allocations)
	•	Brown: integrated with leak (no drift)
	•	Green: shaped (band-pass-ish emphasis)
	3.	Implement Depth presets as spectral shaping (filters/EQ). Provide Normal/Deep/Super Deep. Depth change must ramp 50–150ms without clicks.
	4.	Implement transitions:
	•	Play fade-in ~120ms
	•	Stop fade-out ~120ms
	•	Noise switching crossfade ~150ms using A/B nodes and gain envelopes
	•	Volume change ramp ~50ms
	5.	Guarantee: no allocations in the render callback. All buffers and DSP state must be preallocated.
	6.	Stereo decorrelation: independent PRNG per channel.

B) Hotkeys (working)
	1.	Implement global hotkeys for the 6 default actions.
	2.	Prefer a mechanism that does NOT require continuous event taps for core hotkeys (e.g., RegisterEventHotKey), but keep the implementation isolated behind HotkeyManager.
	3.	Hotkeys must dispatch into the reducer and call AudioEngineManager accordingly.

C) Remap listening mode (permission-gated)
	1.	Implement menu-driven remapping:
	•	user selects “Remap Play/Stop…”
	•	app enters Listening mode for 5 seconds
	•	next chord captured becomes the new binding
	•	Esc cancels
	2.	Capture must be explicit and time-boxed.
	3.	Do not store or log raw keys. Only store final chord.
	4.	If the capture method needs Accessibility and/or Input Monitoring:
	•	do not prompt on launch
	•	when user enters listening mode, check trust; if missing, show menu status and provide “Open System Settings…” item
	5.	After remap, re-register hotkeys.

D) Route change + sleep/wake
	•	Implement RouteObserver to detect device changes.
	•	On change: keep audio stable; if engine restarts, fade in cleanly.
	•	On sleep: stop safely and remember “wasPlaying” only in memory.
	•	On wake: resume if wasPlaying, else remain stopped.

E) Distribution tooling (real)
	1.	Implement scripts for:
	•	xcodebuild release
	•	codesign with Developer ID (hardened runtime)
	•	notarize with notarytool (wait for result)
	•	staple
	•	build DMG (with Applications symlink)
	•	compute sha256
	•	spctl verify
	2.	Implement GitHub Actions release workflow on tag v* producing:
	•	DevNoise.dmg
	•	DevNoise.dmg.sha256
	•	latest.json (version metadata)
	3.	Add site/ static download site deployed on Vercel:
	•	index page with a Download button hitting /download
	•	/download is a redirect (308) to the latest artifact URL (default: GitHub Releases)
	•	include latest.json and release notes
	•	use Vercel redirect config in vercel.json

F) Docs
	•	Update docs/privacy.md to explicitly state:
	•	no network in app
	•	no analytics
	•	no microphone
	•	no keystroke logging or storage
	•	permissions are only used for shortcut binding and global control
	•	Update troubleshooting.md for:
	•	“No sound” cases
	•	“Hotkeys not working”
	•	“Permission not granted”

Acceptance criteria for Phase 1:
	•	App is silent on launch.
	•	Play/Stop starts/stops noise with click-free fades.
	•	Noise switching crossfades click-free.
	•	Depth switching ramps click-free.
	•	Hotkeys work globally.
	•	Remap works from the menu with time-boxed listening mode.
	•	DMG build + sign + notarize + staple pipeline works locally via scripts.
	•	Release workflow produces artifacts and the Vercel download page can point to them.

Do not add windows. Do not add network calls in the app. Do not add update mechanisms. Keep CPU low and avoid render allocations.

⸻

17) “Suspicious assumptions” (callouts for the agent)

These are common failure modes. The agent should treat them as hazards:
	•	“Accessibility alone is enough for all global capture.” Reality: Input Monitoring may still be required depending on capture method; design so core hotkeys can work without continuous capture, and only use capture in explicit listening mode.
	•	“Deep-linking to the exact System Settings pane will always work.” Reality: it’s inconsistent across OS versions; implement best-effort + fallback instructions.  ￼
	•	“Crossfading by reconnecting nodes is safe.” It’s not; do gain envelopes and keep topology stable.
	•	“UserDefaults is fine for anything.” It’s not; only store the whitelist (bindings + audio prefs). Apple notes it’s not for sensitive data.  ￼

⸻

18) Deliverable summary

When this tech PRD is followed, the repo should end Phase 1 with:
	•	a working menu-bar devnoise app
	•	global hotkeys + remap
	•	procedural white/pink/brown/green noise + depth presets
	•	click-free transitions and low overhead
	•	deterministic persistence behavior
	•	signed + notarized DMG artifacts
	•	a simple Vercel-hosted landing page with stable /download redirect  ￼