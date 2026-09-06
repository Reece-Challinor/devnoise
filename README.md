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

Run `make` to see every build, DMG, verification, and release command. The six production Swift files are documented at their public boundaries; [architecture](docs/ARCHITECTURE.md) explains how they fit together.

## Fork and contribute

Fork the repository, create a branch, and open a pull request. Keep the app silent, local, and menu-bar only. Read [CONTRIBUTING.md](CONTRIBUTING.md) for the short checklist and [SECURITY.md](SECURITY.md) for private vulnerability reporting.

Released DMGs are signed, notarized, checksummed, and accompanied by GitHub artifact provenance. See [docs/RELEASING.md](docs/RELEASING.md) for the maintainer workflow.

MIT licensed. Built by [Reece Challinor](https://www.linkedin.com/in/reecechallinor/).
