/**
 * i18n Configuration
 * Setup for internationalization using i18next
 */

import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import enIN from './locales/en-IN.json';
import hi from './locales/hi.json';

// Initialize i18next
i18n
  .use(initReactI18next) // Passes i18n down to react-i18next
  .init({
    resources: {
      'en-IN': {
        translation: enIN,
      },
      hi: {
        translation: hi,
      },
    },
    lng: 'en-IN', // Default language
    fallbackLng: 'en-IN', // Fallback language
    interpolation: {
      escapeValue: false, // React already escapes values
    },
    debug: import.meta.env.DEV, // Enable debug in development
  });

export default i18n;
