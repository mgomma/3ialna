export const publicSiteUrl = "https://mgomma.github.io/3ialna/";

export const androidInstallationSteps = {
  ar: [
    "استخدم هاتف Android 7 أو أحدث. افتح قسم التنزيل في موقع عيالنا الرسمي وحمّل أحدث APK. إذا لم تعرف نوع المعالج، اختر النسخة الشاملة (Universal).",
    "بعد اكتمال التنزيل، افتح إشعار التنزيل أو تطبيق الملفات ← التنزيلات، ثم اضغط ملف APK الخاص بعيالنا.",
    "إذا طلب Android إذن التثبيت، اضغط «الإعدادات» وفعّل «السماح من هذا المصدر» للمتصفح أو مدير الملفات الذي فتح الملف فقط. أبقِ Google Play Protect مفعّلًا؛ إذا ظهر تحذير أمني، توقف وراجع مصدر الملف أو تواصل مع الدعم. إذا كان الجهاز مُدارًا أو الإذن معطّلًا، تواصل مع الوالد أو مسؤول الجهاز.",
    "ارجع إلى ملف APK واضغط «تثبيت» أو «تحديث». تحديث النسخة الرسمية الموقّعة بالمفتاح نفسه يحافظ على البيانات. إذا ظهر تعارض في الحزمة أو فشل التحديث، لا تحذف التطبيق القديم؛ حذف التطبيق قد يمسح الأطفال والإعدادات والتسجيلات. تواصل مع الدعم للحصول على نسخة متوافقة.",
    "بعد التثبيت، أوقف «السماح من هذا المصدر» وافتح عيالنا. اتبع الجولة، وأنشئ PIN للوالد عند الطلب، وأضف الطفل وراجع إعدادات العمر قبل حفظها. بعد التحديث، راجع ملفات الأطفال الموجودة بدل إنشائها من جديد.",
    "من لوحة الوالد افتح مركز الموثوقية. لتتبع الوقت، افتح إعدادات Android وابحث عن «وصول الاستخدام» (Usage access)، ثم اختر عيالنا وفعّل السماح. إذا كان الخيار مقيدًا، اطلب المساعدة من الوالد أو مسؤول الجهاز.",
    "عند تفعيل حظر التطبيقات، امنح «الظهور فوق التطبيقات الأخرى» (Overlay) وخدمة إمكانية الوصول (Accessibility) المطلوبة، ثم ارجع إلى عيالنا للتحقق من الحالة. لا تمنح هذه الأذونات إلا للنسخة الرسمية الموثوقة؛ لا تتجاوز قيود إدارة الجهاز.",
    "لضبط الصلاة، اسمح بالموقع وراجع طريقة الحساب ومواقيت الصلاة. فعّل الإشعارات والمنبّهات الدقيقة عند الطلب. الأذان التلقائي على Android اختياري ويمكن تشغيله من إعدادات الصلاة.",
    "اختبر تذكير الأذان لدقيقة واحدة والشاشة مقفلة قبل الاعتماد عليه. صوت الأذان على Android يستخدم مستوى صوت الإشعارات؛ راجع هذا المستوى ووضع «عدم الإزعاج». رفع صوت المنبّه وحده قد لا يكفي. إذا تأخرت التذكيرات، راجع إعدادات بطارية عيالنا.",
    "جرّب حظر تطبيق غير أساسي ثم أزل الحظر، وتأكد من تحديث عدادات لوحة الوالد. لإلغاء حد يومي خاص بتطبيق، افتح «تعيين حد زمني» ثم «إزالة الحد». راجع الطفل النشط قبل تسليم الجهاز. مشرف الجهاز والقفل الصارم إعدادات متقدمة اختيارية وليسا شرطًا للتثبيت.",
  ],
  en: [
    "Use a phone running Android 7 or later. Open Download on the official 3ialna website and download the latest APK. If you are unsure about the processor, choose the Universal APK.",
    "When the download finishes, open its notification or Files → Downloads, then tap the 3ialna APK.",
    "If Android requests installation permission, tap Settings and enable Allow from this source only for the browser or file manager opening the file. Keep Google Play Protect enabled. If a security warning appears, stop and verify the source or contact support. If the device is managed or permission is disabled, contact the parent or device administrator.",
    "Return to the APK and tap Install or Update. An official update signed with the same key preserves data. If Android reports a package conflict or the update fails, do not uninstall the old app: uninstalling can erase children, settings, and recordings. Contact support for a compatible build.",
    "After installation, turn off Allow from this source and open 3ialna. Follow the tour, create a parent PIN when prompted, and add a child and review the age settings before saving. After an update, review existing child profiles instead of recreating them.",
    "Open Reliability Center from the parent dashboard. To track time, search Android Settings for Usage access, select 3ialna, and allow access. If this setting is restricted, ask the parent or device administrator for help.",
    "When enabling app blocking, grant the requested Display over other apps (Overlay) and Accessibility service permissions, then return to 3ialna to verify their status. Grant these only to the trusted official build; do not bypass device-management restrictions.",
    "For prayer setup, allow Location and review the calculation method and prayer times. Allow Notifications and exact alarms when prompted. Automatic azan on Android is optional and can be enabled in prayer settings.",
    "Run the one-minute azan test with the screen locked before relying on it. Android azan uses notification volume: check that volume and Do Not Disturb. Raising alarm volume alone may not help. If reminders are delayed, review Android battery settings for 3ialna.",
    "Test blocking a nonessential app and then unblock it; check the dashboard counters refresh. To remove a per-app daily limit, open Set Time Limit and choose Remove limit. Check the active child before handing over the phone. Device Admin and hard lock are optional advanced settings, not installation requirements.",
  ],
} as const;

export function getInstallationLinks(language: "ar" | "en") {
  const downloadUrl = `${publicSiteUrl}?lang=${language}#download`;
  const guideUrl = `${publicSiteUrl}?lang=${language}#setup`;
  const message = language === "ar"
    ? `تطبيق عيالنا لأمان العائلة.\nتنزيل Android: ${downloadUrl}\nدليل التثبيت خطوة بخطوة: ${guideUrl}`
    : `3ialna for family digital safety.\nAndroid download: ${downloadUrl}\nStep-by-step installation guide: ${guideUrl}`;
  return { downloadUrl, guideUrl, whatsappUrl: `https://wa.me/?text=${encodeURIComponent(message)}` };
}
