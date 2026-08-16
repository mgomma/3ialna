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

The existing Android accessibility and usage services continue to enforce app blocking, time limits, prayer locks, and hard-lock behavior. The Android integration now includes a privacy-preserving DNS `VpnService`. It routes the configured DNS endpoint through the VPN, evaluates the domain against the shared policy, returns NXDOMAIN for blocked domains, and forwards allowed DNS queries through a protected upstream socket. It does not proxy arbitrary application traffic or inspect messages or page content. Direct-IP traffic, encrypted DNS that bypasses the system resolver, and arbitrary page-content inspection remain outside this slice.

## Next recommended implementation

Validate the VPN on representative Android versions and OEMs. The test matrix should cover airplane mode, VPN permission revocation, reboot, captive portals, IPv6, DNS-over-HTTPS, direct-IP access, battery restrictions, and unsupported encrypted traffic. Content reputation or Islamic-content review should remain a separate, auditable data source rather than hard-coded assumptions.
