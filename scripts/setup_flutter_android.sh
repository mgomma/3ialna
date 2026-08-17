#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AVD_NAME=""
RUN_APP=0
INSTALL_PACKAGES=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  ./scripts/setup_flutter_android.sh [options]

Options:
  --install       Install missing Linux build prerequisites with apt.
  --avd NAME      Start this Android Virtual Device if it is not already running.
  --run           Run the Flutter app after checks complete.
  --dry-run       Print actions without installing packages or starting devices.
  -h, --help      Show this help.

Examples:
  ./scripts/setup_flutter_android.sh --install
  ./scripts/setup_flutter_android.sh --avd Pixel_6_API_35 --run
  ./scripts/setup_flutter_android.sh --install --avd Pixel_6_API_35 --run
EOF
}

log() { printf '\n[%s] %s\n' "3ialna" "$*"; }
warn() { printf '\n[3ialna][warning] %s\n' "$*" >&2; }
die() { printf '\n[3ialna][error] %s\n' "$*" >&2; exit 1; }

run() {
  if (( DRY_RUN )); then
    printf '+ %q' "$1"; shift || true
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

while (($#)); do
  case "$1" in
    --install) INSTALL_PACKAGES=1 ;;
    --avd) (($# >= 2)) || die "--avd requires an AVD name"; AVD_NAME="$2"; shift ;;
    --run) RUN_APP=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

if [[ ! -f "$PROJECT_DIR/pubspec.yaml" ]]; then
  die "pubspec.yaml was not found. Expected project at $PROJECT_DIR"
fi

if [[ "${EUID}" -eq 0 ]]; then
  APT_PREFIX=()
else
  APT_PREFIX=(sudo)
fi

REQUIRED_PACKAGES=(
  clang
  cmake
  ninja-build
  pkg-config
  libgtk-3-dev
  liblzma-dev
  libstdc++-12-dev
)

if (( INSTALL_PACKAGES )); then
  [[ "${DRY_RUN}" -eq 1 || "${EUID}" -eq 0 || "$(command -v sudo || true)" ]] || die "sudo is required for --install"
  log "Installing Linux Flutter development prerequisites"
  run "${APT_PREFIX[@]}" apt-get update
  run "${APT_PREFIX[@]}" apt-get install -y "${REQUIRED_PACKAGES[@]}"
else
  log "Checking Linux Flutter prerequisites"
  missing=()
  for command_name in clang++ ninja cmake pkg-config; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      missing+=("$command_name")
    fi
  done
  for package_name in libgtk-3-dev; do
    if ! dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q 'install ok installed'; then
      missing+=("$package_name")
    fi
  done
  if ((${#missing[@]})); then
    warn "Missing prerequisites: ${missing[*]}"
    warn "Re-run with --install, or install them manually with:"
    printf '  sudo apt-get update && sudo apt-get install -y %s\n' "${REQUIRED_PACKAGES[*]}"
  else
    log "Linux prerequisites are installed"
  fi
fi

if ! command -v flutter >/dev/null 2>&1; then
  warn "Flutter is not on PATH. Install Flutter and add its bin directory to PATH before using --run."
  warn "Official guide: https://docs.flutter.dev/get-started/install/linux"
else
  log "Flutter: $(flutter --version | head -n 1)"
  flutter doctor -v || warn "flutter doctor reported one or more issues"
fi

if [[ -z "${ANDROID_HOME:-}" && -n "${ANDROID_SDK_ROOT:-}" ]]; then
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
fi
if [[ -z "${ANDROID_SDK_ROOT:-}" && -n "${ANDROID_HOME:-}" ]]; then
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
fi

if [[ -z "${ANDROID_HOME:-}" ]]; then
  for candidate in "$HOME/Android/Sdk" "$HOME/Android/sdk"; do
    if [[ -d "$candidate" ]]; then
      export ANDROID_HOME="$candidate"
      export ANDROID_SDK_ROOT="$candidate"
      break
    fi
  done
fi

if [[ -n "${ANDROID_HOME:-}" ]]; then
  export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
  log "Android SDK: $ANDROID_HOME"
else
  warn "ANDROID_HOME/ANDROID_SDK_ROOT is not configured and no default SDK directory was found."
fi

if command -v adb >/dev/null 2>&1; then
  log "ADB devices"
  adb start-server >/dev/null
  adb devices -l || true
else
  warn "adb is not available. Install Android SDK Platform Tools and configure PATH."
fi

if command -v emulator >/dev/null 2>&1; then
  log "Available Android Virtual Devices"
  emulator -list-avds || true
else
  warn "emulator is not available. Install Android Emulator and a system image through Android Studio or sdkmanager."
fi

if [[ -n "$AVD_NAME" ]]; then
  command -v emulator >/dev/null 2>&1 || die "Cannot launch AVD: emulator command is unavailable"
  if emulator -list-avds | grep -Fxq "$AVD_NAME"; then
    if (( DRY_RUN )); then
      log "Would launch AVD: $AVD_NAME"
    elif ! adb devices | awk 'NR > 1 && $1 ~ /^emulator-/ && $2 == "device" { found=1 } END { exit(found ? 0 : 1) }'; then
      log "Launching AVD: $AVD_NAME"
      nohup emulator -avd "$AVD_NAME" -no-snapshot -netdelay none -netspeed full >/tmp/3ialna-emulator.log 2>&1 &
      log "Waiting for Android boot completion"
      adb wait-for-device
      until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do sleep 2; done
      log "Android emulator is ready"
    else
      log "An Android emulator is already connected"
    fi
  else
    die "AVD '$AVD_NAME' was not found. Run emulator -list-avds to see valid names."
  fi
fi

if (( RUN_APP )); then
  command -v flutter >/dev/null 2>&1 || die "Flutter is required for --run"
  log "Preparing Flutter dependencies"
  cd "$PROJECT_DIR"
  flutter pub get
  log "Running 3ialna"
  flutter devices
  flutter run
fi

log "Setup/check completed"
