# Releasing

GitHub Actions builds every release from an existing `v*` tag. It tests the app, imports a Developer ID certificate into an ephemeral keychain, signs the app and DMG, notarizes with an App Store Connect API key, staples the ticket, verifies Gatekeeper, creates a SHA-256 sidecar, attests provenance, and publishes the GitHub release.

## One-time repository setup

Add these GitHub Actions secrets:

| Secret | Value |
| --- | --- |
| `DEVNOISE_SIGN_IDENTITY` | Full `Developer ID Application: … (TEAMID)` identity |
| `DEVNOISE_CERTIFICATE_P12_BASE64` | Base64-encoded exported Developer ID `.p12` |
| `DEVNOISE_CERTIFICATE_P12_PASSWORD` | Password used when exporting the `.p12` |
| `DEVNOISE_NOTARY_KEY_P8_BASE64` | Base64-encoded App Store Connect API `.p8` key |
| `DEVNOISE_NOTARY_KEY_ID` | API key ID |
| `DEVNOISE_NOTARY_ISSUER_ID` | API issuer ID |

On macOS, encode files without line wrapping:

```bash
base64 -i DeveloperID.p12 | pbcopy
base64 -i AuthKey_ABC123.p8 | pbcopy
```

## Release 1.0.0

1. Update `MARKETING_VERSION` and `CHANGELOG.md`.
2. Run `make verify` and complete [the manual QA checklist](../CONTRIBUTING.md#manual-qa).
3. Create and push the annotated tag:

```bash
git tag -a v1.0.0 -m "DevNoise 1.0.0"
git push origin v1.0.0
```

The stable download URL remains:

```text
https://github.com/Reece-Challinor/devnoise/releases/latest/download/DevNoise.dmg
```

If a tag exists but its workflow needs to be rerun, use **Actions → Release → Run workflow** and enter that tag. Never publish an unsigned DMG as an official release.
