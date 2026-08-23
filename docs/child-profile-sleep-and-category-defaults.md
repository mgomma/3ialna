# Child profile sleep and category default research

This note documents the evidence and product boundaries for the child-profile sleep windows, prayer defaults, and starter app registry. These are **parent-editable household defaults**, not individual medical instructions.

| Source | Relevant guidance | Product interpretation |
|---|---|---|
| American Academy of Sleep Medicine, [Child Sleep Duration Health Advisory](https://aasm.org/advocacy/position-statements/child-sleep-duration-health-advisory/) | Children aged 3–5 are recommended 10–13 hours of sleep per 24 hours; ages 6–12 are recommended 9–12 hours; ages 13–18 are recommended 8–10 hours. | Default night lock windows are selected to preserve an opportunity for sleep within these ranges: 19:30–07:00, 20:30–07:00, 21:30–07:00, and 22:30–07:00 respectively. Parents can change or disable them. |
| American Academy of Pediatrics, [Screen time guidelines](https://www.aap.org/en/patient-care/media-and-children/center-of-excellence-on-social-media-and-youth-mental-health/qa-portal/qa-portal-library/qa-portal-library-questions/screen-time-guidelines/) (updated 2025) | The AAP does not endorse a single time limit for every child or teen; balance, content, co-viewing, communication, sleep, and physical activity matter. | The app surfaces budgets, category assignment, sleep locks, and prayer locks as configurable family rules rather than claims of universal clinical limits. |
| Canadian Paediatric Society, [Digital media: Promoting healthy screen use](https://cps.ca/en/documents/position/digital-media) (reaffirmed 2025) | Bedroom screens can interfere with sleep duration and quality; the statement recommends individualised media plans, family review, and prioritising sleep. | Sleep locks are an opt-out child-profile default with a clear parent control, rather than a hidden or immutable restriction. |

## Category starter lists

Published wellbeing and sleep research does **not** prescribe a universal set of package names. The social-media and games lists in the app are therefore a transparent, maintained starter registry of widely used Android packages. Every entry is visible to the parent in App Management, and a parent can move any installed app to Social media, Games, or Not assigned. The category budget is shared across all apps in the category to prevent per-app reset behaviour.

| Category | Curated Android starter packages |
|---|---|
| Social media | Facebook (`com.facebook.katana`), Instagram (`com.instagram.android`), Threads (`com.instagram.barcelona`), X/Twitter (`com.twitter.android`), Snapchat (`com.snapchat.android`), TikTok (`com.zhiliaoapp.musically`, `com.ss.android.ugc.trill`), Reddit (`com.reddit.frontpage`), Discord (`com.discord`), Pinterest (`com.pinterest`), Tumblr (`com.tumblr`), and YouTube (`com.google.android.youtube`). |
| Games | Roblox (`com.roblox.client`), Minecraft (`com.mojang.minecraftpe`), Fortnite (`com.epicgames.fortnite`), PUBG Mobile (`com.tencent.ig`), Free Fire (`com.dts.freefireth`), Mobile Legends (`com.mobile.legends`), Clash of Clans (`com.supercell.clashofclans`), Clash Royale (`com.supercell.clashroyale`), Brawl Stars (`com.supercell.brawlstars`), Candy Crush Saga (`com.king.candycrushsaga`), and Subway Surfers (`com.kiloo.subwaysurf`). |

The registry is a product-maintained convenience list, **not a list prescribed by medical or wellbeing studies**. It is deliberately mirrored in Flutter persistence and Android enforcement, while an explicit parent assignment always takes precedence over a starter entry.

## Prayer locks

Prayer lock values are faith-aligned household defaults, not medical claims. Prayer times remain calculated from the parent’s configured location and calculation method. A child’s active profile controls whether the existing prayer window is enforced and the maximum number of minutes enforced after each prayer; parents can change or disable it per child.
