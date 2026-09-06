# Contributing

DevNoise is intentionally small. Contributions should preserve that quality.

## Workflow

1. Fork the repository and create a focused branch.
2. Read [AGENTS.md](AGENTS.md) before changing runtime behavior.
3. Add or update tests with code changes.
4. Run `make verify`.
5. Open a pull request explaining the user-visible effect and privacy impact.

Use the existing Apple frameworks and avoid new dependencies. Keep public Swift APIs documented with `///` comments and source files headed with a one-line purpose plus `SPDX-License-Identifier: MIT`.

## Manual QA

Before a release, verify on Apple silicon and Intel where possible:

- The app launches with no window, Dock icon, audio, or permission prompt.
- The menu-bar icon and every menu action work.
- All six global shortcuts work while another app is focused.
- Panic Stop halts audio immediately.
- Noise, depth, and volume survive relaunch; playback does not.
- The signed DMG installs by drag-and-drop and opens without a Gatekeeper warning.

By contributing, you agree that your work is licensed under the repository's MIT License.
