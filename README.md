<div align="center">
  <img src="site/assets/devnoise-preview.svg" alt="DevNoise — procedural focus noise for macOS" width="100%">

  <p>
    <a href="https://github.com/Reece-Challinor/devnoise/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/Reece-Challinor/devnoise/actions/workflows/ci.yml/badge.svg"></a>
    <a href="https://github.com/Reece-Challinor/devnoise/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/Reece-Challinor/devnoise?display_name=tag&sort=semver"></a>
    <a href="https://github.com/Reece-Challinor/devnoise/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/Reece-Challinor/devnoise/total"></a>
    <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/github/license/Reece-Challinor/devnoise"></a>
    <a href="https://www.linkedin.com/in/reecechallinor/"><img alt="Reece Challinor on LinkedIn" src="https://img.shields.io/badge/LinkedIn-Reece_Challinor-0A66C2?logo=linkedin"></a>
  </p>
</div>

DevNoise is a tiny, keyboard-first procedural noise app for the macOS menu bar. It has no windows, Dock icon, accounts, analytics, microphone access, or in-app network calls.

## Install

[Download the latest DMG](https://github.com/Reece-Challinor/devnoise/releases/latest/download/DevNoise.dmg), open it, and drag DevNoise to Applications. DevNoise requires macOS 13 or later and supports Apple silicon and Intel Macs.

## Controls

| Action | Shortcut |
| --- | --- |
| Play / Stop | <kbd>Control</kbd> <kbd>Command</kbd> <kbd>N</kbd> |
| Panic Stop | <kbd>Control</kbd> <kbd>Command</kbd> <kbd>Escape</kbd> |
| Next Noise | <kbd>Control</kbd> <kbd>Command</kbd> <kbd>]</kbd> |
| Cycle Depth | <kbd>Control</kbd> <kbd>Command</kbd> <kbd>[</kbd> |
| Volume Up | <kbd>Control</kbd> <kbd>Command</kbd> <kbd>=</kbd> |
| Volume Down | <kbd>Control</kbd> <kbd>Command</kbd> <kbd>-</kbd> |

White, pink, brown, and green noise are generated locally. Normal, Deep, and Super Deep presets shape their tone. Noise, depth, and volume are saved; playback always launches stopped.

## Build

You need macOS 13+ and Xcode. There are no third-party dependencies.

```bash
git clone https://github.com/Reece-Challinor/devnoise.git
cd devnoise
make test
make build
```

Run `make` to see every build, DMG, verification, and release command.

## Contributing

DevNoise is intentionally small. Fork the repository, create a focused branch, and open a pull request.

1. Read [AGENTS.md](AGENTS.md) before changing runtime behavior.
2. Preserve the menu-bar-only, silent, local-first product contract.
3. Use Apple frameworks; do not add dependencies.
4. Add or update tests with code changes.
5. Run `make verify`.

Keep public Swift APIs documented with `///` comments. Every Swift source file starts with a one-line purpose and `SPDX-License-Identifier: MIT`. Contributions are licensed under the repository's MIT License.

<details>
<summary><strong>Architecture</strong></summary>

DevNoise is one AppKit process with six production Swift files and no external packages.

```text
AppDelegate
├── StatusBarController ── menu commands ──┐
├── HotkeyManager ─────── global commands ├── AppModel
├── SettingsStore ─────── allowed defaults┘      │
└── AudioEngineManager ◀── procedural settings ──┘
```

- `AppDelegate.swift` starts the accessory app, installs the status item first, and wires dependencies.
- `AppModel.swift` owns value state and command transitions.
- `StatusBarController.swift` renders the AppKit menu and native template icon.
- `SettingsStore.swift` persists only noise, depth, and volume.
- `HotkeyManager.swift` registers six fixed Carbon hotkeys without accessibility permission.
- `AudioEngineManager.swift` lazily owns `AVAudioEngine` and generates samples in its render callback.

The render callback uses precomputed scalar state. It must not allocate, lock, block, perform I/O, or call Objective-C APIs. Playback is never persisted.

</details>

<a id="manual-qa"></a>
<details>
<summary><strong>Manual QA</strong></summary>

Before a release, verify on Apple silicon and Intel where possible:

- The app launches with no window, Dock icon, audio, or permission prompt.
- The menu-bar icon, menu actions, and all six global shortcuts work.
- Panic Stop halts audio immediately.
- Noise, depth, and volume survive relaunch; playback does not.
- The signed DMG installs by drag-and-drop and opens without a Gatekeeper warning.

</details>

<details>
<summary><strong>Maintainer release guide</strong></summary>

GitHub Actions builds an existing `v*` tag, tests the app, signs and notarizes it, staples the ticket, verifies Gatekeeper, writes a SHA-256 sidecar, attests provenance, and publishes the GitHub Release. Never publish an unsigned DMG as an official release.

Add these Actions secrets once:

| Secret | Value |
| --- | --- |
| `DEVNOISE_SIGN_IDENTITY` | Full `Developer ID Application: … (TEAMID)` identity |
| `DEVNOISE_CERTIFICATE_P12_BASE64` | Base64-encoded Developer ID `.p12` |
| `DEVNOISE_CERTIFICATE_P12_PASSWORD` | `.p12` export password |
| `DEVNOISE_NOTARY_KEY_P8_BASE64` | Base64-encoded App Store Connect API `.p8` key |
| `DEVNOISE_NOTARY_KEY_ID` | API key ID |
| `DEVNOISE_NOTARY_ISSUER_ID` | API issuer ID |

On macOS, encode the credential files without line wrapping:

```bash
base64 -i DeveloperID.p12 | pbcopy
base64 -i AuthKey_ABC123.p8 | pbcopy
```

For version `1.0.0`, set `MARKETING_VERSION`, run `make verify`, complete the manual QA checklist above, then push an annotated tag:

```bash
git tag -a v1.0.0 -m "DevNoise 1.0.0"
git push origin v1.0.0
```

The Release workflow publishes `DevNoise.dmg` and `DevNoise.dmg.sha256`. If an existing tag needs another run, use **Actions → Release → Run workflow** and enter the tag.

</details>

## Security

Do not open a public issue for a vulnerability. [Report it privately](https://github.com/Reece-Challinor/devnoise/security/advisories/new) with the affected version, reproduction steps, impact, and any suggested mitigation. Only the latest release is supported.

## Project

- [Releases and version history](https://github.com/Reece-Challinor/devnoise/releases)
- [Stable DMG download](https://github.com/Reece-Challinor/devnoise/releases/latest/download/DevNoise.dmg)
- [Portfolio site](https://reece-challinor.github.io/devnoise/)

MIT licensed. Built by [Reece Challinor](https://www.linkedin.com/in/reecechallinor/).
