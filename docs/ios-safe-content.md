# iOS safe-content counterpart

## What is implemented

The Flutter project now includes an iOS `safe_content/ios` method channel and an `IosSafeContentBridge` that requests Family Controls authorization on iOS 16 or later. The Flutter client exposes authorization status, requests authorization, and reports whether web protection is running.

The bridge deliberately rejects `startWebProtection` and `stopWebProtection` until a proper Network Extension target and Apple-approved entitlement are added. Family Controls authorization by itself is not equivalent to DNS filtering or arbitrary HTTPS page inspection.

## Required iOS architecture

A production iOS counterpart needs two distinct capabilities:

| Capability | Apple technology | Purpose |
|---|---|---|
| App and Screen Time controls | FamilyControls and ManagedSettings | Authorize parent-managed restrictions and shield selected applications or web domains supported by Apple’s APIs |
| Device web filtering | NetworkExtension `NEPacketTunnelProvider` or an approved content-filter extension | Apply device-level network policy, subject to Apple entitlements, extension targets, and review requirements |

The current bridge handles only the first authorization step. It does not claim full web filtering until the extension target is provisioned and validated.

## Mac validation checklist

Run the following on an online Mac with Xcode, CocoaPods, Flutter, and an Apple Developer signing configuration:

1. Run `flutter pub get` and `pod install` in `ios/`.
2. Add the Family Controls capability to the Runner target and obtain the required provisioning profile.
3. Create the Network Extension target and configure the approved packet-tunnel or content-filter entitlement.
4. Run `flutter analyze` and `flutter test`.
5. Build with `flutter build ios --no-codesign` before signing.
6. Test authorization denial, approval, revocation, app restart, device restart, and child-profile switching.
7. Test DNS-over-HTTPS, IPv6, direct-IP traffic, captive portals, battery behavior, and extension termination.
8. Confirm the UI never claims protection when the extension is stopped or unavailable.

## Product boundary

The Arabic dashboard should use **الحماية مفعّلة** only when the actual iOS enforcement extension reports an active state. When only Family Controls authorization exists, show **تم منح إذن الرقابة** and explain that web filtering still requires the device extension. This separation prevents a false sense of safety and makes the iOS implementation auditable.
