import { FormEvent, useMemo, useState } from "react";
import { ArrowDown, ArrowUp, ArrowUpRight, Check, ChevronDown, CircleHelp, Clock3, Download, Globe2, LockKeyhole, Mail, Mic2, RotateCcw, Send, ShieldCheck, Smartphone, Sparkles } from "lucide-react";

const heroImage = "./assets/3ialna-hero-family.jpg";
const profileImage = "linear-gradient(135deg, rgba(23,74,59,.96), rgba(30,103,82,.72)), radial-gradient(circle at 72% 28%, rgba(231,184,104,.85) 0 9%, transparent 10%), linear-gradient(140deg, #c9b18a, #547b63 58%, #174a3b)";
const voiceImage = "linear-gradient(145deg, rgba(23,74,59,.9), rgba(23,74,59,.22)), radial-gradient(circle at 70% 30%, rgba(231,184,104,.92) 0 12%, transparent 13%), linear-gradient(35deg, #d9c7a9, #547b63 55%, #174a3b)";
const privacyIcons = [LockKeyhole, Mic2, RotateCcw, Clock3];

type Language = "ar" | "en";

const copy = {
  ar: {
    nav: ["كيف يعمل", "الإعداد", "الملفات العمرية", "الخصوصية", "تواصل"],
    badge: "دليل الإعداد الرسمي · عيالنا",
    title: "احمِ وقت العائلة، لا خصوصيتها.",
    intro: "عيالنا يساعد الوالدين على بناء روتين رقمي هادئ يناسب عمر الطفل، مع رسائل صوتية بصوت الوالدين وإعدادات يمكن الرجوع عنها في أي وقت.",
    cta: "ابدأ الإعداد في 5 دقائق",
    secondary: "استكشف الخصائص",
    note: "متاح للاختبار على أجهزة Android. يتطلب منح أذونات الجهاز يدويًا.",
    guide: "من الفكرة إلى الإعداد",
    guideIntro: "إعداد واضح، خطوة واحدة في كل مرة، ومن دون فحص للرسائل أو صفحات المحتوى.",
    privacy: "الخصوصية أولًا",
    privacyBody: "التحكم مبني على الوقت، التطبيقات، النطاقات، وروتين الصلاة. لا نحتاج إلى قراءة محادثات الطفل أو تحليل ما يكتبه.",
    install: "التثبيت والإعداد",
    installIntro: "اتبع هذه الخطوات بالترتيب على هاتف الوالد أو الجهاز الذي ستديره.",
    steps: [
      ["نزّل ملف APK", "حمّل أحدث ملف اختبار من زر التنزيل، ثم اسمح بالتثبيت من هذا المصدر عند ظهور رسالة Android."],
      ["أنشئ حماية الوالدين", "افتح عيالنا، أنشئ رقمًا سريًا، ثم فعّل البصمة لتصبح طريقة التحقق الافتراضية مع بقاء الرقم السري كخيار احتياطي."],
      ["فعّل الأذونات", "فعّل Usage Access وAccessibility وOverlay وDevice Admin عند الحاجة لتشغيل مراقبة الوقت والحظر الصارم."],
      ["اختر ملفًا عمريًا", "اختر الإعداد المناسب، عدّل الحدود، ثم احفظ. يمكنك تغيير الملف أو إرجاعه إلى إعداداته الأصلية لاحقًا."],
      ["سجّل رسالة بصوتك", "من الإعدادات افتح صوت الوالدين، سجّل رسالة قصيرة، استمع إليها، وسيبقى التسجيل على الجهاز فقط."],
    ],
    profiles: "إعدادات جاهزة حسب العمر",
    profilesIntro: "ابدأ من نقطة مناسبة للعمر ثم عدّلها حسب عادات طفلك. إعادة الضبط تعيد إعدادات الملف المختار إلى قيمه الأصلية.",
    profileNames: ["دون 5 سنوات", "من 5 إلى 9", "من 9 إلى 13", "المراهقون 13–18"],
    profileDetails: ["جلسات قصيرة وموافقة الوالدين", "استكشاف موجّه وحدود واضحة", "استقلالية أكبر مع مراجعة", "حدود مرنة تحترم الخصوصية"],
    voice: "رسالتك، بصوتك",
    voiceBody: "بدل صوت آلي عام، يمكن للوالدين تسجيل رسالة دافئة تُستخدم ضمن روتين التنبيه. النص المكتوب يظل ظاهرًا، والتسجيل لا يغادر الجهاز.",
    privacyTitle: "حماية عملية بلا مراقبة خفية",
    privacyPoints: ["لا قراءة للمحادثات أو صفحات الويب", "تخزين التسجيلات والإعدادات محليًا", "الوالد يملك التعديل والرجوع والإيقاف", "إشعارات مكتوبة وصوتية قابلة للتخصيص"],
    faq: "أسئلة شائعة",
    faqItems: [["هل يقرأ عيالنا رسائل الطفل؟", "لا. يعتمد التطبيق على حدود الوقت، التطبيقات، النطاقات، والأذونات المطلوبة للتنفيذ."], ["هل يمكن تغيير الملف العمري؟", "نعم. يمكن اختيار أي ملف، تعديل قيمه، أو إعادة الملف الحالي إلى الإعداد الافتراضي."], ["أين يُحفظ التسجيل الصوتي؟", "محليًا على الجهاز الذي سجّله الوالد. لا يتم رفعه إلى خادم من خلال هذه الميزة."], ["هل يعمل iPhone بنفس الطريقة؟", "تختلف أذونات iOS عن Android. استخدم Family Controls وNetwork Extension وفق دليل iOS داخل المشروع." ]],
    finalCta: "اجعل الإعداد مفهومًا من اليوم الأول.",
    finalBody: "شارك هذه الصفحة مع العائلة، ثم افتح التطبيق واختر الملف الذي يناسب طفلك.",
    download: "تنزيل APK للاختبار",
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
    nav: ["How it works", "Setup", "Age profiles", "Privacy", "Contact"],
    badge: "Official setup guide · 3ialna",
    title: "Protect family time, not private conversations.",
    intro: "3ialna helps parents build a calmer digital routine by age, with parent-recorded voice messages and settings they can edit or reset at any time.",
    cta: "Start setup in 5 minutes",
    secondary: "Explore the features",
    note: "Available for Android testing. Device permissions must be granted manually.",
    guide: "From intention to setup",
    guideIntro: "Clear steps, one decision at a time, without reading messages or inspecting page content.",
    privacy: "Privacy by design",
    privacyBody: "Controls are based on time, apps, domains, and prayer-aware routines. The app does not need to read a child’s conversations or analyze what they type.",
    install: "Install and configure",
    installIntro: "Follow these steps in order on the parent phone or the device you manage.",
    steps: [["Download the APK", "Download the latest test file, then allow installation from this source when Android asks."], ["Create parent protection", "Open 3ialna, create a PIN, and enable biometrics as the preferred method with PIN fallback."], ["Grant permissions", "Enable Usage Access, Accessibility, Overlay, and Device Admin when needed for monitoring and hard lock."], ["Choose an age profile", "Select a starting configuration, edit the limits, and save. You can switch profiles or reset defaults later."], ["Record your voice", "Open Parent voice from Settings, record a short message, preview it, and keep it stored on-device." ]],
    profiles: "Ready-made age profiles",
    profilesIntro: "Start with an age-appropriate baseline, then tune it for your family. Reset returns the selected profile to its original defaults.",
    profileNames: ["Under 5", "Ages 5–9", "Ages 9–13", "Teenagers 13–18"],
    profileDetails: ["Short sessions and parent approval", "Guided exploration and clear limits", "More independence with review", "Flexible boundaries with privacy"],
    voice: "Your message, your voice",
    voiceBody: "Instead of a generic synthetic voice, parents can record a warm message for the notification routine. Written text stays visible, and the recording stays on the device.",
    privacyTitle: "Practical protection without hidden surveillance",
    privacyPoints: ["No reading of conversations or page content", "Recordings and settings remain local", "Parents control edit, reset, and stop", "Written and voice alerts are configurable"],
    faq: "Common questions",
    faqItems: [["Does 3ialna read a child’s messages?", "No. It uses time, app, domain, and permission-based controls."], ["Can I change the age profile?", "Yes. Choose another profile, edit values, or reset the current profile to its defaults."], ["Where is the voice recording stored?", "Locally on the device where the parent records it. This feature does not upload it to a server."], ["Does iPhone work the same way?", "iOS permissions differ from Android. Use Family Controls and Network Extension according to the project’s iOS guide."]],
    finalCta: "Make setup understandable from day one.",
    finalBody: "Share this page with your family, then open the app and choose the profile that fits your child.",
    download: "Download test APK",
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
  const [contactState, setContactState] = useState<"idle" | "sending" | "sent" | "error">("idle");
  const t = useMemo(() => copy[language], [language]);
  const isArabic = language === "ar";

  async function submitContact(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setContactState("sending");
    try {
      const response = await fetch("https://formsubmit.co/ajax/3ialna.app@gmail.com", {
        method: "POST",
        headers: { Accept: "application/json" },
        body: new FormData(event.currentTarget),
      });
      if (!response.ok) throw new Error("Contact form submission failed");
      event.currentTarget.reset();
      setContactState("sent");
    } catch {
      setContactState("error");
    }
  }

  return (
    <div dir={isArabic ? "rtl" : "ltr"} className="site-shell">
      <header className="topbar">
        <a className="brand" href="#top"><span className="brand-mark" aria-hidden="true" /><span>3ialna</span><small>عيالنا</small></a>
        <nav>{t.nav.map((item, index) => <a key={item} href={["#how", "#setup", "#profiles", "#privacy", "#contact"][index]}>{item}</a>)}</nav>
        <div className="top-actions">
          <button className="lang-switch" onClick={() => setLanguage(isArabic ? "en" : "ar")}><Globe2 size={16} />{isArabic ? "English" : "العربية"}</button>
          <a className="mini-cta" href="#setup">{isArabic ? "ابدأ" : "Begin"}<ArrowUpRight size={15} /></a>
        </div>
      </header>

      <main id="top">
        <section className="hero" style={{ backgroundImage: `linear-gradient(90deg, rgba(23,74,59,.98) 0%, rgba(23,74,59,.84) 42%, rgba(23,74,59,.16) 100%), url(${heroImage})` }}>
          <div className="hero-copy">
            <div className="eyebrow"><span className="seed-dot" />{t.badge}</div>
            <h1>{t.title}</h1>
            <p>{t.intro}</p>
            <div className="hero-actions"><a className="button primary" href="#setup"><Download size={18} />{t.cta}</a><a className="button text-button" href="#how">{t.secondary}<ArrowDown size={17} /></a></div>
            <div className="hero-note"><ShieldCheck size={16} />{t.note}</div>
          </div>
          <div className="hero-caption"><span>01</span><b>{isArabic ? "روتين رقمي هادئ" : "A calmer digital rhythm"}</b></div>
        </section>

        <section id="how" className="intro-band section-grid"><div><span className="section-kicker">02 / {isArabic ? "لماذا عيالنا" : "Why 3ialna"}</span><h2>{t.guide}</h2></div><p>{t.guideIntro}</p><div className="privacy-callout"><LockKeyhole size={20} /><div><b>{t.privacy}</b><span>{t.privacyBody}</span></div></div></section>

        <section id="setup" className="setup-section section-grid"><div className="sticky-heading"><span className="section-kicker">03 / {isArabic ? "الدليل العملي" : "The practical guide"}</span><h2>{t.install}</h2><p>{t.installIntro}</p><a className="button dark-button" href="#profiles"><ArrowDown size={17} />{isArabic ? "تابع إلى الملفات" : "Continue to profiles"}</a></div><div className="steps">{t.steps.map(([title, body], index) => <article className="step" key={title}><div className="step-index">{String(index + 1).padStart(2, "0")}</div><div><h3>{title}</h3><p>{body}</p></div><Check size={18} className="step-check" /></article>)}</div></section>

        <section id="profiles" className="profiles-section"><div className="section-heading"><div><span className="section-kicker">04 / {isArabic ? "مرونة الوالدين" : "Parent-controlled flexibility"}</span><h2>{t.profiles}</h2></div><p>{t.profilesIntro}</p></div><div className="profile-feature"><div className="profile-image" style={{ backgroundImage: profileImage }}><span>{isArabic ? "ابدأ من الأساس المناسب" : "Start from the right baseline"}</span></div><div className="profile-list">{t.profileNames.map((name, index) => <div className="profile-row" key={name}><span className="profile-number">0{index + 1}</span><div><h3>{name}</h3><p>{t.profileDetails[index]}</p></div><ChevronDown size={18} /></div>)}</div></div></section>

        <section className="voice-section section-grid"><div className="voice-image" style={{ backgroundImage: voiceImage }}><span className="voice-tag"><Mic2 size={15} />{isArabic ? "محلي على الجهاز" : "Stored on-device"}</span></div><div className="voice-copy"><span className="section-kicker">05 / {isArabic ? "التنبيهات" : "Notifications"}</span><h2>{t.voice}</h2><p>{t.voiceBody}</p><div className="voice-points"><div><Mic2 size={20} /><span>{isArabic ? "تسجيل واستبدال وحذف" : "Record, replace, and delete"}</span></div><div><Smartphone size={20} /><span>{isArabic ? "لا رفع إلى السحابة" : "No cloud upload"}</span></div></div></div></section>

        <section id="privacy" className="privacy-section"><div className="section-heading"><div><span className="section-kicker">06 / {isArabic ? "ما لا نفعله" : "What we do not do"}</span><h2>{t.privacyTitle}</h2></div></div><div className="privacy-grid">{t.privacyPoints.map((point, index) => { const Icon = privacyIcons[index]; return <div key={point} className="privacy-item"><span><Icon size={20} /></span><p>{point}</p></div>; })}</div></section>

        <section className="faq-section section-grid"><div><span className="section-kicker">07 / FAQ</span><h2>{t.faq}</h2><CircleHelp size={34} className="faq-mark" /></div><div className="faq-list">{t.faqItems.map(([question, answer], index) => <div className={`faq-item ${openFaq === index ? "open" : ""}`} key={question}><button onClick={() => setOpenFaq(openFaq === index ? null : index)}><span>{question}</span>{openFaq === index ? <ArrowUp size={18} /> : <ArrowDown size={18} />}</button>{openFaq === index && <p>{answer}</p>}</div>)}</div></section>

        <section id="contact" className="contact-section section-grid"><div className="contact-copy"><span className="section-kicker">{t.contactKicker}</span><h2>{t.contactTitle}</h2><p>{t.contactBody}</p><div className="contact-address"><Mail size={18} /><span>3ialna.app@gmail.com</span></div></div><form className="contact-form" onSubmit={submitContact}><input type="hidden" name="_subject" value="3ialna website inquiry" /><input type="hidden" name="_template" value="table" /><input className="form-honeypot" type="text" name="_honey" tabIndex={-1} autoComplete="off" /><label>{t.name}<input required name="name" autoComplete="name" /></label><label>{t.email}<input required type="email" name="email" autoComplete="email" /></label><label>{t.subject}<input required name="subject" /></label><label>{t.message}<textarea required name="message" rows={5} /></label><button className="button dark-button contact-submit" type="submit" disabled={contactState === "sending"}><Send size={17} />{contactState === "sending" ? t.sending : t.submit}</button>{contactState === "sent" && <p className="form-state success" role="status"><Check size={16} />{t.contactSuccess}</p>}{contactState === "error" && <p className="form-state error" role="alert">{t.contactError}</p>}</form></section>

        <section className="final-cta"><div><Sparkles size={22} /><h2>{t.finalCta}</h2><p>{t.finalBody}</p></div><a className="button primary light" href="#setup"><Download size={18} />{t.download}</a></section>
      </main>
      <footer><div className="brand footer-brand"><span className="brand-mark" aria-hidden="true" /><span>3ialna</span><small>عيالنا</small></div><span>{t.footer}</span><span>© 2026</span></footer>
    </div>
  );
}
