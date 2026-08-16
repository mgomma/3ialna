# Safe-content foundation

3ialna now includes a parent-configurable safe-content policy foundation.

## Included in this slice

- Safe-content categories for adult content, gambling, violence, and social media.
- Explicit blocked-domain and allowed-domain lists.
- Allowlist precedence over category and block rules.
- Canonical domain normalization for URLs, `www` prefixes, paths, and subdomains.
- Persistent policy storage in Flutter `SharedPreferences`.
- Parent dashboard access through the **Safe Content** action.
- Deterministic unit-test coverage for policy serialization and decisions.

## Privacy boundary

The first policy layer stores rule configuration only. It does not read messages, photos, or page content. Unknown domains are allowed by the policy engine rather than silently classified as unsafe. This makes the behavior explainable and avoids presenting a small local list as a complete web-safety provider.

## Android enforcement boundary

The existing Android accessibility and usage services continue to enforce app blocking, time limits, prayer locks, and hard-lock behavior. The safe-content engine is platform-neutral and ready to be called by a future Android `VpnService` or an approved browser integration. A real web-filtering implementation must add traffic routing, DNS/host evaluation, HTTPS limitations, permission education, battery behavior, fail-safe handling, and Android policy/compliance review before being described as full web filtering.

## Next recommended implementation

Implement an Android `VpnService` behind an explicit parent opt-in. It should consume the same serialized policy, apply allowlist-first host decisions, expose a visible persistent notification, fail safely when stopped, and provide a test matrix for airplane mode, VPN permission revocation, reboot, captive portals, IPv6, DNS-over-HTTPS, and unsupported encrypted traffic. Content reputation or Islamic-content review should be a separate, auditable data source rather than hard-coded assumptions.
