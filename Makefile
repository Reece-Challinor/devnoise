# DevNoise contributor and release commands.
# SPDX-License-Identifier: MIT

SHELL := /bin/bash
.DEFAULT_GOAL := help

PROJECT := DevNoise.xcodeproj
SCHEME := DevNoise
DESTINATION := platform=macOS
DERIVED_DATA_DIR := $(CURDIR)/.build
DIST_DIR := $(CURDIR)/dist
XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME)

.PHONY: help open build build-release test analyze app dmg checksum scripts-check verify sign notarize staple gatekeeper release

help: ## Show the available commands.
	@printf '%s\n' \
	  'DevNoise' \
	  '' \
	  '  make open           Open the Xcode project.' \
	  '  make build          Build the Debug app.' \
	  '  make build-release  Build the unsigned Release app.' \
	  '  make test           Run the macOS test suite.' \
	  '  make analyze        Run Xcode static analysis.' \
	  '  make verify         Run all local CI checks.' \
	  '  make dmg            Build an unsigned local DMG.' \
	  '  make checksum       Build a DMG and SHA-256 sidecar.' \
	  '  make release        Sign, notarize, staple, and verify a DMG.' \
	  '' \
	  'Release setup and QA are documented in README.md.'

open: ## Open the project in Xcode.
	open $(PROJECT)

build: ## Build the Debug configuration without signing.
	$(XCODEBUILD) -configuration Debug -derivedDataPath "$(DERIVED_DATA_DIR)/debug" CODE_SIGNING_ALLOWED=NO build

build-release: ## Build the Release configuration without signing.
	$(XCODEBUILD) -configuration Release -derivedDataPath "$(DERIVED_DATA_DIR)/release-check" CODE_SIGNING_ALLOWED=NO build

test: ## Run unit and launch tests.
	$(XCODEBUILD) -configuration Debug -destination '$(DESTINATION)' -derivedDataPath "$(DERIVED_DATA_DIR)/tests" CODE_SIGNING_ALLOWED=NO test

analyze: ## Run Xcode's static analyzer.
	$(XCODEBUILD) -configuration Debug -derivedDataPath "$(DERIVED_DATA_DIR)/analyze" CODE_SIGNING_ALLOWED=NO analyze

app: ## Create dist/DevNoise.app for packaging.
	DEVNOISE_DIST_DIR="$(DIST_DIR)" DEVNOISE_DERIVED_DATA_DIR="$(DERIVED_DATA_DIR)/release" scripts/build_release.sh

dmg: app ## Create an unsigned DMG for local testing.
	DEVNOISE_DIST_DIR="$(DIST_DIR)" scripts/dmg_build.sh "$(DIST_DIR)/DevNoise.app"

checksum: dmg ## Create the DMG and its SHA-256 sidecar.
	DEVNOISE_DIST_DIR="$(DIST_DIR)" scripts/sha256.sh "$(DIST_DIR)/DevNoise.dmg"

scripts-check: ## Validate shell and plist syntax.
	@for script in scripts/*.sh; do bash -n "$$script"; done
	plutil -lint DevNoise/Info.plist

verify: scripts-check test analyze build-release ## Run the full local verification suite.

sign: app ## Sign dist/DevNoise.app with Developer ID.
	DEVNOISE_DIST_DIR="$(DIST_DIR)" scripts/codesign.sh "$(DIST_DIR)/DevNoise.app"

notarize: ## Submit dist/DevNoise.dmg to Apple notarization.
	DEVNOISE_DIST_DIR="$(DIST_DIR)" scripts/notarize.sh "$(DIST_DIR)/DevNoise.dmg"

staple: ## Staple Apple's ticket to release artifacts.
	DEVNOISE_DIST_DIR="$(DIST_DIR)" scripts/staple.sh "$(DIST_DIR)/DevNoise.app" "$(DIST_DIR)/DevNoise.dmg"

gatekeeper: ## Verify signatures, notarization, and Gatekeeper acceptance.
	DEVNOISE_DIST_DIR="$(DIST_DIR)" scripts/verify_gatekeeper.sh "$(DIST_DIR)/DevNoise.app" "$(DIST_DIR)/DevNoise.dmg"

release: verify sign ## Build and verify the complete signed release locally.
	DEVNOISE_DIST_DIR="$(DIST_DIR)" scripts/dmg_build.sh "$(DIST_DIR)/DevNoise.app"
	$(MAKE) notarize
	$(MAKE) staple
	DEVNOISE_DIST_DIR="$(DIST_DIR)" scripts/sha256.sh "$(DIST_DIR)/DevNoise.dmg"
	$(MAKE) gatekeeper
