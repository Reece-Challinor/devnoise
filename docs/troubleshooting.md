# Troubleshooting

## App icon does not appear in menu bar
- Confirm the app is running from Xcode (`DevNoise` scheme).
- Ensure `LSUIElement` is set to `1` in the app Info.plist.

## Hotkeys do not trigger globally
- Phase 0 contains registration skeletons only; global handlers are not yet active.
- Verify bindings exist in menu `Shortcuts` section.

## Accessibility shows not granted
- Use the menu action that opens System Settings for Accessibility.
- Grant access manually, then re-open menu to refresh status.

## No sound plays
- Expected in Phase 0: audio engine methods are stubs and always silent.
