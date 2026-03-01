# Changelog

All notable changes to this project will be documented in this file.

## [1.0] - 2026-03-01

### Added
- Bootstrapped `DevNoise` as a macOS menu-bar-only app with no windows and no Dock icon.
- Added deterministic state architecture (`AppModel`, `Action`, reducer, `Store`) with side-effect isolation.
- Added menu shell with dynamic status line, Play/Stop toggle, Noise/Depth/Volume menus, Shortcuts, Reset, Help, and Quit.
- Added `SettingsStore` with strict UserDefaults whitelist and reset-to-defaults support.
- Added hotkey domain models and validation rules with default chords and registration skeleton.
- Added `PermissionsManager` skeleton for Accessibility trust checks, explicit prompt flow, and Settings deep links.
- Added `AudioEngineManager` skeleton methods (`start`, `stop`, `panicStop`, setters) that remain silent in Phase 0.
- Added release pipeline script placeholders for build/sign/notarize/staple/DMG/checksum/Gatekeeper verification.
- Added GitHub Actions CI workflow to build the Xcode project on push and pull request.
- Added project docs: PRD copies, technical PRD copy, privacy guarantees, troubleshooting skeleton, and operational AGENTS rules.

### Security & Privacy
- No network calls, no analytics/telemetry, no microphone input, and no key logging implemented.
- Persistence constrained to approved settings keys; playback state is never persisted.
