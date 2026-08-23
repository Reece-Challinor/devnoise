# Privacy

DevNoise runs locally and produces audio output only.

## Data and network

- No network calls, analytics, telemetry, tracking, crash uploads, or update checks.
- No accounts, cloud sync, daemons, launch agents, or background services.
- No microphone or audio input. Generated sound is never recorded or saved.

## Keyboard input and permissions

- DevNoise registers six fixed Carbon hotkeys and receives only those shortcut actions.
- It does not monitor general keyboard input, capture shortcuts, or support remapping.
- It never reads, logs, stores, or transmits typed content.
- It requests no Accessibility, Input Monitoring, microphone, or other system permission.

## Local settings

The runtime saves only these non-sensitive `UserDefaults` values:

- `audio.noiseType`
- `audio.depthPreset`
- `audio.volume`

Playback state, errors, shortcut activity, and usage history are never persisted. Reset removes
DevNoise's approved preference keys and leaves unrelated defaults untouched.
