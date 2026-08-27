# Firebase App Distribution automation checklist

- [x] Confirm the Firebase project and Android Firebase App ID.
- [x] Register the Android app and obtain its Firebase App ID using the Firebase Management API.
- [x] Resolve the mismatch between the registered Firebase package and the repository Android application ID.
- [x] Migrate the repository Android application ID and native package to com.ialna.app.
- [x] Add the GitHub Actions build-and-distribute workflow.
- [x] Add release notes and optional tester-group configuration inputs.
- [x] Create the required Firebase service-account credential and repository secrets.
- [x] Trigger a controlled distribution run after explicit confirmation.
- [x] Verify the Firebase App Distribution release.
- [ ] Optionally create a Firebase tester group, add testers, and set FIREBASE_TESTER_GROUPS for automatic invitations.
- [x] Add invited-tester Firebase download information to the bilingual website.
- [x] Build, publish, and verify the GitHub Pages website link.
- [x] Automate website release metadata after a successful Firebase App Distribution upload.
- [x] Add an invited-tester QR-code section for mobile download access.
- [x] Retain FormSubmit’s built-in reCAPTCHA and honeypot protection in the contact form.
- [x] Correct the contact-form status when FormSubmit delivers a message but returns a non-success response.
- [x] Assess signing requirements before exposing an APK as a public direct download.
- [x] Replace the tester-only website link and QR code with a public APK release URL.
- [x] Automate public APK release publishing and website metadata updates for every eligible release.

## Public distribution decision

- [x] Publish a public debug-signed Android pre-release for direct anonymous download; communicate that it is an evaluation build and not a production-signed release.
- [x] Research credible age-based defaults for social media and games category budgets.
- [x] Add parent-managed children with editable name, birth date, gender, and assigned configuration profile.
- [x] Make the first configured child the default active child and support switching when multiple children are defined.
- [x] Apply social-media and games limits as category-wide daily budgets rather than per-app budgets.
- [x] Add a device shortcut path for choosing the active child when multiple profiles exist.
- [x] Update the bilingual website with category-budget guidance and a persistent header menu.
- [x] Research credible default sleep-duration guidance and practical age-profile sleep windows.
- [x] Add reviewed default social-media and games app lists to the category registry.
- [x] Add parent-editable per-child prayer-time and sleep lock schedules.
- [x] Apply the active child’s prayer and sleep lock rules in Android enforcement.
- [x] Update the website profile table with prayer and sleep safeguard defaults.
- [x] Research iOS parental-control enforcement limits and map the Android child prayer/sleep safeguards to supported iOS frameworks.
- [x] Implement equivalent iOS child-profile prayer and sleep safeguards with documented platform fallbacks.
- [x] Add a privacy-aware in-app link to the public contact form.
- [x] Add detailed Arabic-first installation and setup steps for the Android evaluation build and the iOS availability status.
- [x] Research and publish a sourced feature-comparison table for 3ialna and relevant parental-control apps in the Arabic/Islamic market.
- [x] Define a versioned configuration-pack format that excludes child names, dates of birth, gender, and all other child identity data.
- [x] Add parent-named export, native sharing, validation, and import flows for reusable configuration packs.
- [x] Document the configuration-pack privacy boundary and import behavior in the app and public website.
- [x] Add Help & Support navigation that opens an email composer to 3ialna.app@gmail.com with a safe prefilled subject.
- [x] Add an About 3ialna action that opens the official public website in the device browser.
- [x] Optimize the Android evaluation APK packaging safely and measure the resulting published asset size.
- [x] Add automated export/import privacy tests covering child names, birth dates, gender, PINs, usage, and recordings.
- [x] Verify the existing iOS Screen Time safeguards and public installation-guide wording against the current implementation boundary.
- [x] Verify the public market-comparison table remains present, source-linked, and scope-limited.
- [x] Make automated website release-metadata synchronization resilient to concurrent dev pushes, then verify the privacy-hardening APK release publishes successfully.
- [x] Diagnose and repair the public GitHub APK download 404, then verify every website download choice resolves directly.
- [x] Repeat live APK download, profile-pack privacy, iOS safeguard, and market-table verification after the latest deployment.
- [x] Remove emulator-only x86_64 from public phone downloads and retain only supported Android phone architectures.
- [x] Enable safe R8/ProGuard code shrinking and Android resource shrinking for a separately marked optimized evaluation artifact.
- [x] Build, measure, and verify optimized APK downloads before publishing them alongside the existing debug-evaluation build.
- [x] Trace the permission-grant crash using reproducible diagnostics and Android permission-flow guards.
- [x] Add a parent-controlled crash-report export/send flow that excludes child identity, messages, recordings, PINs, and usage data by default.
- [x] Remove the in-app "نموذج التواصل" shortcut and replace it with first-child edit and new-child setup actions.
- [x] Validate the Android VPN permission-return and parent-controlled diagnostic-report path through automated coverage and a user device report if a physical crash is reproduced.
- [x] Inspect and complete iOS Family Controls, app/category shielding, schedule, and diagnostic safeguards for feature parity within Apple platform limits.
- [x] Verify and correct the live Arabic-first installation guide and source-linked competitor comparison after the latest application changes.
- [x] Add parent-created child task reminders with local voice notes, parent-editable repeat intervals, enable/pause/delete controls, and Android/iOS notification scheduling.
- [x] Add a notification action that opens 3ialna and plays the local parent recording; do not promise background auto-play on either platform.
- [x] Let parents use locally recorded voice notes for prayer reminders as an optional replacement for the standard prayer reminder voice.
- [x] Add privacy and scheduling tests proving voice task and prayer recordings remain local and reminder schedules are safely editable.
- [x] Re-audit the shared diagnostic-report schema to confirm no voice recording paths, reminder labels, or parent-only metadata are included.
- [ ] Conduct parent-assisted physical-device validation of recurring task notifications and the Play parent voice action, using a sanitized report only if a crash occurs.
- [x] Create and present an architecture deck for notification-only parent task and prayer voice reminders.
- [ ] Replace lifecycle-only startup entries in shared reports with a compact health summary so actual handled permission or notification faults are prominent.
- [ ] Record sanitized permission-return and notification-action outcomes without storing raw exception text, task labels, or recording information.
- [ ] Add tests for diagnostic signal prioritization and re-verify the submitted report format against the strengthened privacy boundary.
- [x] Enable the default prayer lock safely for newly created child profiles while preserving parent editability and existing parent choices.
- [x] Preserve country verbal settings immediately without an unnecessary save action or reset on returning to the screen.
- [x] Implement a resilient first-run sequence for location and usage access, with clear rationale, Android settings redirects, and app-resume validation rather than abrupt closure.
- [x] Add coverage for default settings and the first-run permission state transitions.
- [ ] Configure the four stable evaluation-signing repository secrets so future GitHub evaluation APKs use one persistent certificate and can upgrade in place.
- [x] Replace separate dashboard child edit/add shortcuts with one children-management entry that lists existing children and provides an add-child control.
- [x] Enable default schedule settings for new profiles while preserving parent editability and existing choices.
- [x] Add focused kids-management tests for an empty list and a newly added child.
- [x] Update the public website to explain the unified kids-management flow and current local update guidance.
- [x] Add a safe local shell script that builds the APK, creates a GitHub release asset, and synchronizes website download metadata without committing signing secrets.
- [x] Run the local release script with the explicit debug allowance and record the resulting release/website behavior.
- [x] Diagnose and fix the two remaining DomainRulesTabs widget tests, then re-run the full Flutter CI suite.
- [x] Add and execute a dry-run mode that verifies local website metadata generation without building, releasing, committing, or pushing artifacts.
- [x] Review DomainRulesTabs test coverage and add focused edge-case tests for invalid, duplicate, and filtered domain behavior.
- [x] Review and revise the website’s default APK download selection so it reflects package size and Android ABI compatibility clearly.
- [x] Add best-effort browser architecture detection for APK choice while retaining a clear manual fallback.
- [x] Diagnose and harden Start Monitoring when Android accessibility is unavailable or declined, preventing an app exit.
- [x] Update child age profiles from birth dates while preserving an explicit parent profile selection.
- [x] Add an in-app parent usage report with date filters.
- [x] Add the Arabic educational-expert contact form with a parent-reviewed email draft containing requested child details.
- [x] Add an Android quick-settings shortcut for opening settings and selecting the child currently using the device.
- [x] Fix prayer-time lock release when its configured interval ends.
- [x] Fix PIN entry so numeric keyboard input is accepted reliably.
- [x] Document Android 13+ Quick Settings tile test steps and audit remaining accessibility/app-blocking limitations.
- [x] Require device unlock before the Quick Settings tile opens the active-child selector.
- [x] Add an interactive in-app onboarding walkthrough explaining the app’s core family-safety features.
- [x] Correct mailto email-draft encoding so recipients see spaces rather than plus signs.
- [x] Align the public website’s bilingual feature walkthrough content with the in-app onboarding order.

> Website verification: the Arabic production preview now begins the feature tour with “عائلتك أولاً” and presents all five steps in the same app order: family, protection, parent voice reminders, reports/privacy, then parent control.

> Publication verification: commit `334ccfd` triggered GitHub Pages deployment run `32734698068`; the deployment is in progress.

> Publication verification: GitHub Pages deployment `32734698068` completed successfully, and the live site displays the five Arabic feature-tour steps in the required onboarding order.

- [ ] Add a privacy-safe mobile device-frame preview for each public website feature-tour step.
- [x] Visually verify that all five website device previews match the family, protection, voice, reports/privacy, and quick-actions tour steps without showing child data.
- [ ] Translate prayer-lock settings, protection and hard-lock controls, and quick actions into Arabic.

> Validation status: commit `79bb6c8` triggered website deployment `32736242340` and Flutter CI `32736242265`; both are in progress.

> Deployment monitoring: the GitHub Pages job has produced its website artifact and remains in progress; no deployment error is reported.

> CI monitoring: Flutter CI analysis failed for commit `79bb6c8`; inspect the analyzer output, repair the localization compile issue, and re-run validation before delivery.

> CI monitoring: analyzer fix commit `f5a5f80` triggered replacement Flutter CI `32736489947`, currently in progress.

> Replacement CI monitoring: the analyzer and Android APK jobs are still running; no new analyzer failure has been reported.

> Replacement CI monitoring: analysis and tests completed successfully after the constructor fix; Android and iOS builds remain in progress.

> Final validation: Flutter CI `32736489947` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing.

- [ ] Review live device-frame preview alignment on desktop and mobile layouts.

> Desktop review: the five device frames share a consistent top edge, size, internal screen height, and baseline with their related titles and copy; no desktop alignment correction is needed.

> Mobile review: at a 390 px viewport, all five frames retain consistent width, centered placement, visual hierarchy, and Arabic RTL alignment in the vertically stacked tour. No responsive correction is needed.
- [x] Review live device-frame preview alignment on desktop and mobile layouts.
- [x] Validate the educational-expert contact mobile number against the selected country calling code.
- [x] Translate the Next prayer label and prayer notification wording into Arabic.
- [x] Set the default prayer lock duration to 15 minutes and cover it with regression tests.

> Validation status: commit `193a4c7` triggered Flutter CI `32740297965`; analysis, test, Android, and iOS jobs are in progress.

> CI monitoring: Dart analysis and regression tests passed, as did the manual Android APK job. Android debug and unsigned iOS builds remain in progress.

> Final validation: Flutter CI `32740297965` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing.

- [x] Add an end-to-end widget test for expert-contact validation with Arabic-Indic mobile digits.
- [x] Require at least one child profile before starting an educational-expert contact request, with a bilingual route to Kids Management.
- [x] Apply daily time limits by the active child’s age-profile settings and enforce the newly selected child’s own allowance immediately after switching.
- [x] Attribute local usage snapshots to the active child without adding child identity to shared diagnostic or export artifacts.
- [x] Add a parent usage-report filter for child-specific daily usage and limits.
- [x] Run a full automated validation pass covering static analysis, unit/widget tests, Android and iOS builds, and tablet-sized layouts.
- [x] Audit Android/iOS platform-sensitive behavior and document any physical-device checks that cannot be proven in CI.
- [x] Fix any confirmed cross-platform or tablet-layout defects and rerun authoritative CI validation.
- [x] Add a PIN-protected Parent mode as the default unrestricted profile, with all child restrictions and time limits disabled only while Parent mode is active.
- [x] Persist child usage history in durable device storage so it survives app updates and a reinstall when the storage is retained, and add parent-controlled per-child history deletion.
- [x] Add regression coverage for Parent mode authorization, restriction bypass, durable history reload, and history deletion.
- [x] Update the public website to explain secure shared-device use for one or more children, including separate profiles, limits, history, and the family-cost benefit.
- [x] Create a bilingual interactive onboarding walkthrough for adding child profiles, switching the shared-device user, and entering PIN-protected Parent mode.
- [x] Add regression coverage for walkthrough steps, skip/completion persistence, and the profile-setup call to action.
- [x] Strengthen the public landing page message that a shared multi-child device can reduce the need to purchase a separate phone for every child, while retaining separate limits and local histories.
- [x] Revalidate the interactive onboarding walkthrough, including child setup, active-child switching, Parent mode education, Kids Management routing, and compact-screen scrolling.
- [x] Create a short bilingual shared-device installation video for the landing page.
- [x] Create a printable bilingual family handover checklist for parents.
- [x] Add a parent-dashboard reminder to confirm or switch the active child when handing over the shared device.
- [x] Add regression coverage, publish the app source changes, and prepare the website publication checkpoint.
- [x] Review the existing local prayer-voice workflow and determine the safe automatic Azan playback path for Android and iOS.
- [x] Add parent-selected on-device Azan recording controls and automatic scheduling at enabled prayer times.
- [x] Add privacy, schedule-refresh, and platform-fallback regression coverage; push and validate the updated builds.

> Validation status: commit `d4c4890` triggered Flutter CI `32750896175`; analysis/tests and Android/iOS builds are in progress.

> CI monitoring: the analysis/test stage, manual Android APK, and Android debug build have passed; the unsigned iOS build remains in progress.

> Final validation: Flutter CI `32750896175` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing.

> Final validation: expert-contact commits `c7b4b73`, `c06d0c7`, `32b1f7f`, and `4f48d38` added the bilingual defined-child gate, existing Kids Management route, and isolated regression coverage. Flutter CI `32765280432` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing.

> Final validation: commit `69e721e` added locally attributed active-child usage, active age-profile limits, and a child filter in the parent report. Flutter CI `32768178535` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing.

> Final validation: commit `b20a488` added landscape-tablet and split-view responsive smoke tests, and replaced the fixed-width shared-profile import field with a maximum-width constraint. Flutter CI `32802275925` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing. Physical Android/iOS/tablet testing remains required for permissions, OEM battery behavior, and Apple Family Controls authorization.

> Final validation: commits `bbdbf00` and `16b0380` added PIN/biometric-gated Parent mode, native Android bypasses for child restrictions, durable local child-history archive with parent-controlled per-child deletion, and deterministic report-widget coverage. Flutter CI `32810325822` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing. Website checkpoint `b163bc5a` documents shared-device child profiles, separate limits/history, and the family cost benefit.

> Final validation: commits `8419038`, `04a740f`, and `931c04a` added a bilingual interactive shared-device walkthrough, direct Kids Management setup action, compact-screen scrolling, and regression coverage for child add/switch and Parent mode demonstrations. Flutter CI `32812401570` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing.

> Follow-up validation: the shared-device savings website copy now makes the family-budget benefit explicit without claiming a specific monetary amount. TypeScript check passed. The requested fresh Flutter CI #109 rerun (attempt #2) also passed analysis/tests, manual Android APK, Android debug build, and unsigned iOS build, including the compact-screen shared-device walkthrough coverage.

- [x] Audit prayer voice-notification scheduling while the app is closed or the screen is locked.
- [x] Implement resilient background prayer voice reminder delivery with Android and iOS platform fallbacks.
- [x] Add regression coverage and validate scheduled prayer voice reminder builds.

> Validation status: commit `7dc5ae6` triggered Flutter CI `32753359505`; analysis/tests and Android/iOS builds are in progress.

> CI monitoring: Dart analysis/tests, the manual Android APK, and the Android debug build passed; the unsigned iOS build remains in progress.

> Final validation: Flutter CI `32753359505` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing.

- [x] Add reboot and time-zone schedule-refresh regression tests for prayer voice reminders.

> Validation status: commit `c189852` triggered Flutter CI `32755214378`; analysis/tests and Android/iOS builds are in progress.

> Final validation: Flutter CI `32755214378` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing.

- [x] Verify Android battery-optimization whitelist handling for scheduled prayer voice reminder reliability.

- [x] Add a clear exact-alarm setup and readiness guide for background prayer voice reminders.
- [x] Enhance the optional battery-optimization review with parent-facing reliability status.
- [x] Add an in-app, on-device verification flow for scheduled prayer voice reminders.

> Validation status: commit `a0b253d` triggered Flutter CI `32757072100`; analysis/tests and Android/iOS builds are in progress.

> CI monitoring: the initial battery-optimization update failed one Dart test; inspect and repair the method-channel test before final validation.

> Replacement validation: binding-fix commit `fa1f967` triggered Flutter CI `32757542508`, currently in progress.

> Battery audit source: Android documents that `setExactAndAllowWhileIdle()` can fire during Doze, while battery-optimization exemptions are partial and direct exemption requests are policy-restricted. Source: https://developer.android.com/training/monitoring-device-state/doze-standby

> Replacement CI monitoring: the repaired test has progressed beyond the prior test failure; Android and iOS build jobs remain in progress.

> Replacement CI monitoring: the manual Android APK has passed; the analyze/test, Android debug, and iOS build jobs are still completing.

> Replacement CI result: the binding initialization alone did not resolve the battery-optimization channel test. Replace the fragile plugin-owning service test with a deterministic channel-wrapper test, then re-run CI.

> Final replacement validation: wrapper-fix commit `20892c6` triggered Flutter CI `32759061892`, currently in progress.

> Final validation: Flutter CI `32759061892` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing.

> Platform research: Android exact alarms can fire while the app is not running or the device is asleep, but Android 12+ requires the user-approved Alarms & reminders access. iOS can deliver a local notification sound while the app is suspended, but custom sound files must be under 30 seconds; iOS cannot promise arbitrary background voice playback after termination.

> Final validation: commit `9b42394` added a parent-visible three-step readiness path, optional battery review language, and an isolated one-minute locked-device test that does not change the recurring prayer schedule. Flutter CI `32762451402` completed successfully with analysis/tests, manual Android APK, Android debug build, and unsigned iOS build all passing. Physical-device/OEM battery behavior remains parent-device validation.

## Verification log

- Firebase tester link resolves and correctly instructs visitors to open their invitation on a mobile device; access remains limited to invited testers.
- Local Arabic-first website preview renders the release panel, tester-access notice, Firebase release button, and contact invitation path correctly.
- GitHub Pages is enabled, but the github-pages environment currently rejects deployments from dev; update its deployment-branch rule before rerunning the website workflow.
- Public GitHub Pages deployment 32665373726 completed successfully and serves the Arabic-first Firebase release section at https://mgomma.github.io/3ialna/.
- Local preview confirms both QR cards render clearly: the Firebase tester QR is marked invitation-only and the public-guide QR opens the shareable landing page.
- FormSubmit built-in Google reCAPTCHA and the existing honeypot remain the selected contact-form protections; third-party visitor analytics are intentionally omitted.
- Firebase run 32666357056 uploaded the build, generated release metadata commit b0d5f6f, and explicitly triggered successful GitHub Pages deployment 32666725991.
- Contact confirmation fix eba008f passed the production Pages deployment in run 32667034191.
- Public debug release run 32667602977 created GitHub pre-release debug-v0.1.0-b1-run32667602977-a1 and its APK direct link; Pages run 32668097160 verified the updated public website.
- Cache-busted live verification confirms Pages now displays the persistent header menu, research-linked category budgets, and the current public APK asset from debug-v0.1.0-b1-run32669486043-a1.
- Public debug release run 32692620123 completed successfully with smaller architecture-specific APKs: arm64-v8a 97,518,062 bytes, armeabi-v7a 76,553,592 bytes, and x86_64 83,535,445 bytes. Pages run 32692991603 completed and the cache-busted live page exposes all three direct-download choices.
- Privacy audit run 32694102326 passed all four new configuration-pack tests, including active-child export with a stored child name, birth date, and gender; overall CI retained only the two known domain-rules widget-test failures. Public release run 32694553988 and Pages run 32694926529 succeeded after metadata synchronization was made resilient to concurrent pushes.
- The 404 was traced to release metadata using custom 3ialna-prefixed names while GitHub CLI published Flutter's app-*.apk basenames. The corrected app-arm64-v8a, app-armeabi-v7a, and app-x86_64 links all returned successful partial-download responses, and Pages run 32695939529 deployed the corrected live metadata.
- Re-verification downloaded the first 1 MiB from the live website's arm64 target with HTTP 206, attachment filename app-arm64-v8a-debug.apk, Android package MIME type, and valid APK metadata. The latest CI again passed all four profile-pack privacy tests; the public iOS setup path and source-linked market table remain present on the live website.
- Optimized release run 32696765564 published arm64 and armv7-only R8/resource-shrunk release-mode, debug-signed APKs at 22,761,017 and 20,431,781 bytes. Crash-reporting release run 32698585376 compiled the native recorder and permission-return guards successfully, published arm64 at 22,761,197 bytes, and Pages run 32699124993 deployed its metadata.
- Final reminder release run 32704415302 published optimized evaluation APKs at 22,827,617 bytes (arm64) and 20,498,381 bytes (armv7); the arm64 direct link returned HTTP 206. Pages run 32705047477 published the Arabic-first guide, current release links, iOS Screen Time/Network Extension prerequisites, local reminder behavior, and the source-linked market table. CI run 32704415349 passed the new VPN result, task reminder, profile-pack privacy, and diagnostics tests; its only remaining failures are the two pre-existing DomainRulesTabs widget tests. Physical permission reproduction and iOS device provisioning remain user-device validation steps.
- Diagnostic privacy hardening run 32705781519 passed the strengthened test with injected task label and `.m4a` path text; the only CI failures remain the two legacy DomainRulesTabs widget tests. Release run 32705781517 published the same optimized artifact size with the hardening included; arm64 direct download again returned HTTP 206.
- First-run onboarding CI run 32708757345 passed all four new prayer-default and country/onboarding persistence tests. It retained only the two legacy DomainRulesTabs widget failures, for 46 passing and 2 failed. Release run 32708757521 published the Android onboarding update; arm64 is 22,827,617 bytes and direct download returned HTTP 206.
- Package conflict investigation confirmed the public workflow falls back to the runner debug signing configuration when no release/evaluation keystore is configured. A fresh runner key cannot replace an installed package signed with a different certificate. Commit 5d7add0 adds optional stable evaluation signing via repository secrets and Arabic/English recovery guidance; those secrets must be configured before future APKs will be in-place upgradeable.
- Unified children-management CI run 32712083795 passed the three new schedule default tests; the only retained failures were the legacy DomainRulesTabs tests, for 49 passing and 2 failed. Release run 32712083849 published arm64 at 22,827,297 bytes and armv7 at 20,514,445 bytes; the arm64 direct link returned HTTP 206.
- Kids-management CI run 32715455856 passed the empty-state and newly-added-child widget tests. It retained only the two legacy DomainRulesTabs failures, for 51 passing and 2 failed. Release run 32715455924 published arm64 at 22,827,545 bytes and armv7 at 20,514,693 bytes; the arm64 direct link returned HTTP 206. Website deployment run 32715455786 succeeded.
- Local release script verification correctly stopped before building because Flutter is not installed in this sandbox; its debug allowance is gated behind the same prerequisite check. DomainRulesTabs no longer disposes a dialog controller while its closing route still renders. CI run 32719389597 passed the full Dart test suite, Android build, and unsigned iOS build after correcting the DNS protocol setup and Screen Time extension embedding metadata.
- Pages run 32725381295 deployed client-side APK ABI selection. A browser that does not expose CPU architecture was live-verified to keep armv7 selected and display an explicit arm64 manual fallback; no architecture data is sent or stored by the site.
- CI run 32727840376 passed Dart analysis, 62 tests, Android builds, and unsigned iOS build after guarding monitoring behind Accessibility, persisting the monitoring flag before native service start, and adding birth-date profile recommendations that preserve parent selections.
- Public Flutter CI run 32730935333 is validating the prayer-lock release and PIN keyboard fixes. GitHub CLI Actions queries are temporarily unavailable because its stored token became invalid; the public Actions page remains usable for status checks.
- Public CI run 32730935333 has completed Dart analysis/tests and the manual Android APK job successfully; the unsigned iOS and standard Android build jobs are still running at this checkpoint.
- Flutter CI run 32729774777 passed the parent report, educational-expert contact, and Quick Settings implementation. Flutter CI run 32730935333 passed Dart analysis/tests, debug Android builds, and the unsigned iOS build after adding prayer-owned overlay release, strict-lock kiosk release, and Arabic-numeral PIN keyboard regression coverage.
- Android’s official Quick Settings guidance confirms that Android 13+ `requestAddTileService()` presents a user approval prompt; users can manually add a declared tile from Quick Settings edit mode on supported earlier versions. Source: https://developer.android.com/develop/ui/views/quicksettings-tiles
- Public Flutter CI run 32732299962 is validating the Quick Settings unlock requirement in commit d8a2a4c; it was still in progress at the latest check.
- Flutter CI run 32732299962 was superseded by the newer dev commit; Flutter CI run 32732912006 is now validating the walkthrough and email-draft encoding update.
- In Flutter CI run 32732912006, analysis/tests and both Android build jobs completed successfully; the unsigned iOS validation job was still running at the latest check.
- Flutter CI run 32732912006 passed Dart analysis/tests, both Android builds, and the unsigned iOS build for the Quick Settings unlock safeguard, feature walkthrough, and email-draft encoding updates.
- Flutter CI run 32815290397 passed analysis/tests, the manual Android APK, Android debug build, and unsigned iOS build for the active-child handover reminder. The previous run 32814935789 failed only because `Icons.handoff_outlined` is unavailable in the configured Material SDK; its supported-icon follow-up is included in this passing run.
- Website checkpoint f1d3790e adds a hosted 8-second shared-device setup video and a bilingual print-ready family handover checklist. The site is ready for the owner to publish from the website interface.
- Commit e128148 adds the opt-in automatic local Azan recording at calculated prayer start times, separate from the existing two-minute parent reminder. Flutter CI 32857414628 passed analysis/tests, manual Android APK, Android debug build, and unsigned iOS build. Physical-device checks remain necessary for exact-alarm approval, Android OEM battery behavior, iPhone notification sound delivery, and actual recording playback.

## Follow-up recommendations
- [ ] Add a QR download section that points to the current public APK/download URL and is included in the printable handover checklist.
- [ ] Create and upload a longer truthful Arabic-narrated shared-device setup video, without describing it as a physical-device recording unless it is one.
- [ ] Run automated handover regression checks and document the physical-device validation steps; physical hardware testing requires the user’s device.

Verification note: the previous three core recommendations are already present: setup video, printable checklist, and active-child handover reminder.

## Crash-reporting follow-up
- [ ] Review the current diagnostic-report and error-capture architecture and choose an email-capable delivery path that does not export sensitive child data.
- [ ] Implement sanitized crash capture with explicit parent consent, local retry/queue behavior, and a safe email/report endpoint or handoff.
- [ ] Add regression tests proving names, birth dates, PINs, recordings, usage, domains, diagnostics, and local paths are excluded; validate Android and iOS builds.

## Follow-up completion record
The QR download block now points to the maintained public ARM64 APK release and is included in the printable handover sheet. The Arabic narrated setup video is 22.2 seconds long and uses the approved visual demo with locally generated narration; it does not claim to be a physical app recording. The landing page checkpoint is `manus-webdev://290b1b97`.

The app’s existing local sanitized crash ring buffer now has a parent-approved “Send by email” action that opens the device mail composer with only sanitized categories, timestamps, allowlisted events, and safe stack locations. No background email is attempted, because mobile platforms do not provide a reliable silent mail send and automatic export of child/device data would violate the app’s privacy boundary. Commit `c4dd6f9` is aligned with `origin/dev`; Flutter CI #113 passed analysis/tests, manual Android APK, Android debug build, and unsigned iOS build. Physical device testing still requires the user’s Android/iOS hardware.

## Latest requested follow-up
- [ ] Pull the latest dev branch and inspect the user-provided monitoring-start crash fix before making changes.
- [ ] Make required settings open directly after permissions are granted on first install, with a safe return to the app.
- [ ] Automatically discover installed apps and place them into the existing categories without exporting app or child data.
- [ ] Make Manage Apps show blocked apps only, with a clear empty state when no apps are blocked.
- [ ] Add focused regression coverage, update the website, push the app changes, and validate the authoritative CI builds.

- [ ] After first-install required setup completes, offer the parent an optional action to add the existing 3ialna child-switch shortcut to Android Quick Settings.

## Completion order update
- [ ] Finish the current setup-flow, automatic app categorization, blocked-only Manage Apps, and Quick Settings shortcut work first.
- [ ] Then re-check and complete the earlier pending shared-device recommendations, crash-report email flow, website checkpoint/publication handoff, and physical-device validation instructions.

## Latest implementation completion record
The latest `dev` pull was applied before source changes. Commit `4d45d27` is aligned with `origin/dev`; Flutter CI #115 passed Analyze and test, Manual installable Android APK, Build Android APK, and Validate iOS build. The first-run flow now redirects to the parent setup dashboard after required permissions, offers the one-time Quick Settings shortcut invitation after setup, reconciles known installed apps into local categories without overwriting parent assignments, and opens Manage Apps with blocked apps only by default. The landing page checkpoint is `manus-webdev://3c71dc15`; desktop and mobile previews plus TypeScript validation passed. Physical-device testing remains outstanding.

## Prayer-time and final recommendation follow-up
- [ ] Pull latest dev before editing and verify current prayer-lock title/row structure.
- [ ] Find and document a free, redistributable Azan recording; bundle it only if licensing and asset-size limits are clear.
- [ ] Show the calculated prayer time beside every prayer-lock title and use the verified local Azan as the default automatic prayer audio.
- [ ] Localize remaining Manage Apps controls and empty states in Arabic/English.
- [ ] Add automated coverage for prayer-time labels and defaults; document Android 13+ Quick Settings, permission-return, and OEM testing steps.
- [ ] Update and verify the landing page, push the app, monitor CI, and checkpoint the website.

## PUI pause and iOS automation
- [ ] Keep the current prayer-time/default-Azan and landing-page changes paused under label PUI; do not discard them.
- [ ] Review the iOS bundle identifier, Firebase config, and current GitHub workflows for automatic build compatibility.
- [ ] Configure secure GitHub Actions iOS build and optional Firebase App Distribution delivery for com.ialna.app after Apple signing prerequisites are available.
- [ ] Validate workflow YAML and document the required Apple/GitHub/Firebase secrets without committing certificates, provisioning profiles, or service-account files.

## Signed iOS Firebase distribution
- [ ] Preserve the paused PUI changes while configuring signed iOS distribution.
- [ ] Guide the owner to create/export the Apple distribution certificate and provisioning profile for `com.ialna.app`.
- [ ] Add the signed macOS GitHub Actions workflow and Firebase App Distribution upload step using secrets only.
- [ ] Validate workflow YAML and monitor the first signed build after all required secrets are present.

- [ ] Verify required iOS signing and Firebase secret names are present without reading or exposing secret values.
- [ ] Add and validate the signed macOS iOS/Firebase distribution workflow, then monitor its first run.

- [ ] Confirm the corrected Apple certificate, provisioning-profile archive, and Firebase iOS App ID secrets are recognized by a signed workflow run without exposing values.
- [ ] Monitor IPA signing/export and Firebase upload; fix only workflow issues and preserve the paused PUI source edit.

Signed iOS workflow attempt #2 was rerun after the owner reported corrected secrets, but GitHub still reported these four names missing: `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_PROVISIONING_PROFILES_BASE64`, and `FIREBASE_IOS_APP_ID`. The workflow itself reached the secret gate and did not expose values. The PUI `app_card.dart` edit remains unstaged and `todo.md` remains untracked.

## Resume PUI
- [ ] Resume the paused prayer-time labels, default Azan, and Manage Apps localization work without changing signed-iOS workflow files.
- [ ] Complete focused PUI regression validation and push only the intended app changes.
- [ ] Update the landing page with Google Play/Android installation guidance, source verification, unknown-app permission guidance, and an explicit recommendation to keep Play Protect enabled; do not publish global Play Protect-disable instructions.
- [ ] Verify the website, checkpoint it, and report that the signed-iOS secret setup remains deferred.

## Islamic and family-safety app research
- [x] Compare Islamic child/family apps, parental-control apps, and adjacent family utilities using current public evidence.
- [x] Identify small features that improve parent and child experience without weakening 3ialna's Arabic-first, local-only privacy model.
- [x] Produce a prioritized feature list with rationale, dependencies, risks, and suggested rollout order.

## Recommended first-release improvements
- [ ] Add local reason-based Pause/Resume with parent-controlled duration and child-facing explanation.
- [ ] Add privacy-safe per-child daily summaries for time, categories, blocked attempts, and approved extensions.
- [ ] Add a parent-only Reliability Center for required permissions and background-reliability status with direct settings routes.
- [ ] Add regression tests for pause/resume, report filtering, privacy boundaries, and reliability-state rendering.

## Gamification MVP
- [ ] Add parent voice celebrations using locally stored recordings.
- [ ] Add offline parent-defined non-screen rewards per child.
- [ ] Add local Flex/Grace tokens with parent-controlled limits and expiry.
- [ ] Add child requests with parent approval and no automatic approval.
- [ ] Add Arabic/English UI and privacy regression tests.

## Reward token hardening
- [ ] Clamp corrupted negative token balances to zero.
- [ ] Prevent duplicate approval from consuming tokens or extending app access twice.
- [ ] Serialize token read-modify-write operations to avoid lost updates under concurrency.
- [ ] Add regression tests for corruption, duplicate approval, concurrency, bounds, and privacy fields.

## Versioned reward repository and website documentation
- [ ] Implement versioned typed local reward/request persistence with validation and migration hooks.
- [ ] Preserve serialized writes and atomic one-time approval semantics.
- [ ] Add repository migration, corruption, concurrency, and privacy tests.
- [ ] Update landing page in Arabic and English with the child-request and parent-approval journey.
- [ ] Validate, checkpoint website, and push app changes.

## Request inbox and configurable durations
- [ ] Add parent-configurable request duration choices and persist them locally.
- [ ] Use the configured choices in the child blocked-app request flow.
- [ ] Add a pending-request count badge and parent inbox entry.
- [ ] Add Android-focused regression coverage and physical-device steps for concurrency and duplicate approval.
- [ ] Run CI, push the implementation, and report any device-only validation limits.

## Request overlay and approval inbox UI specification
- [ ] Document component hierarchy and state model for child requests and parent approval.
- [ ] Define Arabic-first wireframes, bilingual copy, accessibility, privacy, and responsive behavior.
- [ ] Add implementation acceptance criteria and test scenarios.

## Complete request overlay and approval inbox UI refactor
- [ ] Extract reusable child request button, duration dialog, and pending banner.
- [ ] Extract parent pending badge, request card, and authenticated approval sheet.
- [ ] Move request/inbox copy into Arabic and English localization resources.
- [ ] Add dedicated widget and privacy regression tests.
- [ ] Run CI, fix issues, and push the complete refactor.

## Website and Play Store release preparation
- [ ] Finish CI validation for the extracted request and approval UI.
- [ ] Update the bilingual website with the child request and parent approval journey.
- [ ] Write local command-line instructions for safe push and automatic release workflows.
- [ ] Prepare Android Play Store release configuration and a submission checklist without publishing.
- [ ] Validate website, save a checkpoint, and push repository documentation/configuration changes.

## Final release follow-up

- [x] Re-authenticate GitHub CLI and verify all jobs for the latest Flutter CI run.
- [ ] Verify production Android upload-key and Play App Signing configuration, then build and validate a signed AAB through Internal testing. Blocked pending repository access to confirm signing secret names/values and Play Console account-side setup.
- [x] Review the final landing-page copy and save the final website checkpoint. Publication remains a user-side Management UI action.
- [x] Audit and reorder Android installation, first-run permission, settings-return, and verification guidance for the clearest user journey; align the website and app copy.

## Android package-conflict remediation

- [x] Compare the signing certificates of the current public APK and the newly generated build; identify whether the installed package can be upgraded in place.
- [x] Make the public evaluation release use a stable signing certificate and document the one-time migration path when an older certificate cannot be reused.
- [x] Publish a new APK release, update bilingual website download metadata and instructions, and verify the direct link.

## Reusable release skill and landing-page download UX

- [x] Create and validate a reusable skill for stable Android release signing, direct-link verification, website metadata synchronization, and package-conflict remediation.
- [x] Add a QR code that encodes the verified stable-signed APK URL and place it in the bilingual landing page download section.
- [x] Add accessible visual feedback to the landing-page download action, with reduced-motion support and desktop/mobile verification.

## APK sharing action

- [x] Add bilingual Share control beside the APK download link with native Web Share support and copy-link fallback.
- [x] Verify share feedback, keyboard accessibility, responsive layout, and preserved direct-download/QR behavior.

## Share control and custom Manus domain

- [x] Add a bilingual Share control beside the APK download link with native share-sheet support and copy-link fallback.
- [x] Validate share feedback, keyboard access, mobile layout, and preserved download/QR behavior.
- [ ] Check availability of `3ialna.manus.space` and assign it through Manus hosting settings if available; otherwise report the exact domain constraint and keep the generated domain active.

## Direct sharing shortcuts and clipboard tooltip

- [x] Extend the reusable release/download skill with WhatsApp, Telegram, and clipboard-feedback patterns.
- [x] Add bilingual WhatsApp and Telegram share shortcuts beside the general Share action.
- [x] Show an accessible localized “Copied!” tooltip/status after successful clipboard fallback and validate all sharing paths.

## Social previews, troubleshooting FAQ, and language toggle

- [x] Extend the reusable release/download skill with Open Graph metadata, localized FAQ, and language-toggle verification patterns.
- [x] Add branded Open Graph and Twitter metadata for WhatsApp and Telegram shared links in both website variants.
- [x] Create bilingual FAQ entries for APK installation, package conflicts, Play Protect, permissions, and settings return behavior.
- [x] Verify the Arabic/English toggle, build both sites, push the GitHub Pages source, and checkpoint the Manus site.

## Localized FAQ schema and accordion

- [x] Extend the reusable release/download skill with localized FAQ JSON-LD and accordion accessibility guidance.
- [x] Add language-aware FAQPage JSON-LD to the Manus-hosted document and runtime metadata.
- [x] Add matching localized FAQPage JSON-LD and accessible accordion behavior to the GitHub Pages source.
- [x] Build, inspect schema output, verify keyboard/expanded states, push GitHub Pages, and checkpoint Manus hosting.


## FAQ transitions and Contact Support action

- [x] Add smooth reduced-motion-aware expand/collapse transitions while preserving native hidden semantics and keyboard accessibility in both landing-page variants.
- [x] Add a bilingual Contact Support button below the FAQ, route it to the existing support/contact destination, verify responsive layout, build both variants, and publish the update.


## Deep application validation

- [x] Inventory Flutter modules, platform bridges, persistence, services, and current test coverage.
- [x] Run formatting, static analysis, unit/widget tests, coverage, Android checks, iOS checks, and tablet-oriented tests where the environment permits.
- [x] Identify and add regression tests for uncovered lifecycle, permission, multi-child, profile, reminder, privacy-export, usage-report, and responsive-layout scenarios.
- [x] Re-run the authoritative validation suite and document physical-device-only scenarios, blockers, and residual risks.


## Physical Android matrix and deep-test presentation

- [x] Define a reproducible Android permission and notification matrix with expected outcomes, evidence, and reset steps.
- [x] Prepare accurate deep-test presentation content from the passing CI run and coverage artifact.
- [x] Generate, verify, and present the deep-test slide deck.
