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