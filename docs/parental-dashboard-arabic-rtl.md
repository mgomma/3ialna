# 3ialna parental-control dashboard: Arabic RTL UI specification

## Localization principles

Arabic should be treated as a first-class interface rather than a translated fallback. All dashboard cards, tabs, chips, dialogs, timestamps, status messages, and error recovery actions must render in RTL when the active locale is Arabic. Technical terms should be explained in family language: use **الحماية** for protection, **النطاقات المحظورة** for blocked domains, **النطاقات المسموح بها** for allowed domains, and **طلب استثناء** for a child exception request.

The UI must not imply that DNS filtering is complete web safety. The Arabic copy should state that the VPN filters supported DNS traffic and may not cover direct IP access, applications that bypass the system resolver, or page content inside encrypted HTTPS traffic.

## Protection status card

| State | Arabic title | Arabic supporting text | Primary action | English fallback |
|---|---|---|---|---|
| Protected | الحماية مفعّلة | يعمل فلتر النطاقات على هذا الجهاز. | إيقاف الحماية | Protection is active / Stop protection |
| Policy disabled | سياسة المحتوى الآمن متوقفة | فعّل السياسة أولاً لتطبيق قواعد النطاقات. | تفعيل السياسة | Safe-content policy is off / Enable policy |
| Permission required | يلزم السماح باتصال VPN | يحتاج 3ialna إلى إذن VPN لتطبيق قواعد النطاقات على الجهاز. | منح الإذن | VPN permission required / Grant permission |
| VPN stopped | الحماية غير متصلة | السياسة مفعّلة، لكن فلتر الجهاز متوقف. | تشغيل الحماية | Protection is disconnected / Start protection |
| Starting | جارٍ تشغيل الحماية | نتحقق من اتصال الفلتر. | إلغاء | Starting protection / Cancel |
| Error | تعذر تشغيل الحماية | تحقق من إذن VPN ثم حاول مرة أخرى. | إعادة المحاولة | Protection could not start / Retry |
| Unsupported platform | غير متاح على هذا الجهاز | فلترة VPN متاحة حالياً على Android فقط. | معرفة المزيد | Not available on this device |

## Domain tabs

The first tab is **النطاقات المحظورة** with the count of explicit blocked rules. The second is **النطاقات المسموح بها** with the count of exceptions. The helper text is **تأخذ النطاقات المسموح بها أولوية على قواعد الحظر**. The add action is **إضافة نطاق**. The URL field label is **النطاق أو الرابط** and the normalization preview is **سيُحفظ كـ**.

The empty states should be actionable:

| Empty state | Arabic copy | Action |
|---|---|---|
| No blocked domains | لا توجد نطاقات محظورة مخصّصة. يمكنك استخدام فئات الحماية أو إضافة نطاق يدوي. | إضافة نطاق |
| No allowed domains | لا توجد استثناءات. ستظل قواعد الفئات مطبّقة على النطاقات غير المستثناة. | إضافة استثناء |
| No search results | لم نعثر على نطاق يطابق بحثك. | مسح البحث |
| Loading | جارٍ تحميل قواعد النطاقات… | None |
| Offline | لا يمكن مزامنة القواعد الآن. ستظهر آخر قواعد محفوظة على الجهاز. | إعادة المحاولة |

## Add-domain dialog

The dialog title is **إضافة نطاق**. The blocked action uses **حظر هذا النطاق** and the allowed action uses **السماح بهذا النطاق**. Before saving, show **سيتم تطبيق القاعدة على النطاق وجميع النطاقات الفرعية**. Validation messages are **أدخل نطاقاً صحيحاً مثل example.com** and **هذا النطاق موجود بالفعل**. For a broad domain, warn with **قد يؤثر هذا الاختيار على خدمات متعددة. هل تريد المتابعة؟**.

## Child exception requests

A child-facing request should use **طلب استثناء**. Required fields are **النطاق**, **السبب**, and an optional duration. Parent actions are **السماح مرة واحدة**, **السماح لمدة 15 دقيقة**, **السماح دائماً**, and **الإبقاء على الحظر**. The parent review card should show **طلب جديد**, **قيد المراجعة**, **تم السماح**, **مرفوض**, and **منتهي**. Do not expose internal rule IDs to children.

## Recent DNS decisions

The log heading is **آخر قرارات الحماية**. A blocked row should show **تم الحظر**, the normalized domain, the matched rule such as **فئة المقامرة** or **قاعدة يدوية**, the child/device name, and a relative timestamp. The empty state is **لا توجد قرارات مسجّلة بعد**. The privacy explanation is **نسجّل النطاق والقاعدة والوقت فقط، ولا نسجّل محتوى الصفحات أو الرسائل**.

## Error messages

| Condition | Arabic error | Recovery |
|---|---|---|
| VPN permission denied | لم يتم منح إذن VPN. لن تُطبّق فلترة الجهاز. | افتح إعدادات VPN وامنح الإذن |
| VPN already owned by another app | يوجد تطبيق آخر يستخدم اتصال VPN. أوقفه ثم حاول مرة أخرى. | إعادة المحاولة |
| Policy save failed | تعذر حفظ القاعدة. لم تتغير القواعد الحالية. | حاول مرة أخرى |
| Domain invalid | أدخل نطاقاً صحيحاً بدون مسار أو رموز إضافية. | تصحيح الإدخال |
| API unavailable | الخادم غير متاح حالياً. ستبقى آخر قواعد الجهاز محفوظة. | إعادة المحاولة |
| Unauthorized parent | انتهت جلسة الوالد. سجّل الدخول مرة أخرى لإدارة القواعد. | تسجيل الدخول |
