# DevNoise Product Specification

Status: current canonical scope

## Product

DevNoise is a tiny macOS menu-bar utility that starts continuous masking noise without pulling
the user out of their work. It is designed for keyboard-first use and does one job well.

## Required behavior

- Support macOS 13 or later.
- Show a reliable text status item: `DN` while stopped and `DN•` while playing.
- Run as an accessory app with no Dock icon, windows, onboarding, or preferences screen.
- Install the menu-bar item immediately, then launch stopped and silent.
- Create the audio engine only after the user explicitly starts playback.
- Generate all sound procedurally and locally: White, Pink, Brown, and Green noise.
- Offer Normal, Deep, and Super Deep spectral presets.
- Provide Play/Stop, immediate Panic Stop, noise, depth, volume, reset, and quit controls.
- Fade playback and configuration changes so normal use has no clicks or pops.

Defaults are Pink noise, Deep depth, 60% volume, and stopped playback.

## Keyboard controls

The six global shortcuts are fixed. They use Carbon registered hotkeys, require no system
permission, and have no remapping flow.

| Action | Shortcut |
| --- | --- |
| Play / Stop | Control-Command-N |
| Panic Stop | Control-Command-Escape |
| Next Noise | Control-Command-] |
| Cycle Depth | Control-Command-[ |
| Volume Up | Control-Command-= |
| Volume Down | Control-Command-- |

If another app owns a shortcut, DevNoise reports the unavailable shortcut count in its menu;
all menu controls remain usable.

## Menu

The menu contains only current status, actionable audio errors or shortcut conflicts,
Play/Stop, Panic Stop, Noise, Depth, Volume, a read-only shortcut reference, Reset to Defaults,
and Quit.

## Persistence

Only noise type, depth, and volume are actively saved in local `UserDefaults`. Playback and
transient errors are never saved. Every process launch starts stopped and silent, including
after quitting while audio is playing. Reset restores the defaults above.

## Trust requirements

- No network calls, analytics, telemetry, update checks, or background services.
- No microphone or audio input.
- No keyboard monitoring, shortcut capture, or typed-content handling.
- No permission prompts.
- No third-party dependencies.

## Non-goals

No sound files, streaming, playlists, accounts, cloud sync, recording, visualization,
custom shortcuts, launch-at-login helper, Dock UI, or general-purpose settings UI.

## Release acceptance

A release candidate is acceptable when Debug tests pass, Release builds successfully, the
manual checklist in `docs/phase1-qa.md` passes, and the distributed app is Developer ID signed,
notarized, and accepted by Gatekeeper.
