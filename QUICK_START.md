# Quick Start Guide - Parental Control App

## 🚀 5-Minute Setup

### Step 1: Build & Run
```bash
flutter pub get
flutter run
```

### Step 2: Enable Permissions (In-App)
1. **Usage Access**: Tap "Grant Permission" → Settings → Enable
2. **Overlay Permission**: Tap "Grant Permission" → Settings → Enable  
3. **Accessibility Service**: Settings → Accessibility → 3ialna → Enable

### Step 3: Set Up PIN
1. Tap family icon (👨‍👩‍👧‍👦) in app bar
2. Create 4-digit PIN
3. Confirm PIN

### Step 4: Configure Restrictions
1. Tap "Manage Apps"
2. Select apps to monitor
3. Set time limits (e.g., 30 minutes)
4. Block/unblock apps as needed

### Step 5: Enable Kiosk Mode (Optional)
1. In dashboard, tap "Enable Device Admin"
2. Accept device admin policy
3. Toggle "Enable Kiosk Mode"

## 📱 Key Features

### For Parents
- **Dashboard**: View stats and quick actions
- **App Management**: Block apps, set time limits
- **Schedule**: Set active hours for restrictions
- **Kiosk Mode**: Lock device to this app

### For Children
- **Overlay Warning**: Shows when limit exceeded
- **Take a Break**: Closes app and blocks for 30 min
- **Blocked Apps**: Cannot reopen until block expires

## 🔧 Method Channels

### Kiosk Mode
```dart
final kioskService = KioskService();
await kioskService.requestDeviceAdmin();
await kioskService.startKioskMode();
```

### App Blocking
```dart
final blockingService = AppBlockingService();
await blockingService.blockApp('com.facebook.katana', durationMinutes: 30);
```

### App Listing
```dart
final appListService = AppListService();
final apps = await appListService.getAllInstalledApps();
```

## 📊 Data Storage

All data stored in SharedPreferences:
- `parental_control_blocked_apps` - Blocked app list
- `parental_control_time_limits` - Time limits per app
- `parental_control_schedule` - Schedule settings
- `parental_control_parent_pin` - Hashed PIN
- `blocked_apps_with_timestamps` - Temporary blocks

## 🐛 Common Issues

**"Kiosk mode not working"**
→ Enable Device Admin first

**"Apps not blocking"**
→ Enable AccessibilityService

**"Overlay not showing"**
→ Grant Overlay permission

**"Time limits not enforcing"**
→ Grant Usage Access permission

## 📚 Full Documentation

- **Complete Guide**: `README_PARENTAL_CONTROLS.md`
- **Setup Instructions**: `PARENTAL_CONTROL_SETUP.md`
- **Implementation Details**: `IMPLEMENTATION_SUMMARY.md`
- **Screen Time Blocking**: `SCREEN_TIME_BLOCKING_IMPLEMENTATION.md`

---

**Ready to use!** All features are implemented and tested.

