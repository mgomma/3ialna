import { useEffect, useState } from "react";
import { BookOpen, MessageCircle, Send, X } from "lucide-react";
import "./telegram-support-popup.css";

const supportGroupUrl = "https://t.me/+sWzmBwunemY2MGM8";

export default function TelegramSupportPopup({ isArabic, whatsappShareUrl }: { isArabic: boolean; whatsappShareUrl: string }) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const timer = window.setTimeout(() => setIsVisible(true), 8000);
    return () => window.clearTimeout(timer);
  }, []);

  if (!isVisible) return null;

  return (
    <aside className="telegram-support-popup" dir={isArabic ? "rtl" : "ltr"} aria-labelledby="telegram-support-title" aria-live="polite">
      <button
        className="telegram-support-close"
        type="button"
        onClick={() => setIsVisible(false)}
        aria-label={isArabic ? "إغلاق دعوة الدعم" : "Dismiss support invitation"}
      >
        <X size={17} aria-hidden="true" />
      </button>
      <div className="telegram-support-heading">
        <span className="telegram-support-icon"><MessageCircle size={19} aria-hidden="true" /></span>
        <h2 id="telegram-support-title">{isArabic ? "هل تحتاج مساعدة في تثبيت عيالنا؟" : "Need help installing 3ialna?"}</h2>
      </div>
      <p>{isArabic ? "اتبع دليل التثبيت خطوة بخطوة، وشارك رابط التنزيل والدليل مع عائلتك عبر واتساب. فريق الدعم متاح على تيليغرام." : "Follow the step-by-step installation guide, and share the download and guide with your family on WhatsApp. Support is available on Telegram."}</p>
      <div className="telegram-support-actions">
        <a className="telegram-support-link" href="#setup" onClick={() => setIsVisible(false)}>
          <BookOpen size={16} aria-hidden="true" />
          {isArabic ? "عرض دليل التثبيت" : "View installation guide"}
        </a>
        <a className="telegram-support-link secondary" href={whatsappShareUrl} target="_blank" rel="noopener noreferrer">
          <MessageCircle size={16} aria-hidden="true" />
          {isArabic ? "مشاركة عبر واتساب" : "Share on WhatsApp"}
        </a>
        <a className="telegram-support-link secondary" href={supportGroupUrl} target="_blank" rel="noopener noreferrer">
          <Send size={16} aria-hidden="true" />
          {isArabic ? "انضم إلى مجموعة الدعم" : "Join the support group"}
        </a>
      </div>
    </aside>
  );
}
