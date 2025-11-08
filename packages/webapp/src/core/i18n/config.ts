/**
 * i18n Configuration
 * Setup for internationalization using i18next with lazy loading and automatic language detection
 */

import i18n from 'i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import HttpBackend from 'i18next-http-backend';
import { initReactI18next } from 'react-i18next';

// Supported languages (BCP 47 locale codes)
export const SUPPORTED_LANGUAGES = ['en-IN', 'hi-IN', 'te-IN', 'ta-IN'] as const;
export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];

// Custom language detector to map browser languages to our supported languages
const customLanguageDetector = {
  name: 'customDetector',
  lookup() {
    const browserLang = navigator.language || navigator.languages?.[0] || 'en-IN';

    // Map browser languages to our supported languages
    // Check for exact matches first
    if (browserLang === 'en-IN') return 'en-IN';
    if (browserLang === 'hi-IN') return 'hi-IN';
    if (browserLang === 'te-IN') return 'te-IN';
    if (browserLang === 'ta-IN') return 'ta-IN';

    // Map language codes to India-specific variants
    if (browserLang.startsWith('hi')) return 'hi-IN'; // Hindi → Hindi (India)
    if (browserLang.startsWith('te')) return 'te-IN'; // Telugu → Telugu (India)
    if (browserLang.startsWith('ta')) return 'ta-IN'; // Tamil → Tamil (India)
    if (browserLang.startsWith('en')) return 'en-IN'; // English → English (India)

    // Default to English (India) for Indian market
    return 'en-IN';
  },
};

// Configure language detector with priority order
const languageDetectorOptions = {
  order: [
    'querystring', // 4. Check URL query string (?lng=en-IN)
    'sessionStorage', // 2. Check sessionStorage
    'localStorage', // 1. Check localStorage first (user preference)
    'cookie', // 3. Check cookie
    'customDetector', // 5. Custom browser language mapping
    'htmlTag', // 7. HTML lang attribute
    'navigator', // 6. Browser navigator.language
  ],

  lookupQuerystring: 'lng',
  lookupCookie: 'i18next',
  lookupLocalStorage: 'app-language',
  lookupSessionStorage: 'app-language',

  caches: ['localStorage'], // Cache detected language

  cookieMinutes: 10080, // 7 days
  cookieDomain: '',
};

// Initialize i18next with lazy loading and language detection
i18n
  .use(HttpBackend) // Load translations using HTTP
  .use(LanguageDetector) // Detect user language from multiple sources
  .use(initReactI18next) // Passes i18n down to react-i18next
  .init({
    fallbackLng: 'en-IN', // Fallback language
    supportedLngs: SUPPORTED_LANGUAGES, // Supported languages

    // Language detection configuration
    detection: languageDetectorOptions,

    backend: {
      // Load from public folder
      loadPath: '/locales/{{lng}}.json',

      // Request options
      requestOptions: {
        // Use no-cache in development, force-cache in production
        cache: import.meta.env.DEV ? 'no-cache' : 'force-cache',
      },
    },

    // Preload only fallback language for instant display
    preload: ['en-IN'],

    interpolation: {
      escapeValue: false, // React already escapes values
    },

    // React options
    react: {
      useSuspense: true, // Enable Suspense for loading states
    },

    debug: import.meta.env.DEV, // Enable debug in development

    // Performance optimizations
    load: 'currentOnly', // Only load current language
    ns: ['wealthwise'], // Single namespace
    defaultNS: 'wealthwise',
  });

// Register custom language detector
const detector = i18n.services.languageDetector;
if (detector) {
  detector.addDetector(customLanguageDetector);
}

// Save language preference on change and update HTML attributes
i18n.on('languageChanged', (lng) => {
  localStorage.setItem('app-language', lng);
  document.documentElement.lang = lng;

  // Update HTML dir attribute for RTL support
  const isRTL = ['ar', 'he', 'fa', 'ur'].some((rtlLang) =>
    lng.startsWith(rtlLang)
  );
  document.documentElement.dir = isRTL ? 'rtl' : 'ltr';
});

export default i18n;
