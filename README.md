# Herdr App — Intel macOS Builds

Reproducible **Intel-only (`x86_64`) macOS builds** of [Herdr](https://herdr.dev/), the desktop app for terminals and coding agents that keep running.

> This is an unofficial community build. It is not affiliated with or endorsed by the Herdr project. Herdr remains a separate project; see the original project and license notices before redistribution.

## Download

Open **Releases** and download the `.dmg` for your Intel Mac. The release includes SHA-256 checksums and a build manifest.

Builds are produced from the official [herdrdev/herdr-app](https://github.com/herdrdev/herdr-app) source project. The workflows read the configurable `HERDR_SOURCE_REPOSITORY` and `HERDR_SOURCE_REF` values, defaulting to that official repository at the `v0.1.9` release tag.

- Target: Intel `x86_64`, not universal and not Apple Silicon
- Build output: `Herdr.app`, a compressed DMG, and the upstream-format `herdr-app-macos-x86_64.tar.gz`

## Install

1. Download the `.dmg` from Releases.
2. Open it and drag `Herdr.app` to `Applications`.
3. If macOS blocks this unsigned community build, right-click the app and choose **Open** once. If necessary, remove only the quarantine attribute from the app you downloaded:

```bash
xattr -cr /Applications/Herdr.app
```

Only run that command for an artifact you trust and have verified with the published SHA-256 checksum.

Herdr also needs [herdr-core](https://github.com/herdrdev/herdr) (`hc`), which is a separate program with its own official Intel macOS release (`herdr-macos-x86_64`). On first launch the app offers to install a core it cannot find; it looks in `~/.local/bin`, Homebrew, mise, Nix and cargo locations.

## Why a custom Intel build integration is required

Herdr publishes macOS builds for Apple Silicon only. Its source and toolchain support Intel: `crates/ghostty-sys` maps `x86_64-apple-darwin` to Zig's `x86_64-macos` target, and the vendored QuickJS JIT supports `x86_64`. The upstream README sends Intel Mac users to build from source. Upstream's packaging script, however, stops on Intel with `Intel Macs aren't supported; build from source instead.`, and upstream's DMG script requires a Developer ID certificate and Apple notarization.

This repository therefore overlays a minimally patched [`scripts/package`](scripts/package) on the upstream checkout before building. Every change from upstream is marked `INTEL-BUILD`:

- the Intel-Mac guard is removed;
- `HERDR_APP_RELEASE` is not set, so the build behaves like upstream's documented build from source: it never self-updates from the official Apple Silicon feed and never reports telemetry or feedback to the official endpoints as if it were an official release.

The overlay is pinned to the SHA-256 of the upstream `scripts/package` it was derived from. If upstream changes that file, both workflows fail instead of silently packaging with stale logic. The Rust and Zig versions are read from upstream's own `.github/workflows/release.yml` on every run, so toolchains follow upstream rather than a copy that can drift.

[`scripts/intel/make-dmg.sh`](scripts/intel/make-dmg.sh) is the unsigned Intel counterpart of upstream `scripts/mac-dmg`: it creates a drag-to-Applications DMG with `hdiutil` and does not sign, notarize or staple.

See [DEPENDENCIES.md](docs/DEPENDENCIES.md) for the dependency map and source links.

## Workflows

- **Legacy/manual:** [`build-intel-legacy.yml`](.github/workflows/build-intel-legacy.yml) is the minimal build path. Run it from **Actions → Build Intel DMG (legacy)**. It uploads a short-retention DMG artifact.
- **Strict/release:** [`build-intel-strict.yml`](.github/workflows/build-intel-strict.yml) is the recommended path. It fails loudly on a changed upstream packaging script, missing submodules, toolchain or architecture mismatches, non-system linked libraries, a failed `--version`/`--skill` runtime check, missing app output, empty DMGs, or failed DMG validation. It uploads a DMG, the tarball, manifests and targeted logs, and can create a GitHub Release when given a tag such as `herdr-0.1.9-intel1`.

Both workflows are started manually; nothing runs on push or on a timer. GitHub-hosted Intel runners are scarce and long builds consume Actions minutes. The strict workflow can optionally run upstream's native screenshot test (`screenshot_test` input). It is off by default because it needs working Metal on the runner, which hosted Intel VMs may not provide.

## Verification

For a downloaded DMG, verify the release checksum before installation:

```bash
shasum -a 256 Herdr-0.1.9-macos-x86_64.dmg
hdiutil verify Herdr-0.1.9-macos-x86_64.dmg
```

The strict workflow also records executable architecture, native Mach-O counts, minimum macOS version (`minos`), linked libraries, signature type, the source and ghostty commits, and DMG metadata in `build-manifest.txt`.

## Limitations

- Intel macOS support is community-maintained and may have GPUI/Metal/GPU compatibility issues on older Intel GPUs.
- The app is ad hoc signed only; it is not Apple Developer ID signed or notarized by this repository.
- The app does not update itself. Install a newer DMG from Releases to update.
- The minimum supported macOS version is not validated by this repository; the built `minos` is recorded in the manifest, and linker deployment-target warnings are kept in `diagnostic-excerpts.txt`.
- A green workflow means the scripted validations passed; it is not a guarantee that every GPU, display, input method, or mod works on every Intel Mac.

## License

The automation and documentation in this repository are licensed under the [Apache License 2.0](LICENSE), matching upstream Herdr. `scripts/package` is a modified copy of the upstream file and keeps its upstream license. The Herdr source and bundled dependencies retain their own licenses; the app bundle ships upstream `LICENSE` and `THIRD-PARTY-NOTICES`. Do not remove upstream license notices.

### Source configuration for maintainers

Both workflows default to the official `herdrdev/herdr-app` repository at `v0.1.9`. Set the repository variables `HERDR_SOURCE_REPOSITORY` and `HERDR_SOURCE_REF` only if you intentionally build an authorized fork or a different pinned checkout; the strict workflow's `upstream_ref` input overrides `HERDR_SOURCE_REF` for one run. For a private authorized checkout, add a fine-grained repository secret named `HERDR_SOURCE_TOKEN` with read-only Contents access.

When moving to a new upstream release, compare its `scripts/package` with the overlay, re-apply the `INTEL-BUILD` changes, and update `UPSTREAM_PACKAGE_SHA256` in both workflows.
