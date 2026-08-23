# Minimal App QA

Use this checklist on both a Debug build and the final signed Release build.

| ID | Check | Expected result |
| --- | --- | --- |
| QA-01 | Launch DevNoise | `DN` appears in the menu bar; no window, Dock icon, audio, or permission prompt appears |
| QA-02 | Open the `DN` menu | Play, four noise choices, three depth choices, volume controls, shortcuts, and Quit are available |
| QA-03 | Choose Play, then Stop | Audio starts on demand and both transitions are clean; launch itself did not initialize audible playback |
| QA-04 | Select White, Pink, Brown, and Green while playing | Every procedural noise plays and switching does not click, stall, or crash |
| QA-05 | Select Normal, Deep, and Super Deep while playing | Each preset changes the tone cleanly |
| QA-06 | Change volume through its full range | Output changes predictably, remains bounded, and mute produces silence |
| QA-07 | Use Control-Command-N and Control-Command-Escape from another app | Play/Stop toggles globally; Panic Stop silences immediately |
| QA-08 | Use Control-Command-], Control-Command-[, Control-Command-=, and Control-Command-- | Noise, depth, volume up, and volume down work globally |
| QA-09 | Relaunch after changing noise, depth, and volume while playing | Those three audio preferences return, but playback starts stopped and silent |
| QA-10 | Sleep/wake and change audio output while playing | App remains responsive; stopping and restarting playback restores output if needed |
| QA-11 | Inspect normal use | No remapping UI, permission request, network traffic, microphone use, or stored playback state exists |
| QA-12 | Launch the signed/notarized artifact | Gatekeeper accepts it and `DN` appears with the same silent behavior |

Record the macOS version, hardware, output device, build identifier, failures, and tester for
each release candidate.
