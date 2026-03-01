# Privacy

DevNoise is built to be trustable by default. The app runtime is local-only and intentionally
minimal.

## Runtime Data and Network Behavior

- No network calls from inside the app runtime.
- No analytics, telemetry, or usage tracking.
- No crash reporting pipelines.
- No background upload services, daemons, or update checkers.

## Input and Audio Capture Guarantees

- No microphone or audio input access.
- No keystroke logging.
- No storage of raw typed content or key streams.
- During shortcut remap, only the final accepted key chord is persisted.

## Permissions Policy

- Permissions are requested only after explicit user action.
- Accessibility (and, if implementation requires it, Input Monitoring) is used only for
  global controls and remap flows.
- Permission prompts are never shown automatically on launch.

## Local Persistence Scope

- Playback state is never persisted.
- Persistence is restricted to the explicit UserDefaults whitelist documented in `AGENTS.md`.
