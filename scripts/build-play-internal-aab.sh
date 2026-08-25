#!/usr/bin/env bash
# 3ialna Desert Signal release reminder: keep signing material private and make
# the production path explicit, reproducible, and separate from debug evaluation builds.
set -euo pipefail

usage() {
  cat <<'EOF'
Build a production-signed Android App Bundle for Google Play Internal testing.

Usage:
  scripts/build-play-internal-aab.sh [--build-name NAME] [--build-number NUMBER]

Requirements:
  - Flutter and Java 17 available on PATH.
  - android/key.properties exists and points to a private upload keystore.
  - The Play Console upload-key/Play App Signing arrangement is already configured.

This script never uploads to Google Play and never prints passwords.
EOF
}

build_name=""
build_number=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-name)
      build_name="${2:?Missing value for --build-name}"
      shift 2
      ;;
    --build-number)
      build_number="${2:?Missing value for --build-number}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

for command in flutter java keytool; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Required command not found: $command" >&2
    exit 1
  }
done

[[ -f android/key.properties ]] || {
  echo "android/key.properties is required; copy android/key.properties.example and fill it privately." >&2
  exit 1
}

store_file="$(awk -F= '$1 == "storeFile" {print substr($0, index($0, "=") + 1); exit}' android/key.properties)"
key_alias="$(awk -F= '$1 == "keyAlias" {print substr($0, index($0, "=") + 1); exit}' android/key.properties)"
[[ -n "$store_file" && -n "$key_alias" ]] || {
  echo "android/key.properties must define storeFile and keyAlias." >&2
  exit 1
}

if [[ "$store_file" = /* ]]; then
  keystore_path="$store_file"
else
  keystore_path="android/$store_file"
fi
[[ -f "$keystore_path" ]] || {
  echo "Configured keystore was not found: $keystore_path" >&2
  exit 1
}

version_line="$(awk '/^version:/{print $2; exit}' pubspec.yaml)"
default_name="${version_line%%+*}"
default_number="${version_line#*+}"
[[ "$default_number" != "$version_line" ]] || default_number=""
build_name="${build_name:-$default_name}"
build_number="${build_number:-$default_number}"

[[ "$build_name" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?([+-][A-Za-z0-9.-]+)?$ ]] || {
  echo "Invalid build name: $build_name" >&2
  exit 1
}
[[ "$build_number" =~ ^[0-9]+$ ]] || {
  echo "Build number must contain only digits: $build_number" >&2
  exit 1
}

flutter pub get
flutter analyze
flutter test --coverage
flutter build appbundle --release --build-name "$build_name" --build-number "$build_number"

bundle="build/app/outputs/bundle/release/app-release.aab"
[[ -s "$bundle" ]] || { echo "AAB was not created: $bundle" >&2; exit 1; }

verification_file="$(mktemp)"
trap 'rm -f "$verification_file"' EXIT
jarsigner -verify -verbose -certs "$bundle" > "$verification_file"
grep -q 'jar verified' "$verification_file"
sha256sum "$bundle"
echo "Production-signed AAB ready for Play Console Internal testing: $bundle"
echo "Do not upload this file to public GitHub releases or the public website."
