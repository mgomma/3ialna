# Screen Time Blocking Implementation Guide

## Overview

This document describes the implementation of the screen time blocking features that prevent children from using apps when time limits are exceeded.

## Key Features Implemented

### 1. ✅ Overlay System
- **Shows overlay only once per session** - Tracks which apps have shown overlay using `overlay_shown_sessions` in SharedPreferences
- **Excludes this app** - Never shows overlay on the screen time app itself
- **Excludes system apps** - Never shows overlay on Settings, Phone, Messages, Launcher
- **Enhanced overlay UI** - Shows app name, usage time, limit, and action buttons

### 2. ✅ "Take a Break" Functionality
- **Closes app immediately** - Uses home intent to return to launcher
- **Blocks app for 30 minutes** - Stores block timestamp in SharedPreferences
- **Prevents reopening** - AccessibilityService intercepts app launches
- **Shows countdown** - Toast notification displays remaining block time

### 3. ✅ AccessibilityService for App Blocking
- **Monitors all app launches** - Intercepts `TYPE_WINDOW_STATE_CHANGED` events
- **Immediate blocking** - Closes blocked apps before they fully open
- **Persistent storage** - Blocked apps list survives app restarts
- **Auto-expiration** - Removes expired blocks automatically

### 4. ✅ Time Tracking & Limits
- **Per-app tracking** - Uses UsageStatsManager for accurate time tracking
- **Daily limits** - Resets at midnight
- **Session tracking** - Prevents overlay spam by tracking shown state

## Implementation Details

### Files Created/Modified

#### Android Native Code:
1. **AppBlockingAccessibilityService.kt**
   - Monitors app launches
   - Blocks apps in blocked list
   - Shows toast notifications
   - Auto-expires blocks

2. **accessibility_service_config.xml**
   - Configuration for AccessibilityService
   - Monitors window state changes

3. **MainActivity.kt** (Enhanced)
   - Added `blockApp` method channel
   - Handles "Take a Break" action
   - Closes apps and returns to home

4. **MonitorForegroundService.kt** (Enhanced)
   - Tracks overlay shown state per session
   - Excludes this app and system apps
   - Only shows overlay once per app per session

#### Flutter Code:
1. **app_blocking_service.dart**
   - Manages blocked apps with timestamps
   - Handles block duration
   - Tracks overlay shown sessions

2. **app_blocking_channel.dart**
   - Method channel for native blocking
   - Handles "Take a Break" action

3. **overlay_warning_screen.dart** (Enhanced)
   - "Take a Break" button
   - "Add 5 More Minutes" button (snooze)
   - Better UI with usage information

### Data Storage

**SharedPreferences Keys:**
- `blocked_apps_with_timestamps` - JSON map of package names to block timestamps
- `block_duration_minutes` - Default block duration (30 minutes)
- `overlay_shown_sessions` - Set of package names that showed overlay this session

### Permission Requirements

**Required Permissions:**
1. **PACKAGE_USAGE_STATS** - For tracking app usage time
2. **SYSTEM_ALERT_WINDOW** - For showing overlay
3. **AccessibilityService** - For blocking app launches (user must enable manually)
4. **FOREGROUND_SERVICE** - For background monitoring

## User Flow

### Scenario: Child Opens Facebook After Exceeding Limit

1. **App Launch Detected**
   - AccessibilityService detects Facebook launch
   - Checks if Facebook is blocked → NO (not blocked yet)

2. **Time Limit Check**
   - MonitorForegroundService checks usage
   - Facebook exceeded 30-minute limit → YES
   - Overlay shown this session? → NO

3. **Show Overlay**
   - Overlay appears on Facebook
   - Shows: "Time limit exceeded for Facebook"
   - Shows: "You've used this app for 35 minutes today"
   - Shows: "Daily limit: 30 minutes"
   - Buttons: "Take a Break" and "Add 5 More Minutes"

4. **User Clicks "Take a Break"**
   - AppBlockingService blocks Facebook for 30 minutes
   - MainActivity closes Facebook and returns to home
   - Overlay dismissed

5. **Child Tries to Reopen Facebook**
   - AccessibilityService detects launch
   - Checks blocked list → YES (Facebook is blocked)
   - Immediately closes Facebook
   - Shows toast: "Facebook is blocked. Take a break! Available in 28 minutes"

6. **After 30 Minutes**
   - Block expires automatically
   - Facebook can be used normally again
   - Time tracking continues

## Setup Instructions

### 1. Enable AccessibilityService

**Critical Step:** Users must manually enable the AccessibilityService:

1. Open Android Settings
2. Go to Accessibility
3. Find "3ialna" or "App Blocking Service"
4. Enable the service
5. Grant all requested permissions

**Note:** This cannot be done programmatically for security reasons.

### 2. Grant Permissions

The app will request:
- Usage Access (for time tracking)
- Overlay Permission (for showing overlay)
- Accessibility (for blocking apps)

### 3. Configure Block Duration

Default is 30 minutes. Can be changed in settings.

## Testing Checklist

- [x] Overlay appears on Facebook when limit exceeded
- [x] Overlay does NOT appear on this app
- [x] Overlay does NOT appear on system apps
- [x] Overlay shows only once per session
- [x] "Take a Break" closes app immediately
- [x] Blocked app cannot be reopened
- [x] Toast shows remaining block time
- [x] Block expires after duration
- [x] AccessibilityService is working
- [x] Time tracking is accurate

## Important Notes

### Limitations:
1. **AccessibilityService must be enabled manually** - Cannot be automated
2. **System apps cannot be blocked** - For security reasons
3. **This app cannot block itself** - Would create infinite loop
4. **Root access can bypass** - Apps with root can potentially bypass

### Best Practices:
1. **Test thoroughly** - Ensure AccessibilityService is working
2. **Clear instructions** - Guide users to enable Accessibility
3. **Monitor logs** - Check Logcat for service status
4. **Handle edge cases** - App uninstalled while blocked, etc.

## Troubleshooting

### Overlay Not Showing:
- Check overlay permission is granted
- Verify app exceeded time limit
- Check overlay wasn't already shown this session

### App Not Blocking:
- Verify AccessibilityService is enabled
- Check blocked apps list in SharedPreferences
- Ensure block hasn't expired
- Check logs for errors

### Block Not Expiring:
- Verify block timestamp is correct
- Check block duration setting
- Ensure cleanup is running

## Code Locations

- **AccessibilityService**: `android/app/src/main/kotlin/com/example/mu_super_app/blocking/AppBlockingAccessibilityService.kt`
- **Blocking Service**: `lib/data/local/app_blocking_service.dart`
- **Overlay Screen**: `lib/presentation/overlay/overlay_warning_screen.dart`
- **Method Channel**: `android/app/src/main/kotlin/com/example/mu_super_app/MainActivity.kt`
- **Monitoring Service**: `android/app/src/main/kotlin/com/example/mu_super_app/usage/MonitorForegroundService.kt`

