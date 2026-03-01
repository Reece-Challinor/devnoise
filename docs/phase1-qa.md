# Phase 1 QA Matrix

This checklist is for manual Phase 1 verification of runtime behavior, hotkeys/remap, routing,
and release artifacts.

## Test Environment

- macOS version under test
- Build type (Debug or Release)
- Audio output route (built-in, wired, Bluetooth)
- Permission state before run (none, Accessibility granted, Input Monitoring granted)

## Manual Matrix

| ID | Area | Preconditions | Steps | Expected Result |
| --- | --- | --- | --- | --- |
| QA-001 | Launch silence | Fresh launch | Launch app and do nothing for 10s | No audio output on launch; app starts in stopped state |
| QA-002 | Play fade-in | App stopped | Trigger Play from menu | Audio starts with smooth fade-in (~120 ms) and no click/pop |
| QA-003 | Stop fade-out | App playing | Trigger Stop from menu | Audio stops with smooth fade-out (~120 ms) and no click/pop |
| QA-004 | Noise crossfade | App playing | Switch noise type repeatedly (White/Pink/Brown/Green) | Noise transition crossfades (~150 ms) without discontinuity |
| QA-005 | Depth ramp | App playing | Cycle depth preset Normal -> Deep -> Super Deep | Spectral depth changes ramp cleanly (50-150 ms), no abrupt jumps |
| QA-006 | Global Play/Stop hotkey | Hotkey bound and permissions granted as required | Trigger Play/Stop via global hotkey from another app | Playback toggles correctly while DevNoise menu remains hidden/inactive |
| QA-007 | Panic Stop hotkey | App playing, panic hotkey bound | Trigger Panic Stop from another app | Playback stops immediately and state reflects stopped |
| QA-008 | Remap success path | Shortcuts menu open | Start remap for one action and press valid chord within timeout | New chord is accepted and shown immediately in menu |
| QA-009 | Remap timeout/cancel path | Shortcuts menu open in listening mode | Wait >5s without chord, then retry and press Escape | Timeout leaves previous binding unchanged; Escape cancels safely |
| QA-010 | Remap collision handling | Two actions have existing chords | Attempt to bind second action to already-used chord | Collision is rejected or surfaced; prior stable bindings remain intact |
| QA-011 | Sleep/wake behavior | App playing | Put Mac to sleep, wake, observe playback state | No crashes/hangs; playback state recovers according to intended policy |
| QA-012 | Output route change | App playing | Change output route (e.g., speakers -> headphones -> Bluetooth) | Audio pipeline remains stable and click-free after route transition |
| QA-013 | Release artifact redirect | Release published with `DevNoise.dmg` | Open site `/download` endpoint | Permanent redirect resolves to latest GitHub release DMG asset |
| QA-014 | Gatekeeper verification | Release DMG downloaded | Open DMG, launch app, and run `scripts/verify_gatekeeper.sh` | Signed/notarized app launches without trust-blocking failures |

## Sign-off Template

- Tested by:
- Date:
- Environment:
- Cases passed:
- Cases failed:
- Follow-up issues:
