# **devnoise PRD (v0.3.0)**

Version: 0.3.0  
Date: 2026-02-27  
Owner: Reece  
Status: Draft, updated for direct distribution + Accessibility-based global input

## **First principles**

devnoise is a tiny tool with one job: start continuous masking noise instantly, tuned for people who live on the keyboard.

Core first-principles constraints:

1. **Flow first**: the fastest path from distraction to masking is a global shortcut, not nested system settings.  
2. **Minimal surface area**: menu bar only, no windows, no preference screens. The menu is the UI.  
3. **Silent by default**: launch must never produce sound. User must explicitly press Play.  
4. **Trust by construction**: no network, no analytics, no microphone, no tracking. Only local settings.  
5. **Click-free audio**: no pops, no glitches, no “why did my audio freak out?” moments.  
6. **Low overhead**: CPU and memory should be boringly small.

## **Change log (what changed since earlier constraints)**

Previous constraint: “No preferences persistence, no UserDefaults.”  
Updated requirement: **Persist a small whitelist**: hotkeys, noise type, depth. Settings are local-only. UserDefaults is acceptable. Note that Apple documents that UserDefaults stores settings on disk and is not meant for sensitive data. devnoise stores only shortcut bindings and audio preferences. ([Apple Developer](https://developer.apple.com/documentation/foundation/userdefaults?utm_source=chatgpt.com))

Previous constraint: “Mac App Store, sandboxed, App Review compliant.”  
Updated requirement: **Direct distribution** via **Developer ID–signed + notarized app**, packaged as a **DMG** (no Mac App Store).

Previous constraint: “Avoid user-facing permissions. Especially avoid Input Monitoring and Accessibility prompts unless proven unavoidable.”  
Updated requirement: **Accessibility permission is explicitly allowed and required** to support global keyboard-driven behavior beyond simple registered hotkeys (and **Input Monitoring may also be required** depending on the chosen event capture method). The product must still never transmit or store typed content.

---

## **1\) Problem statement**

macOS Background Sounds is functional but not designed for developers in flow:

* It’s hidden in system settings.
* It’s not designed to be toggled instantly via a global shortcut.
* It’s not customizable enough (noise types, depth shaping, hotkeys, etc.)
* It doesn’t “feel” like a tool built for people who live on the keyboard.

devnoise exists to solve: “I need masking noise now, without leaving my current app.”

---

## **2\) Goals and non-goals**

### **Goals**

* Start masking noise instantly with a global shortcut.
* Make it easy to switch noise type and depth from the keyboard.
* Be menu-bar only, no windows.
* Be silent on launch, always.
* Be trustable: no network, no tracking, no mic.

### **Non-goals**

* Streaming music, playlists, or ambient “soundscapes.”
* Recording, analyzing, storing, or transmitting user audio or typed content.
* A full preferences window or complex UI.
* Cloud sync or multi-device settings.

---

## **3\) Target user**

Primary user:

* Developer / knowledge worker
* Uses keyboard shortcuts constantly
* Wants “flow-friendly” masking noise without context-switching

Secondary user:

* Anyone who wants minimal, reliable masking noise they can toggle instantly

---

## **4\) MVP scope**

### **Noise types (MVP)**

* White
* Pink
* Brown
* Green

### **Depth presets (MVP)**

* Normal
* Deep
* Super Deep

Depth is spectral shaping for masking, not just “louder.”

### **Controls (must be keyboard-accessible)**

* Play/Stop toggle
* Panic Stop
* Noise selection
* Depth change (cycle or direct)
* Volume up/down
* Quit (menu at minimum; hotkey optional)

---

## **5\) Platform and distribution**

* Platform: macOS
* Language: Swift
* UI: SwiftUI + AppKit (status item / menu bar behavior via AppKit)
* Audio: AVAudioEngine, procedural generation only (no bundled loops)

Distribution:

* Direct download as **Developer ID–signed + notarized app**, packaged as a **DMG**
* Hardened runtime enabled
* Gatekeeper acceptance verified

---

## **6\) App form factor (hard)**

* **Menu bar only**
* **No Dock icon**
* **No user-facing windows**
* Menu structure should stay compact (use submenus)

---

## **7\) Persistence policy**

Allow minimal local persistence via UserDefaults for a strict whitelist:

* Hotkeys
* Noise type
* Depth preset
* Volume
* Tutorial dismissed flag

Rules:

* **Never persist Playing state**. Every launch starts stopped and silent.
* “Reset to Defaults” resets all persisted values.

---

## **8\) Interaction model**

### **8.1 Menu structure (shape spec)**

Keep top-level items ~6, use submenus.

Recommended top-level:

1. Play/Stop (shows shortcut)
2. Noise ▸
3. Depth ▸
4. Volume ▸
5. Shortcuts ▸ (cheat sheet + remap)
6. Reset to Defaults (or fold into Shortcuts)
7. Quit

### **8.2 State indicator**

Playing vs Stopped must be subtly visible (icon state or a menu line). No “invisible audio state.”

### **8.3 Tutorial/help**

* Tutorial never auto-shows.
* Help is accessible from the menu at all times.

### **8.4 Hotkey design rules (critical)**

Defaults must avoid common conflicts.

Validation rules:

* Must include Command or Control
* No single-key triggers
* Reject Option-only and Shift-only shortcuts
* Prevent collisions within devnoise actions
* Warn (don’t block) about common external conflicts (Raycast/Alfred/Spotlight)

### **8.5 Hotkey capture UX (no windows)**

Remapping and extended keyboard features are allowed to require **Accessibility** (and may require **Input Monitoring** depending on the implementation). The app must clearly explain why permissions are needed and must never store or transmit typed content.

Remap flow inside menu:

1. User selects: Shortcuts > Remap “Play/Stop”
2. Menu enters “Listening mode” for 5 seconds
3. Next key chord pressed becomes the binding
4. Esc cancels
5. Result is shown immediately in the menu

Privacy guardrails:

* Capture is only active during explicit “Listening mode” (time-boxed).
* Do not record, store, or log raw keystrokes or sequences.
* Persist only the final shortcut binding (and only within the persistence whitelist).

---

## **9\) Audio behavior targets**

* Play fade-in: ~120 ms
* Stop fade-out: ~120 ms
* Noise switching: crossfade ~150 ms
* Depth change: ramp 50–150 ms
* No allocations in the audio render callback.

Notes:

* Audio must be click-free during all transitions.
* Noise generation must be procedural only (no audio files).

---

## **10\) Performance budgets**

* CPU while playing: <1% avg, <2% peak (Apple Silicon steady-state)
* Memory: <50 MB RSS

---

## **11\) Privacy, permissions, and trust**

### **11.1 Trust constraints (hard)**

* No network access
* No analytics / telemetry
* No microphone / audio input
* No tracking

### **11.2 Permissions posture**

devnoise may require system permissions (Accessibility, and possibly Input Monitoring) for global keyboard-driven behavior beyond basic registered hotkeys.

Requirements:

* Explain “why” clearly and succinctly in the menu (Help).
* Fail safe: if permissions are denied, core audio control via menu must still work.
* Never store or transmit typed content.

### **11.3 Security and privacy**

Hard constraints:

* No network access.  
* No analytics.  
* No telemetry.  
* No microphone, no audio input.

Keyboard privacy constraints:

* Even if the app uses Accessibility/Input Monitoring APIs, it must **never** store, transmit, or log typed content.
* Shortcut capture must be **explicit**, time-boxed, and only used to bind configured actions.

UserDefaults usage:

* Only store the persistence whitelist.  
* Do not store sensitive information. Apple notes UserDefaults is not encrypted and not for sensitive data. ([Apple Developer](https://developer.apple.com/documentation/foundation/userdefaults?utm_source=chatgpt.com))

---

## **12\) Distribution + permissions readiness (Direct download)**

### **12.1 Permissions strategy**

Goal: keep permissions understandable and defensible.

Required:

* **Accessibility permission** is required to support advanced global keyboard-driven features beyond simple registered hotkeys.

May be required (implementation-dependent):

* **Input Monitoring** permission if the chosen capture method relies on monitoring keyboard events outside the app.

Rules:

* The app must never store or transmit typed content.
* Permission-gated behavior must fail safe:
  * If permissions are not granted, show clear status in the menu and keep core audio controls usable.
  * “Play/Stop” via menu must always work.
* Provide menu items:
  * Help > “Why permissions are needed”
  * Shortcuts > “Open System Settings to grant permissions…”

Known platform risk:

* macOS reports indicate Option-only global hotkeys can fail depending on API usage. Avoid Option-only defaults and reject Option-only remaps. ([GitHub](https://github.com/sindresorhus/KeyboardShortcuts/issues/176?utm_source=chatgpt.com))

### **12.2 Signing, notarization, and packaging**

Distribution requirements:

* Build a **Developer ID–signed** app
* Enable hardened runtime
* **Notarize** the app
* Package as a **DMG**
* Verify Gatekeeper acceptance on a clean machine/user account

### **12.3 Privacy disclosures (non–App Store)**

Even without App Store privacy labels, devnoise must be explicit in-app:

* “No network”
* “No analytics”
* “No microphone”
* “No keystroke logging or storage”
* Explain what Accessibility/Input Monitoring enables and what devnoise does **not** do

---

## **13\) Acceptance criteria**

Core behavior:

* App launches with no sound. Always.  
* Play hotkey starts noise within 200 ms perceived latency.  
* Stop and Panic Stop stop noise quickly without pops.
* If playing, sleep/wake and output route changes attempt to resume with a fade-in (fail safe to Stopped if resume fails).

Audio quality:

* Switching noise type produces no audible click.  
* Switching depth produces no audible click.  
* Stereo output is mildly decorrelated (not hard-mono).

Keyboard:

* Hotkeys work while focus is in other apps.  
* Remapping works via menu “listening mode”. If required permissions are not granted, the menu shows clear status and remapping is disabled until granted.  
* Hotkeys persist across app relaunch.  
* Reset to Defaults resets hotkeys and audio settings, and the next launch is silent.

UI:

* Menu is compact, readable, and stays within the “few items + submenus” pattern.  
* Playing state is visible but subtle.

Performance:

* CPU and memory meet budgets during 30 minutes steady playback.  
* No runaway CPU when rapidly changing settings.

Permissions + privacy:

* No network calls.  
* No microphone access.  
* If Accessibility/Input Monitoring are used, devnoise does not store or transmit typed content.
* If permissions are not granted, the app remains usable via menu controls and shows clear permission status.

---

## **14\) Open questions**

* Exact default hotkey map (must avoid common conflicts).
* Exact depth shaping curves (Normal/Deep/Super Deep).
* Whether to decorrelate channels via delay, filtering, or PRNG offset.

---

## **15\) Milestones**

M1: Hello world menu bar app, no Dock icon, no windows  
M2: Audio engine procedural white noise + click-free play/stop  
M3: Noise types + depth presets + crossfade/ramping  
M4: Hotkeys + remap UX + persistence whitelist  
M5: Sleep/wake + route change handling + panic stop robustness  
M6: Direct distribution polish (icon, DMG packaging, Developer ID signing, notarization, Gatekeeper validation)

---

## **Pushback**

Most likely failure: trust collapse. Requesting Accessibility/Input Monitoring without extremely tight scope, clear UX copy, and strict “no typed content stored/transmitted” guarantees will make the app feel spyware-adjacent.

Most suspicious assumption: “no windows” plus “remap hotkeys” will be painless. It can be done, but only if remapping requires the menu to be open and capture is time-boxed and explicit.

Biggest distribution risk: shipping a DMG that fails notarization/Gatekeeper checks and turns into support hell.

Simplest validation experiment: implement (1) the permission-gated key capture path with zero logging/storage, and (2) the notarize + staple + Gatekeeper verify path, before building the rest of the app.

---

## **16\) Appendix: Reference behaviors**

* Silent on launch means no audio device wake-up pops.
* Panic Stop must cut audio immediately and reset internal state.
* “Reset to Defaults” must:
  * Clear whitelist keys
  * Restore default hotkeys/noise/depth/volume/tutorial flag
  * Leave app in Stopped state