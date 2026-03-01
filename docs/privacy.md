# Privacy

DevNoise Phase 0 privacy guarantees:

- No network calls from inside the app.
- No analytics or telemetry.
- No crash reporting or usage tracking.
- No microphone or audio input access.
- No key logging and no typed-content capture/storage.
- Only final hotkey chord bindings are persisted.
- Playback state is never persisted.

Persistence is restricted to an explicit UserDefaults whitelist documented in `AGENTS.md`.
