# Task Workspace: Pre-Publish Readiness

This folder tracks recurring tasks before publishing Android and iOS builds.

## Files
- QUICK_TEST_PLAN.md: fast smoke tests with dedicated Android and iOS sections.
- ANDROID_TASKS.md: Android-specific bugs, fixes, and enhancements.
- IOS_TASKS.md: iOS-specific bugs, fixes, and enhancements.
- PRE_PUBLISH_BACKLOG.md: combined cross-platform backlog.
- STORE_SUBMISSION_TASKS.md: mandatory account/signing/store tasks.

## Suggested Workflow
1. Run QUICK_TEST_PLAN.md for each release candidate.
2. Update ANDROID_TASKS.md and IOS_TASKS.md first.
3. Reflect cross-platform blockers in PRE_PUBLISH_BACKLOG.md.
4. Complete STORE_SUBMISSION_TASKS.md before uploading builds.
5. Create a new section per release (for example: 0.1.0+2).

## Status Labels
- OPEN: not started
- IN_PROGRESS: currently being worked on
- BLOCKED: cannot proceed until dependency is resolved
- DONE: completed and verified

## Priority Labels
- P0: release blocker
- P1: high risk, should be fixed before store test
- P2: medium risk, can go after first test cycle
- P3: enhancement/quality improvement
