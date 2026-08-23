# iOS safeguard and market comparison research

This note records the implementation boundary for the iOS child-profile safeguards and the public comparison table. It is a product-planning document, not a clinical recommendation or a claim that third-party products are equivalent across every operating system, subscription plan, or country.

## iOS child-profile safeguards

Apple’s Screen Time API suite consists of **Family Controls**, **Managed Settings**, and **Device Activity**. With guardian approval, an app can use Managed Settings to shield selected applications, categories, or websites, while Device Activity extensions can execute on the child device and observe schedules without the host app being opened.[1][2][3]

| Requirement | Supported iOS route | Important boundary |
|---|---|---|
| Parent chooses apps/categories to protect | `FamilyActivityPicker` and privacy-preserving application/category tokens | iOS intentionally does not reveal normal package identifiers; a parent selection is required. |
| Sleep window | Device Activity schedule + Managed Settings shield | Requires a Device Activity Monitor extension, Family Controls entitlement, approval, and an iOS 16+ device. It shields the selected apps/categories rather than using Android’s Device Admin lock. |
| Prayer window | A non-repeating Device Activity schedule for each calculated prayer window + Managed Settings shield | Prayer calculation remains in 3ialna; the app must refresh the next day’s schedules. The child profile controls whether windows are scheduled and their duration. |
| Unlock/exception UX | Managed Settings shield action/configuration extensions | The available action UI is Apple’s shield experience, not a silent forced device lock. |
| Web filtering | Existing Network Extension/DNS route, subject to Apple entitlement and distribution approval | The DNS extension must use a registered provider bundle identifier and required Network Extension capability. |

> Apple requires the Family Controls entitlement for the app and Screen Time extensions. Development provisioning is available through the Apple Developer Program, but TestFlight/App Store distribution needs Apple’s distribution entitlement approval.[1]

The iOS build must therefore present these controls honestly as **Screen Time app/category shields**. It must not promise a universal physical device lock, access to app package names, or unsupervised background enforcement when the Family Controls entitlement, guardian approval, or the companion extension targets are absent.

## Comparator selection and documented features

The comparison will use 3ialna alongside four established products with public, first-party documentation: Google Family Link, Qustodio, Bark, and Norton Family. The table will use a compact **available / not documented / planned** legend rather than infer support from marketing language. Availability differs by platform and plan, so the public page will link to each supplier’s own current documentation.

| Product | First-party documented strengths relevant to the comparison | Geographic and platform caveat |
|---|---|---|
| 3ialna | Local parent-managed child profiles, Arabic-first UI, category-wide social/games budgets, custom DNS/domain rules, prayer-aware and sleep profile defaults, and parent-recorded voice notifications. | Android safeguards are currently the operational focus; iOS Screen Time integration requires Apple entitlement and extension setup. |
| Google Family Link | Daily limits, school time/downtime, individual app limits and blocking, Google-service content controls, location, and Android/ChromeOS remote locking.[4][5] | Its documented remote lock is for Android/ChromeOS; it is account- and Google-service oriented. |
| Qustodio | Web/app filtering, app limits, routines, location, reports, activity monitoring, and platform-specific social/call/SMS monitoring.[6][7] | Feature availability varies by platform and plan; Qustodio’s feature page publishes separate Android and iOS lists. |
| Bark | Screen-time schedules, app/site blocking, location, and content-safety alerts; Bark describes its iOS content-monitoring limitations and its separate Sync workflow.[8] | Bark states its app availability is currently limited to the United States, South Africa, and Australia and that deeper iOS monitoring uses Bark Sync.[8] |
| Norton Family | Time schedules, web/search/video supervision, school-time controls, alerts, reports, location, and platform-qualified app supervision.[9] | Norton explicitly notes that not every feature is available on every platform; app supervision is documented for Android and Windows in its product FAQ.[9] |

## References

[1] [Apple, *Configuring Family Controls*](https://developer.apple.com/documentation/xcode/configuring-family-controls)

[2] [Apple, *Screen Time Technology Frameworks*](https://developer.apple.com/documentation/screentimeapidocumentation)

[3] [Apple, *Managed Settings*](https://developer.apple.com/documentation/managedsettings)

[4] [Google, *Family Link*](https://families.google/familylink/)

[5] [Google, *Manage your child’s screen time*](https://support.google.com/families/answer/7103340?hl=en)

[6] [Qustodio, *Features*](https://www.qustodio.com/en/features/)

[7] [Qustodio Help, *What is Qustodio and what can I do with it?*](https://help.qustodio.com/hc/en-us/articles/360005215597-What-is-Qustodio-and-what-can-I-do-with-it)

[8] [Bark, *Parental controls reimagined*](https://www.bark.us/)

[9] [Norton, *Norton Parental Control*](https://us.norton.com/feature/parental-control)
