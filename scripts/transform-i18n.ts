#!/usr/bin/env tsx
/**
 * Cross-Platform i18n Transformation Script
 * 
 * Converts shared JSON translations to platform-specific formats:
 * - iOS: Localizable.strings
 * - Android: strings.xml
 * - Web: Nested JSON for i18next
 * 
 * Usage: pnpm tsx scripts/transform-i18n.ts
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

// Supported languages (ISO 639-1 codes)
const SUPPORTED_LANGUAGES = [
  { code: 'en', name: 'English', iosCode: 'en', androidCode: 'en' },
  { code: 'hi', name: 'Hindi', iosCode: 'hi', androidCode: 'hi' },
  { code: 'te', name: 'Telugu', iosCode: 'te', androidCode: 'te' },
] as const;

type TranslationValue = string | Record<string, unknown>;
type FlatTranslations = Record<string, string>;

/**
 * Flatten nested JSON into dot notation keys
 * Example: { auth: { signIn: "Sign In" } } => { "auth.signIn": "Sign In" }
 */
function flattenTranslations(
  obj: Record<string, TranslationValue>,
  prefix = '',
): FlatTranslations {
  const result: FlatTranslations = {};

  for (const [key, value] of Object.entries(obj)) {
    const newKey = prefix ? `${prefix}.${key}` : key;

    if (typeof value === 'string') {
      result[newKey] = value;
    } else if (typeof value === 'object' && value !== null) {
      Object.assign(result, flattenTranslations(value as Record<string, TranslationValue>, newKey));
    }
  }

  return result;
}

/**
 * Convert JSON to iOS Localizable.strings format
 * Format: "key" = "value";
 */
function generateiOSStrings(translations: FlatTranslations): string {
  const header = `/*
  Localizable.strings
  WealthWise
  
  Auto-generated from translations/en.json
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
function generateAndroidXML(translations: FlatTranslations): string {
  const header = `<?xml version="1.0" encoding="utf-8"?>
<!--
  Auto-generated from translations/en.json
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
function generateTypeScriptTypes(translations: FlatTranslations): string {
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
    const translations = JSON.parse(rawJson) as Record<string, TranslationValue>;

    // Flatten translations
    const flatTranslations = flattenTranslations(translations);
    console.log(`   Found ${Object.keys(flatTranslations).length} translation keys`);

    // Generate iOS .strings
    const iosOutput = join(OUTPUT_DIR, 'ios', `${lang.iosCode}.lproj`);
    mkdirSync(iosOutput, { recursive: true });
    const iosStrings = generateiOSStrings(flatTranslations);
    writeFileSync(join(iosOutput, 'Localizable.strings'), iosStrings, 'utf-8');
    console.log(`   ✅ Generated iOS strings: ${iosOutput}/Localizable.strings`);

    // Generate Android strings.xml
    const androidOutput = join(OUTPUT_DIR, 'android', `values${lang.androidCode !== 'en' ? `-${lang.androidCode}` : ''}`);
    mkdirSync(androidOutput, { recursive: true });
    const androidXML = generateAndroidXML(flatTranslations);
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
