# Intel macOS dependency map

## Missing upstream Intel build

Herdr publishes macOS builds for Apple Silicon only, and its installer and `scripts/package` refuse Intel Macs. That is expected for this target. The workflow does **not** patch application source: it overlays one packaging script, verifies that the upstream file it replaces is exactly the one the overlay was derived from, and builds natively on an Intel runner.

## Sources used

- Herdr app source: https://github.com/herdrdev/herdr-app
- Herdr app release used for the default build: https://github.com/herdrdev/herdr-app/releases/tag/v0.1.9
- herdr-core (separate program, ships its own `herdr-macos-x86_64`): https://github.com/herdrdev/herdr
- ghostty (`vendor/ghostty` submodule, built with Zig into libghostty-vt): https://github.com/ghostty-org/ghostty
- Rust toolchain action: https://github.com/dtolnay/rust-toolchain
- Zig setup action: https://github.com/mlugg/setup-zig

The official Herdr source repository is https://github.com/herdrdev/herdr-app. The workflows default to that repository; maintainers can override it only for an authorized fork or pinned checkout.

## Build contract

1. Check out the source at `HERDR_SOURCE_REF` with submodules, and require `vendor/ghostty/build.zig`.
2. Read the Rust and Zig versions from upstream `.github/workflows/release.yml` (`RUST_TOOLCHAIN` and the `mlugg/setup-zig` `version`).
3. Require `crates/ghostty-sys/build.rs` to map `x86_64-apple-darwin` to `x86_64-macos`.
4. Compute the SHA-256 of upstream `scripts/package` and require it to equal `UPSTREAM_PACKAGE_SHA256`:

```text
bd104ffe75046600c8670d2624bbc57eb557d312a04942abb8e83d040010d243  scripts/package (herdr-app v0.1.9)
```

5. Copy the `INTEL-BUILD` overlay over `scripts/package` and run it with `x86_64-apple-darwin`.
6. Reject the build if any Mach-O file lacks `x86_64`, the executable links non-system libraries, or the runtime checks fail.

This avoids silently packaging with logic written for a different Herdr revision.

## Rust and Zig dependencies

Rust crates come from upstream `Cargo.lock` with `--locked`; vendored crates (`gpui-pre*`, `gpui-kit`, `taffy`, `quickjs-jit-runtime`, `zed-xim`, `xim-ctext`) come from the source checkout. libghostty-vt is compiled from the submodule by Zig for `x86_64-macos` and linked statically, so no third-party dylibs are bundled. The strict workflow checks that the final executable links only `/usr/lib` and `/System/Library` libraries.

## Release-build flag

Upstream marks official builds with `HERDR_APP_RELEASE=1`, which turns on self-update from `releases.herdr.dev` and sending telemetry and feedback. The Intel overlay leaves it unset. The official update feed has no `macos-x86_64` target, and a community build should not report itself as an official release.
