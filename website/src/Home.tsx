import { useMemo, useState } from "react";
import { ArrowDown, ArrowUp, ArrowUpRight, Check, ChevronDown, CircleHelp, Clock3, Download, ExternalLink, Globe2, LockKeyhole, Mail, Mic2, RotateCcw, Send, ShieldCheck, Smartphone, Sparkles } from "lucide-react";
import { QRCodeSVG } from "qrcode.react";
import { currentRelease } from "./release.generated";

const heroImage = "./assets/3ialna-hero-family.jpg";
const profileImage = "linear-gradient(135deg, rgba(23,74,59,.96), rgba(30,103,82,.72)), radial-gradient(circle at 72% 28%, rgba(231,184,104,.85) 0 9%, transparent 10%), linear-gradient(140deg, #c9b18a, #547b63 58%, #174a3b)";
const voiceImage = "linear-gradient(145deg, rgba(23,74,59,.9), rgba(23,74,59,.22)), radial-gradient(circle at 70% 30%, rgba(231,184,104,.92) 0 12%, transparent 13%), linear-gradient(35deg, #d9c7a9, #547b63 55%, #174a3b)";
const privacyIcons = [LockKeyhole, Mic2, RotateCcw, Clock3];
const publicSiteUrl = "https://mgomma.github.io/3ialna/";

type Language = "ar" | "en";

const copy = {
  ar: {
    nav: ["كيف يعمل", "تنزيل", "الإعداد", "الملفات العمرية", "المقارنة", "الخصوصية", "تواصل"],
    badge: "دليل الإعداد الرسمي · عيالنا",
    title: "احمِ وقت العائلة، لا خصوصيتها.",
    intro: "عيالنا يساعد الوالدين على بناء روتين رقمي هادئ يناسب عمر الطفل، مع رسائل صوتية بصوت الوالدين وإعدادات يمكن الرجوع عنها في أي وقت.",
    cta: "تنزيل النسخة التجريبية",
    secondary: "استكشف الخصائص",
    note: "متاح للاختبار على أجهزة Android. يتطلب منح أذونات الجهاز يدويًا.",
    guide: "من الفكرة إلى الإعداد",
    guideIntro: "إعداد واضح، خطوة واحدة في كل مرة، ومن دون فحص للرسائل أو صفحات المحتوى.",
    privacy: "الخصوصية أولًا",
    privacyBody: "التحكم مبني على الوقت، التطبيقات، النطاقات، وروتين الصلاة. لا نحتاج إلى قراءة محادثات الطفل أو تحليل ما يكتبه.",
    install: "التثبيت والإعداد",
    installIntro: "اتبع هذه الخطوات بالترتيب على هاتف الوالد أو الجهاز الذي ستديره.",
    steps: [
      ["نزّل ملف Android", "استخدم زر التنزيل أو رمز QR في هذه الصفحة. عند ظهور تنبيه Android، اسمح بالتثبيت من المتصفح أو مدير الملفات."],
      ["أنشئ حماية الوالدين", "افتح عيالنا، أنشئ رقمًا سريًا، ثم فعّل البصمة لتصبح طريقة التحقق الافتراضية مع بقاء الرقم السري كخيار احتياطي."],
      ["فعّل الأذونات", "فعّل Usage Access وAccessibility وOverlay وDevice Admin عند الحاجة لتشغيل مراقبة الوقت والحظر الصارم."],
      ["اختر ملفًا عمريًا", "اختر الإعداد المناسب، عدّل الحدود، ثم احفظ. يمكنك تغيير الملف أو إرجاعه إلى إعداداته الأصلية لاحقًا."],
      ["سجّل رسالة بصوتك", "من الإعدادات افتح صوت الوالدين، سجّل رسالة قصيرة، استمع إليها، وسيبقى التسجيل على الجهاز فقط."],
    ],
    androidInstallTitle: "تفصيل التثبيت على Android",
    androidInstallSteps: ["حمّل APK التجريبي من زر التنزيل على هاتف Android، ثم افتح ملف التنزيل.", "اسمح مؤقتًا للتثبيت من المتصفح أو مدير الملفات عندما يطلب Android ذلك، ثم ثبّت التطبيق.", "افتح عيالنا وأنشئ PIN للوالد، ثم فعّل البصمة إن كانت متاحة.", "عرّف الأطفال، اختر الطفل النشط، وحدد ملفه العمري ثم راجع حدود التواصل والألعاب والنوم والصلاة.", "امنح Usage Access وAccessibility وOverlay. فعّل Device Admin فقط إذا أردت محاولة القفل الصارم؛ يبقى الحاجب المرئي بديلًا عند عدم توفره.", "صنّف التطبيقات المثبتة، وراجع سجل الفئات قبل تسليم الجهاز للطفل."],
    iosInstallTitle: "مسار iPhone وiPad",
    iosInstallSteps: ["تتطلب قيود iOS نظام iOS 16 أو أحدث، وحساب مطور Apple وإذن Family Controls للتوزيع.", "من داخل عيالنا افتح إعداد رقابة iOS، امنح إذن Screen Time، ثم اختر التطبيقات أو الفئات التي تريد Apple حمايتها.", "تطبق قواعد النوم والصلاة كشاشات حماية للتطبيقات أو الفئات التي اخترتها، وليست قفلًا ماديًا شاملًا للجهاز.", "تحتاج حماية الويب إلى Network Extension مسجلة وموافق عليها من Apple. لا تنشر نسخة iOS للمستخدمين قبل إكمال هذه المتطلبات في Apple Developer وTestFlight أو App Store."],
    packTitle: "مشاركة إعدادات بلا بيانات الأطفال",
    packBody: "من لوحة الوالدين اختر مشاركة إعداد. تسمي الحزمة باسم الإعداد واسم منشئها، وتحتوي القواعد القابلة لإعادة الاستخدام فقط. لا تتضمن أسماء الأطفال أو تواريخ الميلاد أو الجنس أو PIN أو الاستخدام أو التسجيلات. عند الاستيراد تُطبق الحزمة على الطفل النشط ولا تنشئ طفلاً جديدًا.",
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
    releaseBody: "نزّل ملف APK مباشرة من هذه الصفحة على هاتف Android. لا تحتاج إلى دعوة اختبار أو تسجيل الدخول إلى Firebase.",
    releasePlatform: "Android",
    releaseVersion: "0.1.0 · البنية 1",
    releaseChannel: "إصدار تقييم عام",
    releaseButton: "تنزيل APK التقييمي",
    releaseNotice: "هذه نسخة تقييم وليست إصدار متجر. راجع ملاحظات الإصدار لمعرفة نوع التوقيع والتحسينات، وقد يطلب Android السماح بالتثبيت من المتصفح أو مدير الملفات.",
    apkChoiceTitle: "اختر ملفًا أصغر يناسب هاتفك",
    apkChoiceArm64: "معظم هواتف Android الحديثة · arm64",
    apkChoiceArmv7: "هواتف Android أقدم · armv7",
    requestInvite: "تحتاج إلى مساعدة؟ تواصل معنا",
    testerQrTitle: "امسح لتنزيل APK مباشرة",
    testerQrBody: "يفتح التنزيل على هاتف Android دون تسجيل دخول.",
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
    nav: ["How it works", "Download", "Setup", "Age profiles", "Comparison", "Privacy", "Contact"],
    badge: "Official setup guide · 3ialna",
    title: "Protect family time, not private conversations.",
    intro: "3ialna helps parents build a calmer digital routine by age, with parent-recorded voice messages and settings they can edit or reset at any time.",
    cta: "Download the test release",
    secondary: "Explore the features",
    note: "Available for Android testing. Device permissions must be granted manually.",
    guide: "From intention to setup",
    guideIntro: "Clear steps, one decision at a time, without reading messages or inspecting page content.",
    privacy: "Privacy by design",
    privacyBody: "Controls are based on time, apps, domains, and prayer-aware routines. The app does not need to read a child’s conversations or analyze what they type.",
    install: "Install and configure",
    installIntro: "Follow these steps in order on the parent phone or the device you manage.",
    steps: [["Download the Android file", "Use the download button or QR code on this page. When Android prompts you, allow installation from your browser or file manager."], ["Create parent protection", "Open 3ialna, create a PIN, and enable biometrics as the preferred method with PIN fallback."], ["Grant permissions", "Enable Usage Access, Accessibility, Overlay, and Device Admin when needed for monitoring and hard lock."], ["Choose an age profile", "Select a starting configuration, edit the limits, and save. You can switch profiles or reset defaults later."], ["Record your voice", "Open Parent voice from Settings, record a short message, preview it, and keep it stored on-device." ]],
    androidInstallTitle: "Detailed Android installation",
    androidInstallSteps: ["Download the evaluation APK using this page’s download button on an Android phone, then open the downloaded file.", "Temporarily allow installation from your browser or file manager when Android asks, then install the app.", "Open 3ialna, create a parent PIN, and enable biometrics where available.", "Define the children using the shared device, choose the active child, select an age profile, then review social, games, sleep, and prayer settings.", "Grant Usage Access, Accessibility, and Overlay. Enable Device Admin only if you want to attempt hard lock; the visual blocker remains the fallback when it is unavailable.", "Categorize installed apps, then review the category rules before handing the device to a child."],
    iosInstallTitle: "iPhone and iPad path",
    iosInstallSteps: ["iOS safeguards require iOS 16 or later, an Apple Developer account, and the Family Controls distribution entitlement.", "In 3ialna, open iOS parental setup, grant Screen Time authorization, then use the Apple picker to select the apps or categories to protect.", "Sleep and prayer rules shield the selected apps or categories during their windows; they are not a universal physical device lock.", "Web protection also requires a registered and Apple-approved Network Extension. Do not distribute an iOS build until these Apple Developer and TestFlight/App Store requirements are complete."],
    packTitle: "Share settings, not children’s data",
    packBody: "From the parent dashboard, choose Share setup. Give the pack a setup name and creator name; it carries reusable rules only. It never includes child names, dates of birth, gender, PINs, usage, or recordings. Import applies the pack to the active child and never creates a child profile.",
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
    releaseBody: "Download the APK directly from this page on an Android phone. No Firebase sign-in or tester invitation is required.",
    releasePlatform: "Android",
    releaseVersion: "0.1.0 · Build 1",
    releaseChannel: "Public evaluation release",
    releaseButton: "Download evaluation APK",
    releaseNotice: "This is an evaluation build, not a store release. Check the release notes for signing and optimization details; Android may ask you to allow installation from your browser or file manager.",
    apkChoiceTitle: "Choose a smaller APK for your device",
    apkChoiceArm64: "Most modern Android phones · arm64",
    apkChoiceArmv7: "Older Android phones · armv7",
    requestInvite: "Need help? Contact us",
    testerQrTitle: "Scan to download the APK directly",
    testerQrBody: "Opens the Android download without sign-in.",
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

export default function Home() {
  const [language, setLanguage] = useState<Language>("ar");
  const [openFaq, setOpenFaq] = useState<number | null>(0);
  const t = useMemo(() => copy[language], [language]);
  const isArabic = language === "ar";
  const releaseVersion = `${currentRelease.version} · ${isArabic ? "البنية" : "Build"} ${currentRelease.build}`;
  const releaseDate = new Intl.DateTimeFormat(isArabic ? "ar-SA" : "en-US", { dateStyle: "medium" }).format(new Date(currentRelease.publishedAt));
  const contactWasSubmitted = new URLSearchParams(window.location.search).get("sent") === "1";
  const apkChoices = [
    { key: "arm64", label: t.apkChoiceArm64, url: currentRelease.downloadUrls.arm64 },
    { key: "armv7", label: t.apkChoiceArmv7, url: currentRelease.downloadUrls.armv7 },
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

        <section id="how" className="intro-band section-grid"><div><span className="section-kicker">02 / {isArabic ? "لماذا عيالنا" : "Why 3ialna"}</span><h2>{t.guide}</h2></div><p>{t.guideIntro}</p><div className="privacy-callout"><LockKeyhole size={20} /><div><b>{t.privacy}</b><span>{t.privacyBody}</span></div></div></section>

        <section id="download" className="release-section section-grid"><div className="release-copy"><span className="section-kicker">{t.releaseKicker}</span><h2>{t.releaseTitle}</h2><p>{t.releaseBody}</p><a className="release-request" href="#contact"><Mail size={16} />{t.requestInvite}<ArrowUpRight size={15} /></a></div><div className="release-panel"><div className="release-status"><span className="release-pulse" aria-hidden="true" />{isArabic ? "إصدار متاح" : "Release available"}</div><div className="release-facts"><div><span>{isArabic ? "المنصة" : "Platform"}</span><b>{currentRelease.platform}</b></div><div><span>{isArabic ? "الإصدار" : "Version"}</span><b>{releaseVersion}</b></div><div><span>{isArabic ? "قناة التثبيت" : "Install channel"}</span><b>{t.releaseChannel}</b></div></div><a className="button release-button" href={currentRelease.downloadUrl} target="_blank" rel="noreferrer"><Download size={18} />{t.releaseButton}<ExternalLink size={16} /></a><div className="apk-choice-list"><b>{t.apkChoiceTitle}</b>{apkChoices.map((choice) => <a key={choice.key} href={choice.url} target="_blank" rel="noreferrer"><Download size={14} />{choice.label}<ExternalLink size={13} /></a>)}</div><p className="release-notice"><ShieldCheck size={17} />{t.releaseNotice}</p><p className="release-updated">{t.releaseUpdated}: {releaseDate}</p><div className="release-qr-grid"><div className="release-qr-card"><QRCodeSVG value={currentRelease.downloadUrl} size={128} level="M" includeMargin bgColor="#f7f3eb" fgColor="#174a3b" /><div><b>{t.testerQrTitle}</b><span>{t.testerQrBody}</span></div></div><div className="release-qr-card"><QRCodeSVG value={publicSiteUrl} size={128} level="M" includeMargin bgColor="#f7f3eb" fgColor="#174a3b" /><div><b>{t.siteQrTitle}</b><span>{t.siteQrBody}</span></div></div></div></div></section>

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
