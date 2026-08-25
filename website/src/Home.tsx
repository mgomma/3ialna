import { useEffect, useMemo, useState } from "react";
import { ArrowDown, ArrowUp, ArrowUpRight, Check, ChevronDown, CircleHelp, Clock3, Download, ExternalLink, Globe2, LockKeyhole, Mail, Mic2, RotateCcw, Send, ShieldCheck, Smartphone, Sparkles } from "lucide-react";
import { QRCodeSVG } from "qrcode.react";
import { currentRelease } from "./release.generated";

const heroImage = "./assets/3ialna-hero-family.jpg";
const profileImage = "linear-gradient(135deg, rgba(23,74,59,.96), rgba(30,103,82,.72)), radial-gradient(circle at 72% 28%, rgba(231,184,104,.85) 0 9%, transparent 10%), linear-gradient(140deg, #c9b18a, #547b63 58%, #174a3b)";
const voiceImage = "linear-gradient(145deg, rgba(23,74,59,.9), rgba(23,74,59,.22)), radial-gradient(circle at 70% 30%, rgba(231,184,104,.92) 0 12%, transparent 13%), linear-gradient(35deg, #d9c7a9, #547b63 55%, #174a3b)";
const privacyIcons = [LockKeyhole, Mic2, RotateCcw, Clock3];
const publicSiteUrl = "https://mgomma.github.io/3ialna/";

type Language = "ar" | "en";
type AndroidAbi = "arm64" | "armv7";
type DetectionState = "checking" | AndroidAbi | "unknown";

type UserAgentData = {
  platform?: string;
  getHighEntropyValues?: (hints: string[]) => Promise<{
    architecture?: string;
    bitness?: string;
  }>;
};

type NavigatorWithUserAgentData = Navigator & {
  userAgentData?: UserAgentData;
};

const copy = {
  ar: {
    nav: ["جولة الخصائص", "تنزيل", "الإعداد", "الملفات العمرية", "المقارنة", "الخصوصية", "تواصل"],
    badge: "دليل الإعداد الرسمي · عيالنا",
    title: "احمِ وقت العائلة، لا خصوصيتها.",
    intro: "عيالنا يساعد الوالدين على بناء روتين رقمي هادئ يناسب عمر الطفل، مع رسائل صوتية بصوت الوالدين وإعدادات يمكن الرجوع عنها في أي وقت.",
    cta: "تنزيل النسخة التجريبية",
    secondary: "استكشف الخصائص",
    note: "متاح للاختبار على أجهزة Android. يتطلب منح أذونات الجهاز يدويًا.",
    guide: "جولة عيالنا في خمس محطات",
    guideIntro: "نفس ترتيب الجولة داخل التطبيق: ابدأ بالعائلة، ثم الحماية، فالتذكيرات، فالتقارير والخصوصية، وأنهِ بإعدادات الوالد المرنة.",
    walkthrough: [
      ["عائلتك أولاً", "أضف الأطفال، راجع تاريخ الميلاد، واختر الإعداد المناسب للعمر. يظهر الطفل النشط بوضوح عند مشاركة الجهاز."],
      ["الحماية والحدود", "فعّل المراقبة بعد منح الوصول المطلوب، ثم اضبط حدود الفئات والمواقع المسموحة والمحظورة وأوقات النوم والصلاة."],
      ["تذكيرات بصوت الوالد", "سجّل تذكيرات للمهام أو الصلاة. يفتح الإشعار عيالنا لتشغيل التسجيل المحلي، ولا يعمل الصوت تلقائياً في الخلفية."],
      ["تقارير وخصوصية", "راجع الاستخدام حسب التاريخ. تبقى التسجيلات والبيانات الحساسة على الجهاز، وأي مشاركة بالبريد تحتاج مراجعتك وموافقتك."],
      ["أنت المتحكم", "كل إعداد قابل للتعديل. أضف اختصار لوحة الإعدادات السريعة من إدارة الأطفال لتبديل الطفل النشط بسرعة أكبر."],
    ],
    privacy: "الخصوصية أولًا",
    privacyBody: "التحكم مبني على الوقت، التطبيقات، النطاقات، وروتين الصلاة. لا نحتاج إلى قراءة محادثات الطفل أو تحليل ما يكتبه.",
    install: "التثبيت والإعداد",
    installIntro: "اتبع هذه الخطوات بالترتيب على هاتف الوالد أو الجهاز الذي ستديره.",
    steps: [
      ["نزّل وثبّت Android", "استخدم زر التنزيل أو رمز QR، وافتح الملف على هاتف Android. اسمح بالتثبيت من المتصفح أو مدير الملفات لهذا التثبيت فقط، مع إبقاء Play Protect مفعّلًا."],
      ["أنشئ حماية الوالدين", "افتح عيالنا أولًا، أنشئ PIN للوالد، ثم فعّل البصمة لتصبح طريقة التحقق الافتراضية مع بقاء PIN كخيار احتياطي."],
      ["أضف الأطفال والإعدادات", "من إدارة الأطفال أضف طفلًا واحدًا على الأقل، اختر الطفل النشط وملفه العمري، ثم راجع حدود التواصل والألعاب والنوم والصلاة."],
      ["امنح الأذونات عند الحاجة", "ابدأ بالموقع لمواقيت الصلاة ووصول الاستخدام للحدود الزمنية. اطلب Overlay وAccessibility عند تشغيل الحماية، وDevice Admin اختياريًا للقفل الصارم فقط."],
      ["اختبر ثم أضف التذكيرات", "صنّف التطبيقات وجرّب الحماية قبل تسليم الجهاز. عند إنشاء تذكير، اسمح بالإشعارات والمنبّهات الدقيقة وسجّل صوت الوالد محليًا إذا رغبت."],
    ],
    androidInstallTitle: "تفصيل التثبيت على Android",
    androidInstallSteps: ["حمّل APK التجريبي من زر التنزيل أو QR على هاتف Android، ثم افتح الملف.", "اسمح بالتثبيت من المتصفح أو مدير الملفات لهذا التثبيت فقط، وأبقِ Play Protect مفعّلًا. إذا ظهر تعارض في الحزمة، فهذه النسخة موقعة بمفتاح مختلف؛ صدّر الإعداد قبل إزالة النسخة القديمة لأن بيانات الجهاز المحلية قد تُحذف.", "افتح عيالنا وأنشئ PIN للوالد، ثم فعّل البصمة إن كانت متاحة. لا تسلّم الجهاز للطفل قبل إكمال إعداد الوالد.", "افتح إدارة الأطفال، أضف طفلًا واحدًا على الأقل، اختر الطفل النشط وملفه العمري، ثم راجع حدود التواصل والألعاب والنوم والصلاة. إعداد الجدول مفعّل افتراضيًا من 09:00 إلى 21:00 ويمكن تعديله.", "امنح الموقع لمواقيت الصلاة ووصول الاستخدام للحدود الزمنية. بعد اختيار تشغيل الحماية، فعّل Accessibility وOverlay عند الطلب؛ سيعيدك Android إلى عيالنا عند الرجوع ليتحقق التطبيق من الحالة.", "فعّل الإشعارات والمنبّهات الدقيقة عند إنشاء تذكيرات أو أذان. افتح مهام وتذكيرات الطفل لتسجيل صوت الوالد واختيار التكرار كل ساعة أو كل ساعتين؛ يفتح الإشعار عيالنا لتشغيل التسجيل محليًا ولا يعمل تلقائيًا في الخلفية.", "فعّل Device Admin فقط إذا أردت تجربة القفل الصارم، وراجع تحسين البطارية إذا احتجت إلى موثوقية التذكيرات. كلاهما اختياري ويظل الحاجب المرئي بديلًا عند عدم توفره.", "صنّف التطبيقات المثبتة، راجع قواعد الفئات، نفّذ اختبارًا قصيرًا للحظر وتبديل الطفل، ثم سلّم الجهاز."],
    iosInstallTitle: "مسار iPhone وiPad",
    iosInstallSteps: ["تتطلب قيود iOS نظام iOS 16 أو أحدث، وحساب مطور Apple وإذن Family Controls للتوزيع.", "من داخل عيالنا افتح إعداد رقابة iOS، امنح إذن Screen Time، ثم اختر التطبيقات أو الفئات التي تريد Apple حمايتها.", "تطبق قواعد النوم والصلاة كشاشات حماية للتطبيقات أو الفئات التي اخترتها، وليست قفلًا ماديًا شاملًا للجهاز.", "تظهر تذكيرات المهام والصلاة كإشعارات محلية. يفتح زر تشغيل صوت الوالدين عيالنا لتشغيل التسجيل المحلي؛ لا يَعِد التطبيق بالتشغيل التلقائي في الخلفية على iPhone.", "تحتاج حماية الويب إلى Network Extension مسجلة وموافق عليها من Apple. لا تنشر نسخة iOS للمستخدمين قبل إكمال هذه المتطلبات في Apple Developer وTestFlight أو App Store."],
    packTitle: "مشاركة إعدادات بلا بيانات الأطفال",
    packBody: "من لوحة الوالدين اختر مشاركة إعداد. تسمي الحزمة باسم الإعداد واسم منشئها، وتحتوي القواعد القابلة لإعادة الاستخدام فقط. لا تتضمن أسماء الأطفال أو تواريخ الميلاد أو الجنس أو PIN أو الاستخدام أو التسجيلات أو أسماء مهام التذكير أو تسجيلاتها. عند الاستيراد تُطبق الحزمة على الطفل النشط ولا تنشئ طفلاً جديدًا.",
    comparisonTitle: "مقارنة شفافة للخصائص",
    comparisonIntro: "هذه مقارنة نطاق، وليست ترتيبًا أو مراجعة أمنية. تعتمد الخانات على صفحات الخصائص الرسمية المرتبطة أدناه؛ تختلف الإمكانات باختلاف المنصة والخطة والبلد.",
    comparisonHeaders: ["الخاصية", "عيالنا", "Google Family Link", "Qustodio", "Bark", "Norton Family"],
    comparisonRows: [["حدود الوقت والجداول", "نعم", "نعم", "نعم", "نعم", "نعم"], ["حظر/تصنيف التطبيقات", "نعم؛ فئات مشتركة", "نعم؛ حدود لكل تطبيق", "نعم", "نعم", "محدود حسب المنصة"], ["قفل النوم", "نعم؛ قابل للتعديل", "وقت التوقف", "روتين/وقت نوم", "جداول", "جداول"], ["قفل الصلاة", "نعم؛ وفق موقع الوالد", "—", "—", "—", "—"], ["رسائل الوالد الصوتية", "نعم؛ محلية", "—", "—", "—", "—"], ["حزم إعداد مجهولة هوية الأطفال", "نعم", "غير موثق", "غير موثق", "غير موثق", "غير موثق"], ["إرشاد iOS", "Screen Time؛ إعداد Apple مطلوب", "تختلف بحسب الجهاز", "قائمة iOS منشورة", "قيود iOS موثقة", "تختلف بحسب المنصة"]],
    comparisonSources: "مصادر المقارنة",
    profiles: "إعدادات جاهزة حسب العمر",
    profilesIntro: "ابدأ من نقطة مناسبة للعمر ثم عدّلها حسب عادات طفلك. تُحتسب كل التطبيقات المصنفة ضمن التواصل أو الألعاب من ميزانية يومية مشتركة، ويمكن للوالدين تغيير كل قيمة أو إعادة الضبط.",
    profileNames: ["دون 5 سنوات", "من 5 إلى 9", "من 9 إلى 13", "المراهقون 13–18"],
    profileDetails: ["تواصل: 0 د · ألعاب: 30 د · صلاة: 10 د · نوم: 19:30–07:00", "تواصل: 0 د · ألعاب: 45 د · صلاة: 15 د · نوم: 20:30–07:00", "تواصل: 30 د · ألعاب: 60 د · صلاة: 15 د · نوم: 21:30–07:00", "تواصل: 60 د · ألعاب: 90 د · صلاة: 15 د · نوم: 22:30–07:00"],
    profileNote: "هذه نقاط بداية قابلة للتعديل للترفيه فقط، وليست وصفة صحية فردية. راجع النوم، الدراسة، النشاط البدني، وجودة المحتوى مع طفلك. قفل الصلاة يعتمد على الموقع وطريقة الحساب التي يضبطها الوالد.",
    profileSources: "مصادر الإرشاد",
    categoryRegistryTitle: "قائمة الفئات الافتراضية",
    socialRegistry: "التواصل: Facebook، Instagram، Threads، X، Snapchat، TikTok، Reddit، Discord، Pinterest، Tumblr، YouTube.",
    gamesRegistry: "الألعاب: Roblox، Minecraft، Fortnite، PUBG Mobile، Free Fire، Mobile Legends، Clash، Brawl Stars، Candy Crush، Subway Surfers.",
    categoryRegistryNote: "هذه قائمة بداية شفافة وليست حكمًا على كل تطبيق. يستطيع الوالد نقل أي تطبيق مثبت بين التواصل والألعاب أو إزالته من الفئة.",
    voice: "رسالتك، بصوتك",
    voiceBody: "بدل صوت آلي عام، يمكن للوالدين تسجيل رسالة دافئة تُستخدم ضمن روتين التنبيه. النص المكتوب يظل ظاهرًا، والتسجيل لا يغادر الجهاز.",
    privacyTitle: "حماية عملية بلا مراقبة خفية",
    privacyPoints: ["لا قراءة للمحادثات أو صفحات الويب", "تخزين التسجيلات والإعدادات محليًا", "الوالد يملك التعديل والرجوع والإيقاف", "إشعارات مكتوبة وصوتية قابلة للتخصيص"],
    faq: "أسئلة شائعة",
    faqItems: [["هل يقرأ عيالنا رسائل الطفل؟", "لا. يعتمد التطبيق على حدود الوقت، التطبيقات، النطاقات، والأذونات المطلوبة للتنفيذ."], ["هل يمكن تغيير الملف العمري؟", "نعم. يمكن اختيار أي ملف، تعديل قيمه، أو إعادة الملف الحالي إلى الإعداد الافتراضي."], ["أين يُحفظ التسجيل الصوتي؟", "محليًا على الجهاز الذي سجّله الوالد. لا يتم رفعه إلى خادم من خلال هذه الميزة."], ["هل يعمل iPhone بنفس الطريقة؟", "تختلف أذونات iOS عن Android. استخدم Family Controls وNetwork Extension وفق دليل iOS داخل المشروع." ]],
    finalCta: "اجعل الإعداد مفهومًا من اليوم الأول.",
    finalBody: "شارك هذه الصفحة مع العائلة، ثم افتح التطبيق واختر الملف الذي يناسب طفلك.",
    download: "تنزيل APK للاختبار",
    releaseKicker: "03 / إصدار Android التجريبي",
    releaseTitle: "نسخة Android التجريبية متاحة للتنزيل المباشر",
    releaseBody: "ابدأ بالنسخة الأصغر المناسبة للتجربة على هاتف Android. إذا لم يقبل الهاتف تثبيتها، استخدم بديل arm64 المدرج أدناه. لا تحتاج إلى دعوة اختبار أو تسجيل الدخول إلى Firebase.",
    releasePlatform: "Android",
    releaseVersion: "0.1.0 · البنية 1",
    releaseChannel: "إصدار تقييم عام",
    releaseButton: "تنزيل النسخة الأصغر · armv7",
    releaseNotice: "هذه نسخة تقييم وليست إصدار متجر. قد يطلب Android السماح بالتثبيت من المتصفح أو مدير الملفات. إذا ظهرت رسالة «يتعارض مع حزمة موجودة»، فالتطبيق القديم موقّع بمفتاح مختلف. لا تحذفه قبل تصدير إعداد قابل للمشاركة؛ الحذف يمسح بيانات الأطفال وPIN والتسجيلات والاستخدام المحلية.",
    apkChoiceTitle: "إذا لم يتم التثبيت، جرّب البديل المناسب لهاتفك",
    apkChoiceArm64: "بديل للهواتف الحديثة التي لا تقبل النسخة الأصغر · arm64",
    apkChoiceArmv7: "النسخة الأصغر للتجربة أولاً · armv7",
    autoChoiceChecking: "يتم فحص توافق المعالج محليًا…",
    autoChoiceArm64: "اكتشف المتصفح ARM64؛ تم اختيار arm64 تلقائيًا.",
    autoChoiceArmv7: "اكتشف المتصفح معالجًا غير ARM64؛ تم اختيار armv7 الأصغر تلقائيًا.",
    autoChoiceUnknown: "لم يشارك المتصفح معمارية المعالج؛ أبقينا armv7 الأصغر. اختر arm64 يدويًا إذا لم يتم التثبيت.",
    requestInvite: "تحتاج إلى مساعدة؟ تواصل معنا",
    testerQrTitle: "امسح لتنزيل النسخة الأصغر",
    testerQrBody: "يفتح تنزيل armv7 على هاتف Android دون تسجيل دخول.",
    siteQrTitle: "امسح لمشاركة الدليل",
    siteQrBody: "افتح صفحة الإعداد على أي هاتف.",
    releaseUpdated: "آخر تحديث",
    footer: "عيالنا · أمان رقمي يحترم العائلة",
    contactKicker: "08 / تواصل",
    contactTitle: "هل تحتاج إلى مساعدة في الإعداد؟",
    contactBody: "أرسل لنا رسالتك، وسيتلقى فريق عيالنا التفاصيل عبر البريد. يرجى عدم إرسال أرقام سرية أو معلومات شخصية حساسة.",
    name: "الاسم",
    email: "البريد الإلكتروني",
    subject: "الموضوع",
    message: "كيف يمكننا المساعدة؟",
    submit: "إرسال الرسالة",
    sending: "جارٍ الإرسال…",
    contactSuccess: "شكرًا لك. وصلت رسالتك إلى فريق عيالنا.",
    contactError: "تعذر إرسال الرسالة الآن. حاول مرة أخرى لاحقًا.",
  },
  en: {
    nav: ["Feature tour", "Download", "Setup", "Age profiles", "Comparison", "Privacy", "Contact"],
    badge: "Official setup guide · 3ialna",
    title: "Protect family time, not private conversations.",
    intro: "3ialna helps parents build a calmer digital routine by age, with parent-recorded voice messages and settings they can edit or reset at any time.",
    cta: "Download the test release",
    secondary: "Explore the features",
    note: "Available for Android testing. Device permissions must be granted manually.",
    guide: "The 3ialna tour in five steps",
    guideIntro: "The same sequence used in the app: family first, then protection, reminders, reports and privacy, and finally parent-controlled settings.",
    walkthrough: [
      ["Your family, first", "Add children, review birth dates, and choose an age-appropriate baseline. The active child is always clear when the device is shared."],
      ["Protection and limits", "Start monitoring after granting required access, then set category budgets, allowed and blocked sites, and editable sleep and prayer schedules."],
      ["Parent voice reminders", "Record task or prayer reminders. A notification opens 3ialna to play the local recording; it does not autoplay in the background."],
      ["Reports and privacy", "Review usage by date. Recordings and sensitive data stay on the device, and any email sharing requires your review and consent."],
      ["You stay in control", "Every setting remains editable. Add the Quick Settings shortcut from Kids management for faster active-child switching."],
    ],
    privacy: "Privacy by design",
    privacyBody: "Controls are based on time, apps, domains, and prayer-aware routines. The app does not need to read a child’s conversations or analyze what they type.",
    install: "Install and configure",
    installIntro: "Follow these steps in order on the parent phone or the device you manage.",
    steps: [["Download and install Android", "Use the download button or QR code, then open the file on an Android phone. Allow installation from the browser or file manager for this install only, and keep Play Protect enabled."], ["Create parent protection", "Open 3ialna first, create a parent PIN, then enable biometrics as the preferred method with PIN fallback."], ["Add children and settings", "Open Kids management, add at least one child, choose the active child and age profile, then review social, games, sleep, and prayer limits."], ["Grant permissions when needed", "Start with location for prayer times and Usage Access for time limits. Request Overlay and Accessibility when enabling protection; Device Admin is optional for hard lock only."], ["Test, then add reminders", "Categorize apps and test protection before handing over the device. When creating a reminder, allow notifications and exact alarms, and record a parent voice note locally if desired."]],
    androidInstallTitle: "Detailed Android installation",
    androidInstallSteps: ["Download the evaluation APK from the download button or QR code on an Android phone, then open the file.", "Allow installation from the browser or file manager for this install only, and keep Play Protect enabled. If Android reports a package conflict, this build has a different signing key; export setup before uninstalling because local device data may be removed.", "Open 3ialna, create a parent PIN, and enable biometrics where available. Do not hand over the device until parent setup is complete.", "Open Kids management, add at least one child, choose the active child and age profile, then review social, games, sleep, and prayer limits. The default schedule is 09:00–21:00 and remains editable.", "Grant Location for prayer times and Usage Access for time limits. After choosing to enable protection, grant Accessibility and Overlay when prompted; Android returns to 3ialna so the app can re-check the status.", "Grant Notifications and exact alarms when creating reminders or prayer alerts. In Child tasks and reminders, record a parent voice note and choose every hour or every two hours; the notification opens 3ialna to play it locally and does not autoplay in the background.", "Enable Device Admin only if you want to try hard lock, and review battery optimization if reminder reliability needs it. Both are optional, and the visual blocker remains the fallback when unavailable.", "Categorize installed apps, review category rules, run a short blocking and child-switch test, then hand over the device."],
    iosInstallTitle: "iPhone and iPad path",
    iosInstallSteps: ["iOS safeguards require iOS 16 or later, an Apple Developer account, and the Family Controls distribution entitlement.", "In 3ialna, open iOS parental setup, grant Screen Time authorization, then use the Apple picker to select the apps or categories to protect.", "Sleep and prayer rules shield the selected apps or categories during their windows; they are not a universal physical device lock.", "Task and prayer reminders are local notifications. The Play parent voice action opens 3ialna to play the local recording; the app does not promise automatic background playback on iPhone.", "Web protection also requires a registered and Apple-approved Network Extension. Do not distribute an iOS build until these Apple Developer and TestFlight/App Store requirements are complete."],
    packTitle: "Share settings, not children’s data",
    packBody: "From the parent dashboard, choose Share setup. Give the pack a setup name and creator name; it carries reusable rules only. It never includes child names, dates of birth, gender, PINs, usage, recordings, reminder labels, or reminder recordings. Import applies the pack to the active child and never creates a child profile.",
    comparisonTitle: "Transparent feature comparison",
    comparisonIntro: "This is a scope comparison, not a ranking or security review. Cells are based on the official feature pages linked below; capabilities vary by platform, plan, and country.",
    comparisonHeaders: ["Feature", "3ialna", "Google Family Link", "Qustodio", "Bark", "Norton Family"],
    comparisonRows: [["Time limits and schedules", "Yes", "Yes", "Yes", "Yes", "Yes"], ["App blocking / categories", "Yes; shared categories", "Yes; per-app limits", "Yes", "Yes", "Platform-limited"], ["Sleep protection", "Yes; editable", "Downtime", "Routines / bedtime", "Schedules", "Schedules"], ["Prayer-aware lock", "Yes; parent location", "—", "—", "—", "—"], ["Parent-recorded voice", "Yes; on-device", "—", "—", "—", "—"], ["Child-identity-free setup packs", "Yes", "Not documented", "Not documented", "Not documented", "Not documented"], ["iOS path", "Screen Time; Apple setup required", "Device-dependent", "Published iOS list", "Documented iOS limits", "Platform-dependent"]],
    comparisonSources: "Comparison sources",
    profiles: "Ready-made age profiles",
    profilesIntro: "Start with an age-appropriate baseline, then tune it for your family. Every app categorized as social media or games draws from one daily shared budget, and parents can edit or reset every value.",
    profileNames: ["Under 5", "Ages 5–9", "Ages 9–13", "Teenagers 13–18"],
    profileDetails: ["Social: 0m · Games: 30m · Prayer: 10m · Sleep: 19:30–07:00", "Social: 0m · Games: 45m · Prayer: 15m · Sleep: 20:30–07:00", "Social: 30m · Games: 60m · Prayer: 15m · Sleep: 21:30–07:00", "Social: 60m · Games: 90m · Prayer: 15m · Sleep: 22:30–07:00"],
    profileNote: "These are editable recreational starting points, not individual medical prescriptions. Review sleep, school, physical activity, and content quality with your child. Prayer locks use the parent’s configured location and calculation method.",
    profileSources: "Guidance sources",
    categoryRegistryTitle: "Default category starter list",
    socialRegistry: "Social media: Facebook, Instagram, Threads, X, Snapchat, TikTok, Reddit, Discord, Pinterest, Tumblr, and YouTube.",
    gamesRegistry: "Games: Roblox, Minecraft, Fortnite, PUBG Mobile, Free Fire, Mobile Legends, Clash titles, Brawl Stars, Candy Crush, and Subway Surfers.",
    categoryRegistryNote: "This is a transparent starting registry, not a judgment about every app. Parents can move any installed app between Social media, Games, or Not assigned.",
    voice: "Your message, your voice",
    voiceBody: "Instead of a generic synthetic voice, parents can record a warm message for the notification routine. Written text stays visible, and the recording stays on the device.",
    privacyTitle: "Practical protection without hidden surveillance",
    privacyPoints: ["No reading of conversations or page content", "Recordings and settings remain local", "Parents control edit, reset, and stop", "Written and voice alerts are configurable"],
    faq: "Common questions",
    faqItems: [["Does 3ialna read a child’s messages?", "No. It uses time, app, domain, and permission-based controls."], ["Can I change the age profile?", "Yes. Choose another profile, edit values, or reset the current profile to its defaults."], ["Where is the voice recording stored?", "Locally on the device where the parent records it. This feature does not upload it to a server."], ["Does iPhone work the same way?", "iOS permissions differ from Android. Use Family Controls and Network Extension according to the project’s iOS guide."]],
    finalCta: "Make setup understandable from day one.",
    finalBody: "Share this page with your family, then open the app and choose the profile that fits your child.",
    download: "Download test APK",
    releaseKicker: "03 / Android test release",
    releaseTitle: "The Android evaluation build is ready for direct download",
    releaseBody: "Start with the smaller evaluation APK on an Android phone. If the phone cannot install it, use the arm64 fallback listed below. No Firebase sign-in or tester invitation is required.",
    releasePlatform: "Android",
    releaseVersion: "0.1.0 · Build 1",
    releaseChannel: "Public evaluation release",
    releaseButton: "Download smaller APK · armv7",
    releaseNotice: "This is an evaluation build, not a store release. Android may ask you to allow installation from your browser or file manager. If Android says the package conflicts with an existing package, the installed copy has a different signing key. Do not uninstall before exporting a shareable setup; uninstalling removes local child data, PINs, recordings, and usage.",
    apkChoiceTitle: "If installation fails, try the compatible alternative",
    apkChoiceArm64: "Fallback for modern phones that cannot install the smaller build · arm64",
    apkChoiceArmv7: "Smaller build to try first · armv7",
    autoChoiceChecking: "Checking processor compatibility on this device…",
    autoChoiceArm64: "The browser reported ARM64; arm64 was selected automatically.",
    autoChoiceArmv7: "The browser reported a non-ARM64 processor; the smaller armv7 build was selected automatically.",
    autoChoiceUnknown: "The browser did not share CPU architecture; the smaller armv7 build remains selected. Choose arm64 manually if installation fails.",
    requestInvite: "Need help? Contact us",
    testerQrTitle: "Scan to download the smaller APK",
    testerQrBody: "Opens the armv7 Android download without sign-in.",
    siteQrTitle: "Scan to share the guide",
    siteQrBody: "Open the setup page on any phone.",
    releaseUpdated: "Last updated",
    footer: "3ialna · Family digital safety",
    contactKicker: "08 / Contact",
    contactTitle: "Need help with setup?",
    contactBody: "Send your message and the 3ialna team will receive the details by email. Please do not send PINs or sensitive personal information.",
    name: "Name",
    email: "Email address",
    subject: "Subject",
    message: "How can we help?",
    submit: "Send message",
    sending: "Sending…",
    contactSuccess: "Thank you. Your message has reached the 3ialna team.",
    contactError: "Your message could not be sent right now. Please try again later.",
  },
} as const;

function TourPreview({ step, isArabic }: { step: number; isArabic: boolean }) {
  const labels = isArabic
    ? {
      children: "الأطفال", active: "الطفل النشط", profile: "ملف مناسب للعمر",
      protection: "الحماية", enabled: "المراقبة مفعّلة", limits: "حدود الفئات", schedule: "النوم والصلاة",
      voice: "تذكير بصوت الوالد", local: "تسجيل محلي", play: "تشغيل داخل عيالنا",
      reports: "تقرير الاستخدام", week: "آخر 7 أيام", localData: "بيانات على الجهاز",
      actions: "إجراءات سريعة", tile: "إضافة اختصار", switchChild: "تبديل الطفل النشط",
    }
    : {
      children: "Kids", active: "Active child", profile: "Age-ready profile",
      protection: "Protection", enabled: "Monitoring enabled", limits: "Category limits", schedule: "Sleep & prayer",
      voice: "Parent voice reminder", local: "Local recording", play: "Play in 3ialna",
      reports: "Usage report", week: "Last 7 days", localData: "On-device data",
      actions: "Quick actions", tile: "Add shortcut", switchChild: "Switch active child",
    };

  const previewContent = [
    <><div className="preview-title"><span className="preview-avatar" />{labels.children}</div><div className="preview-focus"><small>{labels.active}</small><b>{labels.profile}</b></div><div className="preview-row"><span className="preview-dot teal" />{labels.profile}</div></>,
    <><div className="preview-title"><span className="preview-shield">✓</span>{labels.protection}</div><div className="preview-focus success"><span>{labels.enabled}</span><i /></div><div className="preview-row"><span className="preview-dot indigo" />{labels.limits}<i /></div><div className="preview-row"><span className="preview-dot amber" />{labels.schedule}</div></>,
    <><div className="preview-title"><span className="preview-sound">)))</span>{labels.voice}</div><div className="preview-wave"><span /><span /><span /><span /><span /></div><div className="preview-focus voice"><small>{labels.local}</small><b>01:12</b></div><span className="preview-play">▶ {labels.play}</span></>,
    <><div className="preview-title"><span className="preview-chart">▥</span>{labels.reports}</div><small className="preview-caption">{labels.week}</small><div className="preview-bars"><i /><i /><i /><i /><i /></div><div className="preview-focus privacy"><span>✓</span>{labels.localData}</div></>,
    <><div className="preview-title"><span className="preview-spark">✦</span>{labels.actions}</div><span className="preview-action">{labels.tile}<span>＋</span></span><span className="preview-action">{labels.switchChild}<span>›</span></span></>,
  ][step];

  return <div className={`phone-preview step-${step + 1}`} aria-label={isArabic ? `معاينة شاشة الخطوة ${step + 1}` : `Step ${step + 1} screen preview`}><div className="phone-speaker" /><div className="phone-screen">{previewContent}</div></div>;
}

export default function Home() {
  const [language, setLanguage] = useState<Language>("ar");
  const [openFaq, setOpenFaq] = useState<number | null>(0);
  const [detectedAbi, setDetectedAbi] = useState<AndroidAbi>("armv7");
  const [detectionState, setDetectionState] = useState<DetectionState>("checking");
  const t = useMemo(() => copy[language], [language]);
  const isArabic = language === "ar";

  useEffect(() => {
    let isCurrent = true;
    const userAgentData = (navigator as NavigatorWithUserAgentData).userAgentData;

    if (userAgentData?.platform?.toLowerCase() !== "android" || !userAgentData.getHighEntropyValues) {
      setDetectionState("unknown");
      return () => {
        isCurrent = false;
      };
    }

    void userAgentData
      .getHighEntropyValues(["architecture", "bitness"])
      .then(({ architecture = "", bitness = "" }) => {
        if (!isCurrent) return;
        const architectureValue = architecture.toLowerCase();
        const isArm64 = /arm|aarch64/.test(architectureValue) &&
          (architectureValue.includes("64") || bitness === "64");
        const abi: AndroidAbi = isArm64 ? "arm64" : "armv7";
        setDetectedAbi(abi);
        setDetectionState(abi);
      })
      .catch(() => {
        if (isCurrent) setDetectionState("unknown");
      });

    return () => {
      isCurrent = false;
    };
  }, []);

  const releaseVersion = `${currentRelease.version} · ${isArabic ? "البنية" : "Build"} ${currentRelease.build}`;
  const releaseDate = new Intl.DateTimeFormat(isArabic ? "ar-SA" : "en-US", { dateStyle: "medium" }).format(new Date(currentRelease.publishedAt));
  const contactWasSubmitted = new URLSearchParams(window.location.search).get("sent") === "1";
  const preferredDownloadUrl = currentRelease.downloadUrls[detectedAbi];
  const detectionMessage = detectionState === "checking"
    ? t.autoChoiceChecking
    : detectionState === "arm64"
      ? t.autoChoiceArm64
      : detectionState === "armv7"
        ? t.autoChoiceArmv7
        : t.autoChoiceUnknown;
  const apkChoices = [
    { key: "armv7", label: t.apkChoiceArmv7, url: currentRelease.downloadUrls.armv7 },
    { key: "arm64", label: t.apkChoiceArm64, url: currentRelease.downloadUrls.arm64 },
  ] as const;

  return (
    <div dir={isArabic ? "rtl" : "ltr"} className="site-shell">
      <header className="topbar">
        <a className="brand" href="#top"><span className="brand-mark" aria-hidden="true" /><span>3ialna</span><small>عيالنا</small></a>
        <nav>{t.nav.map((item, index) => <a key={item} href={["#how", "#download", "#setup", "#profiles", "#comparison", "#privacy", "#contact"][index]}>{item}</a>)}</nav>
        <div className="top-actions">
          <button className="lang-switch" onClick={() => setLanguage(isArabic ? "en" : "ar")}><Globe2 size={16} />{isArabic ? "English" : "العربية"}</button>
          <a className="mini-cta" href="#download">{isArabic ? "النسخة التجريبية" : "Test release"}<ArrowUpRight size={15} /></a>
        </div>
      </header>

      <main id="top">
        <section className="hero" style={{ backgroundImage: `linear-gradient(90deg, rgba(23,74,59,.98) 0%, rgba(23,74,59,.84) 42%, rgba(23,74,59,.16) 100%), url(${heroImage})` }}>
          <div className="hero-copy">
            <div className="eyebrow"><span className="seed-dot" />{t.badge}</div>
            <h1>{t.title}</h1>
            <p>{t.intro}</p>
            <div className="hero-actions"><a className="button primary" href="#download"><Download size={18} />{t.cta}</a><a className="button text-button" href="#how">{t.secondary}<ArrowDown size={17} /></a></div>
            <div className="hero-note"><ShieldCheck size={16} />{t.note}</div>
          </div>
          <div className="hero-caption"><span>01</span><b>{isArabic ? "روتين رقمي هادئ" : "A calmer digital rhythm"}</b></div>
        </section>

        <section id="how" className="walkthrough-section"><div className="walkthrough-heading"><div><span className="section-kicker">02 / {isArabic ? "الجولة التعريفية" : "Feature tour"}</span><h2>{t.guide}</h2></div><p>{t.guideIntro}</p></div><ol className="walkthrough-list">{t.walkthrough.map(([title, body], index) => <li className="walkthrough-step" key={title}><span className="walkthrough-number">{String(index + 1).padStart(2, "0")}</span><TourPreview step={index} isArabic={isArabic} /><h3>{title}</h3><p>{body}</p></li>)}</ol></section>

        <section id="download" className="release-section section-grid"><div className="release-copy"><span className="section-kicker">{t.releaseKicker}</span><h2>{t.releaseTitle}</h2><p>{t.releaseBody}</p><a className="release-request" href="#contact"><Mail size={16} />{t.requestInvite}<ArrowUpRight size={15} /></a></div><div className="release-panel"><div className="release-status"><span className="release-pulse" aria-hidden="true" />{isArabic ? "إصدار متاح" : "Release available"}</div><div className="release-facts"><div><span>{isArabic ? "المنصة" : "Platform"}</span><b>{currentRelease.platform}</b></div><div><span>{isArabic ? "الإصدار" : "Version"}</span><b>{releaseVersion}</b></div><div><span>{isArabic ? "قناة التثبيت" : "Install channel"}</span><b>{t.releaseChannel}</b></div></div><a className="button release-button" href={preferredDownloadUrl} target="_blank" rel="noreferrer"><Download size={18} />{t.releaseButton}<ExternalLink size={16} /></a><p className="release-detection" role="status"><Smartphone size={16} />{detectionMessage}</p><div className="apk-choice-list"><b>{t.apkChoiceTitle}</b>{apkChoices.map((choice) => <a key={choice.key} href={choice.url} target="_blank" rel="noreferrer"><Download size={14} />{choice.label}<ExternalLink size={13} /></a>)}</div><p className="release-notice"><ShieldCheck size={17} />{t.releaseNotice}</p><p className="release-updated">{t.releaseUpdated}: {releaseDate}</p><div className="release-qr-grid"><div className="release-qr-card"><QRCodeSVG value={preferredDownloadUrl} size={128} level="M" includeMargin bgColor="#f7f3eb" fgColor="#174a3b" /><div><b>{t.testerQrTitle}</b><span>{t.testerQrBody}</span></div></div><div className="release-qr-card"><QRCodeSVG value={publicSiteUrl} size={128} level="M" includeMargin bgColor="#f7f3eb" fgColor="#174a3b" /><div><b>{t.siteQrTitle}</b><span>{t.siteQrBody}</span></div></div></div></div></section>

        <section id="setup" className="setup-section section-grid"><div className="sticky-heading"><span className="section-kicker">04 / {isArabic ? "الدليل العملي" : "The practical guide"}</span><h2>{t.install}</h2><p>{t.installIntro}</p><a className="button dark-button" href="#profiles"><ArrowDown size={17} />{isArabic ? "تابع إلى الملفات" : "Continue to profiles"}</a></div><div className="steps">{t.steps.map(([title, body], index) => <article className="step" key={title}><div className="step-index">{String(index + 1).padStart(2, "0")}</div><div><h3>{title}</h3><p>{body}</p></div><Check size={18} className="step-check" /></article>)}</div><div className="installation-details"><article><h3>{t.androidInstallTitle}</h3><ol>{t.androidInstallSteps.map((step) => <li key={step}>{step}</li>)}</ol></article><article><h3>{t.iosInstallTitle}</h3><ol>{t.iosInstallSteps.map((step) => <li key={step}>{step}</li>)}</ol></article><aside><h3>{t.packTitle}</h3><p>{t.packBody}</p></aside></div></section>

        <section id="profiles" className="profiles-section"><div className="section-heading"><div><span className="section-kicker">05 / {isArabic ? "مرونة الوالدين" : "Parent-controlled flexibility"}</span><h2>{t.profiles}</h2></div><p>{t.profilesIntro}</p></div><div className="profile-feature"><div className="profile-image" style={{ backgroundImage: profileImage }}><span>{isArabic ? "ابدأ من الأساس المناسب" : "Start from the right baseline"}</span></div><div className="profile-list">{t.profileNames.map((name, index) => <div className="profile-row" key={name}><span className="profile-number">0{index + 1}</span><div><h3>{name}</h3><p>{t.profileDetails[index]}</p></div><ChevronDown size={18} /></div>)}</div></div><div className="profile-evidence"><p>{t.profileNote}</p><span>{t.profileSources}: <a href="https://www.who.int/news/item/24-04-2019-to-grow-up-healthy-children-need-to-sit-less-and-play-more" target="_blank" rel="noreferrer">WHO</a> · <a href="https://aasm.org/advocacy/position-statements/child-sleep-duration-health-advisory/" target="_blank" rel="noreferrer">AASM</a> · <a href="https://www.aap.org/en/patient-care/media-and-children/center-of-excellence-on-social-media-and-youth-mental-health/qa-portal/qa-portal-library/qa-portal-library-questions/screen-time-guidelines/" target="_blank" rel="noreferrer">AAP</a> · <a href="https://cps.ca/en/documents/position/digital-media" target="_blank" rel="noreferrer">CPS</a></span></div><div className="profile-category-registry"><h3>{t.categoryRegistryTitle}</h3><p>{t.socialRegistry}</p><p>{t.gamesRegistry}</p><small>{t.categoryRegistryNote}</small></div></section>
        <section id="comparison" className="comparison-section"><div className="section-heading"><div><span className="section-kicker">06 / {isArabic ? "سياق السوق" : "Market context"}</span><h2>{t.comparisonTitle}</h2></div><p>{t.comparisonIntro}</p></div><div className="comparison-scroll"><table><thead><tr>{t.comparisonHeaders.map((heading) => <th key={heading}>{heading}</th>)}</tr></thead><tbody>{t.comparisonRows.map((row) => <tr key={row[0]}>{row.map((cell, index) => <td key={`${row[0]}-${index}`}>{cell}</td>)}</tr>)}</tbody></table></div><p className="comparison-sources">{t.comparisonSources}: <a href="https://families.google/familylink/" target="_blank" rel="noreferrer">Google Family Link</a> · <a href="https://www.qustodio.com/en/features/" target="_blank" rel="noreferrer">Qustodio</a> · <a href="https://www.bark.us/" target="_blank" rel="noreferrer">Bark</a> · <a href="https://us.norton.com/feature/parental-control" target="_blank" rel="noreferrer">Norton Family</a> · <a href="https://developer.apple.com/documentation/screentimeapidocumentation" target="_blank" rel="noreferrer">Apple Screen Time</a></p></section>

        <section className="voice-section section-grid"><div className="voice-image" style={{ backgroundImage: voiceImage }}><span className="voice-tag"><Mic2 size={15} />{isArabic ? "محلي على الجهاز" : "Stored on-device"}</span></div><div className="voice-copy"><span className="section-kicker">06 / {isArabic ? "التنبيهات" : "Notifications"}</span><h2>{t.voice}</h2><p>{t.voiceBody}</p><div className="voice-points"><div><Mic2 size={20} /><span>{isArabic ? "تسجيل واستبدال وحذف" : "Record, replace, and delete"}</span></div><div><Smartphone size={20} /><span>{isArabic ? "لا رفع إلى السحابة" : "No cloud upload"}</span></div></div></div></section>

        <section id="privacy" className="privacy-section"><div className="section-heading"><div><span className="section-kicker">07 / {isArabic ? "ما لا نفعله" : "What we do not do"}</span><h2>{t.privacyTitle}</h2></div></div><div className="privacy-grid">{t.privacyPoints.map((point, index) => { const Icon = privacyIcons[index]; return <div key={point} className="privacy-item"><span><Icon size={20} /></span><p>{point}</p></div>; })}</div></section>

        <section className="faq-section section-grid"><div><span className="section-kicker">08 / FAQ</span><h2>{t.faq}</h2><CircleHelp size={34} className="faq-mark" /></div><div className="faq-list">{t.faqItems.map(([question, answer], index) => <div className={`faq-item ${openFaq === index ? "open" : ""}`} key={question}><button onClick={() => setOpenFaq(openFaq === index ? null : index)}><span>{question}</span>{openFaq === index ? <ArrowUp size={18} /> : <ArrowDown size={18} />}</button>{openFaq === index && <p>{answer}</p>}</div>)}</div></section>

        <section id="contact" className="contact-section section-grid"><div className="contact-copy"><span className="section-kicker">{t.contactKicker}</span><h2>{t.contactTitle}</h2><p>{t.contactBody}</p><div className="contact-address"><Mail size={18} /><span>3ialna.app@gmail.com</span></div></div><form className="contact-form" action="https://formsubmit.co/3ialna.app@gmail.com" method="POST"><input type="hidden" name="_subject" value="3ialna website inquiry" /><input type="hidden" name="_template" value="table" /><input type="hidden" name="_captcha" value="true" /><input type="hidden" name="_next" value={`${publicSiteUrl}?sent=1#contact`} /><input type="hidden" name="_url" value={publicSiteUrl} /><input className="form-honeypot" type="text" name="_honey" tabIndex={-1} autoComplete="off" /><label>{t.name}<input required name="name" autoComplete="name" /></label><label>{t.email}<input required type="email" name="email" autoComplete="email" /></label><label>{t.subject}<input required name="subject" /></label><label>{t.message}<textarea required name="message" rows={5} /></label><button className="button dark-button contact-submit" type="submit"><Send size={17} />{t.submit}</button>{contactWasSubmitted && <p className="form-state success" role="status"><Check size={16} />{t.contactSuccess}</p>}</form></section>

        <section className="final-cta"><div><Sparkles size={22} /><h2>{t.finalCta}</h2><p>{t.finalBody}</p></div><a className="button primary light" href="#download"><Download size={18} />{t.download}</a></section>
      </main>
      <footer><div className="brand footer-brand"><span className="brand-mark" aria-hidden="true" /><span>3ialna</span><small>عيالنا</small></div><span>{t.footer}</span><span>© 2026</span></footer>
    </div>
  );
}
