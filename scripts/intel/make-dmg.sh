#!/usr/bin/env bash
set -euo pipefail
# Packs an ad-hoc signed Intel Herdr.app into a drag-to-Applications DMG.
# Upstream scripts/mac-dmg requires a Developer ID certificate and Apple
# notarization, which this community build does not have. This script is the
# unsigned Intel counterpart; it does not sign, notarize or staple.
app="${1:?usage: make-dmg.sh Herdr.app output.dmg}"
out="${2:?usage: make-dmg.sh Herdr.app output.dmg}"
VOLNAME="${VOLNAME:-Herdr}"
[[ "$(uname -s)" == Darwin ]] || { echo 'error: make-dmg.sh requires macOS' >&2; exit 1; }
[[ "$(basename "$app")" == Herdr.app && -d "$app" ]] || { echo "error: expected a Herdr.app bundle: $app" >&2; exit 1; }
[[ "$out" == *.dmg && ! -e "$out" ]] || { echo "error: output must be a new .dmg file: $out" >&2; exit 1; }
exe="$app/Contents/MacOS/Herdr"
[[ -x "$exe" ]] || { echo "error: app executable missing: $exe" >&2; exit 1; }
[[ "$(lipo -archs "$exe")" == x86_64 ]] || { echo "error: main executable is not x86_64: $(lipo -archs "$exe")" >&2; exit 1; }
codesign --verify --deep --strict "$app" || { echo 'error: app signature (ad hoc) does not verify' >&2; exit 1; }
work="$(mktemp -d "${TMPDIR:-/tmp}/herdr-intel-dmg.XXXXXX")"; trap 'rm -rf "$work"' EXIT
mkdir "$work/stage"
ditto "$app" "$work/stage/Herdr.app"
ln -s /Applications "$work/stage/Applications"
hdiutil create -volname "$VOLNAME" -srcfolder "$work/stage" -fs HFS+ -format UDZO -imagekey zlib-level=9 "$work/Herdr.dmg"
[[ -s "$work/Herdr.dmg" ]] || { echo 'error: hdiutil produced an empty DMG' >&2; exit 1; }
hdiutil verify "$work/Herdr.dmg"
mkdir -p "$(dirname "$out")"
mv "$work/Herdr.dmg" "$out"
echo "Created Intel DMG: $out"
