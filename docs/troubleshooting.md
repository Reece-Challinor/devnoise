# Troubleshooting

## App icon does not appear in menu bar

- Confirm the app process is running.
- If launched from Xcode, verify the `DevNoise` scheme is selected.
- Verify `LSUIElement = 1` in `DevNoise/Info.plist` so the app stays menu-bar only.

## No sound

- Confirm playback is started explicitly (launch is always silent and stopped).
- Verify output route in macOS Sound settings and test with another app.
- Check DevNoise volume and depth menu selections.
- Toggle Play/Stop once to force a clean fade cycle.
- If audio still fails after route changes, restart the app process.

## Hotkeys not working

- Confirm each binding includes at least Command or Control.
- Check for collisions with Spotlight, Raycast, Alfred, or system shortcuts.
- Rebind in `Shortcuts` and verify the updated chord appears in the menu.
- If permission-gated actions fail, review the permission section below.

## Permissions not granted

- DevNoise asks for permissions only when user actions require global control/remap behavior.
- Open the permission helper from the menu and grant access in System Settings.
- In macOS Privacy settings, toggle DevNoise off/on, then relaunch if state appears stale.
- If permissions were changed while DevNoise was open, quit and relaunch once to refresh trust.

## Remap timeout or collision

- Remap listening mode is time-boxed (5 seconds). Start remap again if it times out.
- Press Escape to cancel and return to the previous binding.
- If the candidate chord collides with another DevNoise action, choose a distinct binding.
- If macOS or another app intercepts the chord, select a less common combination.

## Notarization / Gatekeeper warnings

- Confirm the downloaded DMG is from the official release endpoint.
- Validate notarization and ticket stapling in release CI before publishing.
- If Gatekeeper blocks launch, remove old copies/quarantine metadata and re-download the latest
  signed artifact.
- Run `scripts/verify_gatekeeper.sh` during release validation and archive its output.
