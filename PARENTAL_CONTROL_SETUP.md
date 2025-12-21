# Parental Control Setup Guide

This guide explains how to set up and use the parental control features in the app.

## Overview

The parental control system provides:
- **Kiosk Mode**: Lock the device to prevent exiting the app
- **App Blocking**: Block specific apps from being used
- **Time Limits**: Set daily time limits for individual apps
- **Schedule Management**: Restrict app usage during specific hours
- **PIN Protection**: Secure parental controls with a PIN

## Initial Setup

### 1. Enable Device Admin (Required for Kiosk Mode)

1. Open the app and navigate to **Parental Controls** (tap the family icon in the app bar)
2. If you haven't set a PIN yet, you'll be prompted to create one
3. In the Parental Controls dashboard, tap **Enable Device Admin**
4. Follow the system prompts to grant device admin permissions
5. Read and accept the device admin policy

**Note**: Device admin permission is required for kiosk mode to work. Without it, you can still use app blocking and time limits, but kiosk mode will not be available.

### 2. Grant Usage Access Permission

The app needs usage access to monitor app usage and enforce time limits:

1. When prompted, tap **Open Settings**
2. Find **3ialna** in the list of apps
3. Enable **Usage access**
4. Return to the app

### 3. Grant Overlay Permission

For blocking overlays to appear:

1. When prompted, tap **Open Settings**
2. Find **3ialna** in the list of apps
3. Enable **Display over other apps**
4. Return to the app

## Using Parental Controls

### Setting Up a PIN

1. Navigate to **Parental Controls**
2. If no PIN is set, you'll be prompted to create one
3. Enter a 4-digit PIN
4. Confirm the PIN
5. Optionally use biometric authentication (fingerprint/face) if available

### Managing Apps

1. In Parental Controls, tap **Manage Apps**
2. Browse the list of installed apps
3. Use the toggle switch to block/unblock apps
4. Tap **Set Time Limit** to configure daily time limits
5. View current usage vs limits with progress bars

### Setting Time Limits

1. In **Manage Apps**, find the app you want to limit
2. Tap **Set Time Limit**
3. Choose a preset time (15m, 30m, 1h, etc.) or enter a custom value
4. Tap **Set** to save

The app will show an overlay warning when the time limit is reached.

### Configuring Schedule

1. In Parental Controls, tap **Schedule**
2. Enable **Enable Schedule**
3. Select active days (Mon-Sun)
4. Set start and end times
5. Optionally enable **Different Weekend Rules** for separate weekend hours

Restrictions will only apply during scheduled hours when enabled.

### Activating Kiosk Mode

**Important**: Device admin must be enabled first.

1. In Parental Controls dashboard, ensure device admin is enabled
2. Toggle **Enable Kiosk Mode** switch
3. The device will enter lock task mode
4. Home button and recent apps will be disabled
5. To exit, toggle kiosk mode off (requires PIN authentication)

## Security Considerations

### PIN Security

- The PIN is hashed using SHA-256 before storage
- PINs are never stored in plain text
- Biometric authentication can be used as an alternative

### Device Admin

- Device admin permission allows the app to:
  - Lock the device into kiosk mode
  - Prevent uninstallation (when device owner)
  - Control lock screen policies

### App Uninstallation

- The app can be uninstalled unless it's set as a device owner
- Device owner mode requires special setup (usually for enterprise devices)
- For regular users, device admin mode is sufficient for kiosk functionality

## Troubleshooting

### Kiosk Mode Not Working

1. Ensure device admin is enabled
2. Check that the app has device admin permissions
3. Try disabling and re-enabling device admin
4. Restart the device

### Apps Not Being Blocked

1. Verify the app is in the blocked list
2. Check that schedule restrictions are active (if schedule is enabled)
3. Ensure the monitoring service is running
4. Grant usage access permission if not already granted

### Time Limits Not Enforcing

1. Verify time limits are set for the app
2. Check that monitoring is enabled
3. Ensure usage access permission is granted
4. Check the schedule settings if schedule is enabled

### Overlay Not Showing

1. Grant overlay permission in system settings
2. Check that the app has SYSTEM_ALERT_WINDOW permission
3. Restart the app

## Advanced Configuration

### Device Owner Mode (Enterprise)

For complete control, the app can be set as a device owner:

1. This requires special setup during device provisioning
2. Usually only available on enterprise-managed devices
3. Provides additional features like preventing uninstallation
4. Contact your IT administrator for setup

### Background Monitoring

The app uses a foreground service to monitor app usage:

- Service runs continuously when monitoring is enabled
- Checks app usage every 30 seconds
- Shows persistent notification
- Automatically restarts after device reboot

## Best Practices

1. **Set a Strong PIN**: Use a PIN that's not easily guessable
2. **Regular Reviews**: Periodically review blocked apps and time limits
3. **Communication**: Discuss restrictions with children
4. **Testing**: Test restrictions before enforcing them strictly
5. **Backup**: Keep a record of your PIN in a secure location

## Limitations

- **iOS Support**: iOS has stricter limitations. This implementation focuses on Android.
- **System Apps**: Some system apps cannot be blocked (Settings, Phone, etc.)
- **Root Access**: Apps with root access may bypass restrictions
- **App Updates**: Newly installed apps are not automatically blocked

## Support

For issues or questions:
1. Check this guide first
2. Review app logs for error messages
3. Ensure all permissions are granted
4. Try restarting the device

## Privacy

- All data is stored locally on the device
- No usage data is sent to external servers
- PINs are hashed and stored securely
- App usage statistics are only used for enforcement

