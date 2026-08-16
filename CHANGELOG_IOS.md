# iOS Changelog - 3ialna Parental Control App

## [2026-05-12] - Native Bridge & Infrastructure

### Added
- **Native MethodChannel**: Implemented the `app_blocking/block` channel in `AppDelegate.swift` to allow Flutter to communicate with native iOS code.
- **Unified Storage Preparation**: The iOS version is now ready to consume the same storage keys and configurations as the Android version via the Flutter layer.

### Technical Requirements for iOS Parental Control
To implement actual app blocking on iOS, you must use Apple's **Screen Time API**. This requires:
1.  **Apple Developer Program Membership**: Mandatory for using the `FamilyControls` entitlement.
2.  **Physical Device**: The Screen Time API does not work on the iOS Simulator.
3.  **Entitlements**: You must enable the "Family Controls" capability in Xcode.
4.  **Frameworks**:
    - `FamilyControls`: For authorizing parental control.
    - `ManagedSettings`: For enforcing restrictions (blocking apps).
    - `DeviceActivity`: For monitoring usage and triggering events.

### Next Steps for Implementation
- Create a **Shield Configuration Extension** to customize the appearance of the blocked app screen.
- Create a **Shield Action Extension** to handle user interactions on the blocked screen.
- Create a **Device Activity Monitor Extension** to track usage and enforce time limits in the background.

---
*Note: Due to sandbox limitations and the requirement for Apple-signed entitlements, the native Screen Time API logic must be completed within a local Xcode environment on a Mac.*
