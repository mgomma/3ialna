#!/usr/bin/env bash
set -euo pipefail

apk_path="${1:?Usage: bash android-startup-smoke.sh APK_PATH [UPGRADE_APK_PATH]}"
upgrade_apk_path="${2:-}"
package_name="com.ialna.app"
diagnostics_dir="${ANDROID_SMOKE_DIAGNOSTICS:-diagnostics}"

mkdir -p "$diagnostics_dir"
collect_failure_logs() {
    exit_status=$?
    if [[ "$exit_status" -ne 0 ]]; then
        adb logcat -d -v threadtime > "$diagnostics_dir/logcat.txt" || true
        cat "$diagnostics_dir/logcat.txt"
    fi
}
trap collect_failure_logs EXIT

adb install -r "$apk_path"
if [[ "${ANDROID_SMOKE_RESET_DATA:-0}" == "1" ]]; then
    adb shell pm clear "$package_name"
fi

check_startup() {
    phase="$1"
    phase_dir="$diagnostics_dir/$phase"
    mkdir -p "$phase_dir"
    adb shell am force-stop "$package_name"
    adb logcat -c
    adb shell am start -W -n "$package_name/.MainActivity" > "$phase_dir/startup.txt"
    cat "$phase_dir/startup.txt"
    app_pid="$(adb shell pidof "$package_name" | tr -d '\r')"
    [[ "$app_pid" =~ ^[0-9]+$ ]]
    capture_status=0
    timeout 30s adb logcat --pid="$app_pid" -v threadtime > "$phase_dir/logcat.txt" || capture_status=$?
    if [[ "$capture_status" -ne 0 && "$capture_status" -ne 124 ]]; then
        cat "$phase_dir/logcat.txt"
        exit "$capture_status"
    fi
    adb logcat -d -v threadtime -s ActivityManager ActivityTaskManager > "$phase_dir/system.txt"
    if ! grep -q 'Status: ok' "$phase_dir/startup.txt"; then
        grep -q 'Status: timeout' "$phase_dir/startup.txt"
        grep -Eq 'Displayed com\.ialna\.app/\.MainActivity' "$phase_dir/system.txt"
    fi
    surviving_pid="$(adb shell pidof "$package_name" | tr -d '\r')"
    [[ "$surviving_pid" == "$app_pid" ]]
    if grep -E 'FATAL EXCEPTION|Fatal signal|Unhandled Exception|Error registering plugin|MissingPluginException' "$phase_dir/logcat.txt" ||
        grep -E 'ANR in com\.ialna\.app' "$phase_dir/system.txt"; then
        cat "$phase_dir/logcat.txt" "$phase_dir/system.txt"
        exit 1
    fi
    echo "PASS: $phase"
}

check_startup no-optional-permissions

if [[ "${ANDROID_SMOKE_DEEP_TESTS:-0}" == "1" ]]; then
    adb shell appops set "$package_name" GET_USAGE_STATS allow
    check_startup usage-access-granted
    adb shell appops set "$package_name" GET_USAGE_STATS deny
    check_startup usage-access-revoked
    android_api="$(adb shell getprop ro.build.version.sdk | tr -d '\r')"
    if [[ "$android_api" -ge 33 ]]; then
        adb shell pm grant "$package_name" android.permission.POST_NOTIFICATIONS
        check_startup notifications-granted
        adb shell pm revoke "$package_name" android.permission.POST_NOTIFICATIONS
        check_startup notifications-revoked
    fi
fi

if [[ -n "$upgrade_apk_path" ]]; then
    adb install -r "$upgrade_apk_path"
    check_startup optimized-release-upgrade
fi