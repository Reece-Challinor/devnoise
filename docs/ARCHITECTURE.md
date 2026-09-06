# Architecture

DevNoise is one AppKit process with six production Swift files and no external packages.

```text
AppDelegate
├── StatusBarController ── menu commands ──┐
├── HotkeyManager ─────── global commands ├── AppModel
├── SettingsStore ─────── allowed defaults┘      │
└── AudioEngineManager ◀── procedural settings ──┘
```

- `AppDelegate.swift` starts the accessory app and wires dependencies. It installs the status item first and never starts audio on launch.
- `AppModel.swift` owns the small value-state model and command transitions.
- `StatusBarController.swift` renders the AppKit menu and native template icon.
- `SettingsStore.swift` reads and writes only noise, depth, and volume.
- `HotkeyManager.swift` registers six fixed Carbon hotkeys without accessibility permission.
- `AudioEngineManager.swift` lazily owns AVAudioEngine and generates samples in its render callback.

The app has no runtime windows, network layer, microphone path, analytics, updater, or background service. Audio state flows from explicit menu or hotkey commands into the model, then to the engine and menu. Playback is intentionally excluded from persistence.

## Audio thread

The render callback uses precomputed scalar state and performs no allocation, locking, Objective-C calls, file or network I/O, or blocking work. Changes to audio code must preserve that boundary.
