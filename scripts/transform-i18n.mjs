#!/usr/bin/env node
/**
 * Cross-Platform i18n Transformation Script
 * 
 * Converts shared JSON translations to platform-specific formats:
 * - iOS: Localizable.strings (language-REGION.lproj format)
 * - Android: strings.xml (values-{language}-r{REGION} format)
 * - Web: Nested JSON for i18next (language-REGION.json format)
 * 
 * Locale Naming Convention (BCP 47):
 * - Source files: translations/{locale}.json (e.g., en-IN.json, hi-IN.json)
 * - iOS output: generated/ios/{locale}.lproj/Localizable.strings (e.g., en-IN.lproj)
 * - Android output: generated/android/values-{locale}/strings.xml (e.g., values-en-rIN)
 * - Web output: packages/webapp/public/locales/{locale}.json (e.g., en-IN.json)
 * 
 * Supported Locales:
 * - en-IN: English (India) - Default locale for Indian market
 * - hi-IN: Hindi (India)
 * - te-IN: Telugu (India)
 * - ta-IN: Tamil (India)
 * 
 * Usage: pnpm run i18n:transform
 * 
 * To add a new language:
 * 1. Create translations/{locale}.json (copy en-IN.json structure)
 * 2. Add locale to SUPPORTED_LANGUAGES array below
 * 3. Run: node scripts/transform-i18n.mjs
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Paths
const ROOT_DIR = join(__dirname, '..');
const TRANSLATIONS_DIR = join(ROOT_DIR, 'translations');
const OUTPUT_DIR = join(ROOT_DIR, 'translations/generated');

// Supported locales (BCP 47 language-region codes)
// Format: language-REGION (e.g., en-IN for English India)
const SUPPORTED_LANGUAGES = [
  { 
    code: 'en-IN', 
    name: 'English (India)', 
    iosCode: 'en-IN',      // iOS uses language-region format
    androidCode: 'en-rIN'  // Android uses language-rREGION format (values-en-rIN)
  },
  { 
    code: 'hi-IN', 
    name: 'Hindi (India)', 
    iosCode: 'hi-IN', 
    androidCode: 'hi-rIN' 
  },
  { 
    code: 'te-IN', 
    name: 'Telugu (India)', 
    iosCode: 'te-IN', 
    androidCode: 'te-rIN' 
  },
  { 
    code: 'ta-IN', 
    name: 'Tamil (India)', 
    iosCode: 'ta-IN', 
    androidCode: 'ta-rIN' 
  },
  // Fallback for regions without India-specific content
  { 
    code: 'en', 
    name: 'English (Generic)', 
    iosCode: 'en', 
    androidCode: 'en' 
  },
];

/**
 * Flatten nested JSON into dot notation keys
 * Example: { auth: { signIn: "Sign In" } } => { "auth.signIn": "Sign In" }
 */
function flattenTranslations(obj, prefix = '') {
  const result = {};

  for (const [key, value] of Object.entries(obj)) {
    const newKey = prefix ? `${prefix}.${key}` : key;

    if (typeof value === 'string') {
      result[newKey] = value;
    } else if (typeof value === 'object' && value !== null) {
      Object.assign(result, flattenTranslations(value, newKey));
    }
  }

  return result;
}

/**
 * Convert JSON to iOS Localizable.strings format
 * Format: "key" = "value";
 */
function generateiOSStrings(translations, langCode) {
  const header = `/*
  Localizable.strings
  WealthWise
  
  Auto-generated from translations/${langCode}.json
  DO NOT EDIT MANUALLY - Changes will be overwritten
*/

`;

  const entries = Object.entries(translations)
    .map(([key, value]) => {
      // Escape quotes in values
      const escapedValue = value.replace(/"/g, '\\"');
      return `"${key}" = "${escapedValue}";`;
    })
    .join('\n');

  return header + entries + '\n';
}

/**
 * Convert JSON to Android strings.xml format
 */
function generateAndroidXML(translations, langCode) {
  const header = `<?xml version="1.0" encoding="utf-8"?>
<!--
  Auto-generated from translations/${langCode}.json
  DO NOT EDIT MANUALLY - Changes will be overwritten
-->
<resources>
`;

  const footer = `</resources>
`;

  const entries = Object.entries(translations)
    .map(([key, value]) => {
      // Convert dot notation to underscore for Android
      const androidKey = key.replace(/\./g, '_');
      
      // Escape XML special characters
      let escapedValue = value
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, "\\'");

      // Handle interpolation variables ({{var}} -> %s or %1$s)
      const interpolationMatches = escapedValue.match(/\{\{[^}]+\}\}/g);
      if (interpolationMatches) {
        // Replace {{variable}} with %s for simple cases
        escapedValue = escapedValue.replace(/\{\{[^}]+\}\}/g, '%s');
      }

      return `    <string name="${androidKey}">${escapedValue}</string>`;
    })
    .join('\n');

  return header + entries + '\n' + footer;
}

/**
 * Generate TypeScript types from translation keys
 */
function generateTypeScriptTypes(translations) {
  const keys = Object.keys(translations);

  const header = `/**
 * Auto-generated translation keys
 * DO NOT EDIT MANUALLY - Changes will be overwritten
 */

export type TranslationKey = 
`;

  const keyTypes = keys
    .map((key) => `  | '${key}'`)
    .join('\n');

  const footer = `;

/**
 * Type-safe translation function
 */
export type TFunction = (key: TranslationKey, defaultValue?: string) => string;
`;

  return header + keyTypes + footer;
}

/**
 * Main transformation function
 */
function transformTranslations() {
  console.log('🌍 Starting cross-platform i18n transformation...\n');

  // Create output directory
  if (!existsSync(OUTPUT_DIR)) {
    mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  for (const lang of SUPPORTED_LANGUAGES) {
    const inputPath = join(TRANSLATIONS_DIR, `${lang.code}.json`);

    if (!existsSync(inputPath)) {
      console.warn(`⚠️  Translation file not found: ${inputPath}`);
      continue;
    }

    console.log(`📝 Processing ${lang.name} (${lang.code})...`);

    // Read and parse JSON
    const rawJson = readFileSync(inputPath, 'utf-8');
    const translations = JSON.parse(rawJson);

    // Flatten translations
    const flatTranslations = flattenTranslations(translations);
    console.log(`   Found ${Object.keys(flatTranslations).length} translation keys`);

    // Generate iOS .strings
    const iosOutput = join(OUTPUT_DIR, 'ios', `${lang.iosCode}.lproj`);
    mkdirSync(iosOutput, { recursive: true });
    const iosStrings = generateiOSStrings(flatTranslations, lang.code);
    writeFileSync(join(iosOutput, 'Localizable.strings'), iosStrings, 'utf-8');
    console.log(`   ✅ Generated iOS strings: ${iosOutput}/Localizable.strings`);

    // Generate Android strings.xml
    // Android uses values/ for default (en-IN), values-{locale}/ for others
    // For en-IN as default, use values/ (no suffix)
    // For other locales, use values-{androidCode}/
    let androidDirName = 'values';
    if (lang.code !== 'en-IN') {
      androidDirName = `values-${lang.androidCode}`;
    }
    const androidOutput = join(OUTPUT_DIR, 'android', androidDirName);
    mkdirSync(androidOutput, { recursive: true });
    const androidXML = generateAndroidXML(flatTranslations, lang.code);
    writeFileSync(join(androidOutput, 'strings.xml'), androidXML, 'utf-8');
    console.log(`   ✅ Generated Android XML: ${androidOutput}/strings.xml`);

    // Generate Web JSON (already exists, but copy to public folder)
    const webOutput = join(ROOT_DIR, 'packages/webapp/public/locales');
    mkdirSync(webOutput, { recursive: true });
    writeFileSync(join(webOutput, `${lang.code}.json`), rawJson, 'utf-8');
    console.log(`   ✅ Copied Web JSON: ${webOutput}/${lang.code}.json`);

    // Generate TypeScript types (only for English)
    if (lang.code === 'en') {
      const typesOutput = join(ROOT_DIR, 'packages/shared-types/src');
      mkdirSync(typesOutput, { recursive: true });
      const tsTypes = generateTypeScriptTypes(flatTranslations);
      writeFileSync(join(typesOutput, 'i18n.types.ts'), tsTypes, 'utf-8');
      console.log(`   ✅ Generated TypeScript types: ${typesOutput}/i18n.types.ts`);
    }

    console.log();
  }

  console.log('✨ Cross-platform i18n transformation complete!\n');
  console.log('📁 Generated files:');
  console.log('   - iOS: translations/generated/ios/<lang>.lproj/Localizable.strings');
  console.log('   - Android: translations/generated/android/values-<lang>/strings.xml');
  console.log('   - Web: packages/webapp/public/locales/<lang>.json');
  console.log('   - Types: packages/shared-types/src/i18n.types.ts');
}

// Run transformation
try {
  transformTranslations();
} catch (error) {
  console.error('❌ Error during transformation:', error);
  process.exit(1);
}
