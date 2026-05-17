# Store Submission Tasks (Operational)

Last updated: 2026-05-17

## Android (Play Console)
- [ ] Finalize package id and app name.
- [ ] Create upload keystore and secure backup.
- [ ] Configure android/key.properties locally (never commit).
- [ ] Build signed AAB.
- [ ] Complete Data safety form.
- [ ] Complete declarations for sensitive permissions:
  - QUERY_ALL_PACKAGES
  - accessibility usage
  - usage stats and overlay behaviors
- [ ] Upload to Internal testing and invite testers.
- [ ] Confirm policy status has no blocking warnings.

## iOS (TestFlight)
- [ ] Finalize bundle identifier and signing team.
- [ ] Confirm provisioning profiles for Debug/Release/Profile.
- [ ] Build IPA from macOS environment.
- [ ] Upload build to App Store Connect.
- [ ] Fill export compliance and privacy answers.
- [ ] Add testing notes for known iOS limitations.
- [ ] Add internal/external testers and start test cycle.

## Final Go/No-Go
- [ ] No open P0 items in PRE_PUBLISH_BACKLOG.md
- [ ] No unmitigated P1 crash/security items
- [ ] Quick test plan completed and attached to release notes
