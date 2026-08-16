# 3ialna iOS implementation boundaries and validation

## Scope delivered in this repository

The iOS implementation now has three coordinated layers. The Flutter layer presents an Arabic right-to-left onboarding flow and calls the `safe_content/ios` MethodChannel. The Runner bridge requests Family Controls authorization and configures `NEDNSProxyManager`. The `SafeContentDNSProxy` source contains the provider lifecycle, domain normalization, allowlist precedence, NXDOMAIN response construction, and an upstream DNS forwarding boundary.

The implementation intentionally filters DNS names only. It does not inspect message bodies, page text, photos, browser history, or application content. A domain rule is normalized to a host name, and a rule matches the exact host or a subdomain. An allowed rule takes precedence over a blocked rule. The current provider reads policy arrays from the App Group suite and uses an upstream resolver configured in the provider source until the product-level resolver policy is finalized.

## Xcode work still required

The repository contains the extension source and `Info.plist`, but the extension must be added to the Xcode project on a Mac. This is an Apple signing and entitlement boundary rather than something that can be reliably completed by Flutter tooling on Linux.

| Required item | Expected configuration |
|---|---|
| Network Extension target | Add a DNS Proxy App Extension named `SafeContentDNSProxy`. |
| Target class | Set the principal class to `SafeContentDNSProxyProvider`. |
| Provider bundle identifier | Use the exact identifier configured in `IosSafeContentBridge.swift`, or update both values together. |
| Network Extension entitlement | Enable the DNS Proxy capability for the app and extension targets where Apple permits it. |
| Family Controls | Enable the capability and request authorization from the parent-approved flow. |
| App Group | Configure the same App Group on Runner and the extension, then replace the placeholder suite identifier if the production identifier differs. |
| Signing | Use a paid Apple Developer team with the required capabilities and provisioning profiles. |
| Policy synchronization | Write blocked and allowed domain arrays to the shared App Group before starting or reloading the provider. |

The extension target is not considered production-ready until it is visible in the Xcode project, signs successfully, and is installed on a physical iPhone. Simulator behavior is not sufficient to validate the complete Network Extension lifecycle.

## Mac-based validation checklist

1. Open `ios/Runner.xcworkspace` on macOS after running `flutter pub get`.
2. Add the `SafeContentDNSProxy` App Extension target and include `SafeContentDNSProxyProvider.swift` and the extension `Info.plist` in that target only.
3. Configure the final bundle identifiers, App Group, Family Controls, Network Extension capability, team, and provisioning profiles.
4. Build Runner and the extension for a physical iPhone running a supported iOS version.
5. Launch the Arabic onboarding flow, confirm the Family Controls prompt, then confirm the DNS proxy permission and activation prompt.
6. Add a test blocked domain and verify that a DNS lookup returns NXDOMAIN. Add a parent-approved exception and verify that the exception wins for the exact host and its subdomains.
7. Verify that allowed DNS replies return through the configured upstream resolver and that a resolver failure is surfaced as an unavailable protection state rather than being described as active.
8. Stop and restart the proxy, reboot the phone, and confirm that the saved provider configuration and status are restored.
9. Test airplane mode, captive portals, IPv6-only connectivity, DNS-over-HTTPS browser settings, and apps that use their own encrypted DNS transport. These cases must be documented as supported, blocked, or out of scope before release.
10. Confirm that no domain logs contain query content or user message data. Store only the minimum event metadata needed for a parent-facing audit trail.

## Known boundaries and follow-up work

The provider currently uses `1.1.1.1` as the code-level upstream placeholder. Production must move this into an explicit privacy-reviewed configuration, with timeout, retry, failure-mode, and regional-resolver decisions documented. The forwarding path is deliberately isolated in one method so it can be replaced by an approved resolver strategy without changing policy evaluation.

The App Group policy writer is also a required integration step. The Flutter dashboard currently owns the user-facing rules, while the extension reads shared arrays. A production implementation must serialize updates atomically, version the policy, and confirm that the extension has loaded the newest version before reporting protection as active.

The iOS onboarding copy distinguishes Screen Time authorization from DNS proxy activation. This avoids claiming that Family Controls alone filters websites. The dashboard entry point is shown only on iOS, while Android continues to use its existing VPN, accessibility, and kiosk controls.

## Validation status in this environment

The source changes were reviewed with `git diff --check`. Flutter and Dart executables are not installed in this Linux sandbox, and Xcode is unavailable, so Flutter analysis and Swift/Xcode compilation could not be run here. The remaining validation must occur on macOS with the extension target and Apple entitlements configured.
