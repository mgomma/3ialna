# Troubleshooting: App Not Closing When Limit Exceeded

## Common Issues and Solutions

### Issue: Facebook (or other app) not closing when "Take a Break" is clicked

#### Check 1: Is the Overlay Showing?
- **Symptom**: No overlay appears when limit is exceeded
- **Solution**: 
  1. Verify Usage Access permission is granted
  2. Check that time limit is actually exceeded
  3. Verify overlay permission is granted
  4. Check logs: `adb logcat | grep MonitorForegroundSvc`

#### Check 2: Is "Take a Break" Button Working?
- **Symptom**: Overlay shows but clicking "Take a Break" does nothing
- **Solution**:
  1. Check if package name is being detected correctly
  2. Verify method channel is working
  3. Check logs: `adb logcat | grep MainActivity`

#### Check 3: Is AccessibilityService Enabled?
- **Symptom**: App closes but can be reopened immediately
- **Solution**:
  1. Go to Settings → Accessibility
  2. Find "3ialna" or "App Blocking Service"
  3. Enable the service
  4. **This is critical** - without this, apps cannot be blocked

#### Check 4: Is the App Actually Being Blocked?
- **Symptom**: App closes but blocking doesn't persist
- **Solution**:
  1. Check SharedPreferences: `flutter.blocked_apps_with_timestamps`
  2. Verify block timestamp is saved
  3. Check AccessibilityService logs: `adb logcat | grep AppBlockingService`

## Step-by-Step Debugging

### 1. Verify Permissions
```bash
# Check if Usage Access is granted
adb shell dumpsys package com.example.mu_super_app | grep PACKAGE_USAGE_STATS

# Check if Overlay permission is granted
adb shell appops get com.example.mu_super_app SYSTEM_ALERT_WINDOW

# Check if AccessibilityService is enabled
adb shell settings get secure enabled_accessibility_services
```

### 2. Check Logs
```bash
# Monitor service logs
adb logcat -s MonitorForegroundSvc AppBlockingService MainActivity

# Check for errors
adb logcat | grep -i error
```

### 3. Verify Blocking State
```bash
# Check SharedPreferences
adb shell run-as com.example.mu_super_app
cd shared_prefs
cat FlutterSharedPreferences.xml | grep blocked
```

### 4. Test AccessibilityService
1. Open Facebook manually
2. Check logs for AccessibilityService events
3. Verify it detects the app launch
4. Check if it reads the blocked list

## Common Fixes

### Fix 1: Enable AccessibilityService
**Most Common Issue!**

1. Open Android Settings
2. Go to **Accessibility**
3. Scroll to **Installed services** or **Downloaded apps**
4. Find **3ialna** or **App Blocking Service**
5. Tap to open
6. Toggle **ON**
7. Confirm the warning dialog

**Without this, the app cannot block other apps!**

### Fix 2: Grant All Permissions
1. **Usage Access**: Settings → Apps → 3ialna → Usage access → Enable
2. **Overlay Permission**: Settings → Apps → 3ialna → Display over other apps → Enable
3. **AccessibilityService**: Settings → Accessibility → 3ialna → Enable

### Fix 3: Restart Services
```bash
# Restart the monitoring service
adb shell am startservice com.example.mu_super_app/.usage.MonitorForegroundService

# Check if service is running
adb shell dumpsys activity services | grep MonitorForegroundService
```

### Fix 4: Clear and Reconfigure
1. Clear app data
2. Re-enable all permissions
3. Set up PIN again
4. Configure app limits
5. Test with a short time limit (e.g., 1 minute)

## Testing the Blocking Flow

### Test Scenario 1: Overlay Appears
1. Set Facebook limit to 1 minute
2. Use Facebook for 1+ minutes
3. **Expected**: Overlay should appear
4. **If not**: Check Usage Access permission

### Test Scenario 2: Take a Break Works
1. Overlay appears
2. Click "Take a Break"
3. **Expected**: Facebook closes immediately, returns to home
4. **If not**: Check method channel logs

### Test Scenario 3: App Stays Blocked
1. After "Take a Break", try to open Facebook
2. **Expected**: Facebook closes immediately, toast shows "blocked"
3. **If not**: Check AccessibilityService is enabled

### Test Scenario 4: Block Expires
1. Wait 30 minutes after blocking
2. Try to open Facebook
3. **Expected**: Facebook opens normally
4. **If not**: Check block expiration logic

## Advanced Debugging

### Check Blocked Apps List
```kotlin
// In Android Studio, add breakpoint in AppBlockingAccessibilityService
// Check: prefs.getString("flutter.blocked_apps_with_timestamps")
```

### Verify Package Name
- Facebook: `com.facebook.katana`
- Instagram: `com.instagram.android`
- Check actual package: `adb shell pm list packages | grep facebook`

### Monitor Real-Time
```bash
# Watch all blocking-related logs
adb logcat -c
adb logcat | grep -E "AppBlocking|MonitorForeground|blockApp|Take a Break"
```

## Expected Behavior

### When Limit Exceeded:
1. ✅ Overlay appears (once per session)
2. ✅ Shows app name, usage time, limit
3. ✅ "Take a Break" button visible

### When "Take a Break" Clicked:
1. ✅ App added to blocked list
2. ✅ App force-closed immediately
3. ✅ Returns to home screen
4. ✅ Overlay dismissed

### When Blocked App Opened:
1. ✅ AccessibilityService detects launch
2. ✅ Checks blocked list
3. ✅ Immediately closes app
4. ✅ Shows toast: "Facebook is blocked. Available in X minutes"

## Still Not Working?

1. **Check Android Version**: Some features require Android 6.0+
2. **Check Device Admin**: For kiosk mode, device admin must be enabled
3. **Check Root Access**: Rooted devices may bypass restrictions
4. **Check System Apps**: System apps cannot be blocked
5. **Check This App**: This app cannot block itself

## Contact Support

If none of these solutions work:
1. Collect logs: `adb logcat > blocking_logs.txt`
2. Note Android version and device model
3. Describe exact steps to reproduce
4. Include screenshots of permission settings

