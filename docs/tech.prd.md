# DevNoise Technical Specification

Status: current canonical architecture

## Platform and dependencies

- Native Swift macOS app, deployment target macOS 13.
- AppKit for lifecycle and the status menu.
- AVFoundation for procedural audio output.
- Carbon `RegisterEventHotKey` for fixed global shortcuts.
- Foundation and Darwin for local state and low-level atomic publication.
- No third-party packages, networking, microphone input, or permission APIs.
- `LSUIElement = 1` and accessory activation policy enforce menu-bar-only operation.

## Runtime structure

The app target intentionally has six source files:

| File | Responsibility |
| --- | --- |
| `AppDelegate.swift` | Owns lifecycle and coordinates menu, settings, hotkeys, and lazy audio |
| `State/AppModel.swift` | Defines the small value model, defaults, and cycle/volume helpers |
| `UI/StatusBarController.swift` | Owns the `DN` status item and builds the AppKit menu |
| `Hotkeys/HotkeyManager.swift` | Registers and dispatches the six fixed Carbon hotkeys |
| `Persistence/SettingsStore.swift` | Loads, validates, saves, migrates, and resets audio preferences |
| `Audio/AudioEngineManager.swift` | Owns the lazy engine, source renderer, DSP, transitions, and recovery |

There is no reducer framework, remapping subsystem, permissions manager, app window, or
separate DSP object graph.

## Launch and command flow

1. `AppDelegate` switches the process to accessory mode.
2. It creates and retains `StatusBarController` first so `DN` is visible immediately.
3. It loads the three saved audio preferences into a stopped model.
4. It registers the fixed shortcuts and displays a count if any registration fails.
5. Menu commands and hotkeys call the same small set of main-thread command handlers.
6. The first Play command constructs `AudioEngineManager`; no audio engine exists before that.

An audio start or recovery failure leaves the model stopped and places a concise error in the
menu. Menu controls continue working when hotkey registration fails.

## State and persistence

`AppModel` contains only playback, selected noise, selected depth, volume, a transient audio
error, and the transient unavailable-hotkey count. Defaults are stopped, Pink, Deep, and 0.6.

Current persistence writes exactly:

- `audio.noiseType`
- `audio.depthPreset`
- `audio.volume`

Values are validated on load, volume is clamped to `0...1`, and legacy depth values are
migrated. Playback, errors, and hotkey availability never persist. Reset removes every key in
the repository persistence whitelist without touching unrelated defaults.

## Hotkeys

`HotkeyAction` supplies stable identifiers, labels, key codes, and display strings for the six
shortcuts defined in `docs/prd.md`. `HotkeyManager` installs one Carbon dispatcher handler,
registers each Control-Command chord, routes recognized identifiers, and unregisters everything
on teardown. It does not install event taps, observe arbitrary keys, or request Accessibility or
Input Monitoring access.

## Audio

The first Play builds one `AVAudioEngine` graph with a 48 kHz stereo `AVAudioSourceNode`
connected to the main mixer. The render path produces independent left and right procedural
samples with a local xorshift generator and small filter state for White, Pink, Brown, and Green
noise.

Normal, Deep, and Super Deep select fixed spectral-shaping parameters. Two preallocated voices
crossfade configuration changes over 150 ms. A 120 ms gain ramp handles play, stop, and volume
changes. Normal Stop pauses the engine after its fade; Panic Stop stops it immediately and marks
the renderer for a fresh silent start.

Render-thread targets are published as atomic integers. The render callback must not allocate,
lock, perform file or network I/O, call Objective-C APIs, or block. Engine configuration changes
and wake events attempt recovery only when playback was active; failure returns to stopped and
never auto-plays later.

## Verification and release

`DevNoiseTests` covers model defaults and cycling, persistence boundaries, stable shortcuts, and
visible status-item text. CI runs the Debug test action and a Release build with signing disabled.
Distribution builds use the repository scripts for Developer ID signing, notarization, DMG
packaging, checksums, and Gatekeeper verification.
