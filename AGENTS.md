# Repository guardrails

These rules apply to every contribution.

## Product contract

- Keep DevNoise menu-bar only, with no runtime windows or Dock icon (`LSUIElement = 1`).
- Launch silently. Audio starts only after an explicit Play command.
- Generate audio procedurally and locally. Do not add audio files.
- Do not add in-app network calls, analytics, telemetry, accounts, microphone input, update checkers, daemons, launch agents, or background services.
- Do not request permissions or capture, log, store, or transmit typed content.
- Keep the six fixed Carbon hotkeys. Do not add keyboard monitoring or remapping.
- Do not add third-party dependencies.

## Data and real-time safety

Only these `UserDefaults` keys are allowed:

- `audio.noiseType`
- `audio.depthPreset`
- `audio.volume`

Playback state must never persist. The audio render callback must not allocate memory, lock, perform file or network I/O, call Objective-C APIs, or block.

## Verify changes

Run `make verify`. Audio or lifecycle changes also need the [manual QA checklist](README.md#manual-qa).

## Documentation

- Begin every Swift source file with a one-line purpose and `SPDX-License-Identifier: MIT`.
- Document public Swift boundaries with concise `///` comments.
- Keep contributor, architecture, security, and release guidance in `README.md`.
- Use GitHub Releases for version history; do not add a standalone changelog.
