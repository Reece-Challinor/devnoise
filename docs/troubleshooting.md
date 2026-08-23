# Troubleshooting

## `DN` does not appear in the menu bar

- Confirm the `DevNoise` process is running and the `DevNoise` scheme was launched.
- Look for `DN` in the right side of the macOS menu bar. It may be hidden when the menu bar is
  crowded; quit another menu-bar app or widen the available space.
- Quit all running DevNoise processes, clean the Xcode build folder, and run again.
- DevNoise intentionally has no Dock icon or app window (`LSUIElement = 1`).

## No sound

- Launch is always silent. Click `DN` and choose Play, or press Control-Command-N.
- Raise DevNoise volume and confirm the selected output in macOS Sound settings.
- Stop and play once after changing or reconnecting an audio device.
- Quit and relaunch if macOS changed the output route while the app was running.

## A shortcut does not work

- The six shortcuts are fixed and cannot be remapped; see the table in `README.md`.
- Quit or reconfigure another app that owns the same shortcut, then relaunch DevNoise.
- DevNoise uses Carbon global hotkeys and should not request Accessibility, Input Monitoring,
  microphone, or other permissions.

## Settings seem wrong after relaunch

- Noise type, depth, and volume persist.
- Playback never persists: every launch starts stopped and silent.
- Quit DevNoise normally after changing a setting so the latest preference is saved.

## Release build is blocked by macOS

Run `scripts/verify_gatekeeper.sh` against the signed and notarized release artifact before
publishing it. Replace old local copies with the verified build.
