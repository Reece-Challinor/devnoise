# DevNoise Release Notes

## v0.1.0
Status: release candidate

- Reliable text `DN` menu-bar item with no Dock icon or runtime windows.
- Silent launch and lazy procedural audio for White, Pink, Brown, and Green noise.
- Three depth presets, volume controls, and six fixed permission-free global shortcuts.
- No in-app networking, telemetry, microphone input, typed-content handling, or playback
  persistence.
- Focused automated tests plus a manual release QA matrix in `docs/phase1-qa.md`.

## Download Contract

The `/download` redirect points to the latest GitHub Release asset:

`https://github.com/Reece-Challinor/devnoise/releases/latest/download/DevNoise.dmg`

Release jobs should upload a DMG artifact with exactly this asset name (`DevNoise.dmg`) so the
redirect always resolves to the latest signed/notarized package.
