# DevNoise Release Notes

## v0.3.0 (Phase 1)
Date: 2026-03-01

- Menu-bar-only runtime with no Dock icon and no runtime windows.
- Silent-on-launch behavior remains enforced (no auto-play).
- Procedural noise architecture only (no bundled loop assets).
- Privacy guardrails remain explicit: no in-app networking, no analytics/telemetry, no
  microphone/audio input, no typed-content storage.
- Phase 1 manual QA matrix is documented in `docs/phase1-qa.md`.

## Download Contract

The `/download` redirect points to the latest GitHub Release asset:

`https://github.com/Reece-Challinor/devnoise/releases/latest/download/DevNoise.dmg`

Release jobs should upload a DMG artifact with exactly this asset name (`DevNoise.dmg`) so the
redirect always resolves to the latest signed/notarized package.
