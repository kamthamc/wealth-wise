#!/usr/bin/env tsx
"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
var node_fs_1 = require("node:fs");
var node_path_1 = require("node:path");
var node_url_1 = require("node:url");
var __filename = (0, node_url_1.fileURLToPath)(import.meta.url);
var __dirname = (0, node_path_1.dirname)(__filename);
// Paths
var ROOT_DIR = (0, node_path_1.join)(__dirname, '..');
var TRANSLATIONS_DIR = (0, node_path_1.join)(ROOT_DIR, 'translations');
var OUTPUT_DIR = (0, node_path_1.join)(ROOT_DIR, 'translations/generated');
// Supported languages (ISO 639-1 codes)
var SUPPORTED_LANGUAGES = [
    { code: 'en', name: 'English', iosCode: 'en', androidCode: 'en' },
    { code: 'hi', name: 'Hindi', iosCode: 'hi', androidCode: 'hi' },
    { code: 'te', name: 'Telugu', iosCode: 'te', androidCode: 'te' },
];
/**
 * Flatten nested JSON into dot notation keys
 * Example: { auth: { signIn: "Sign In" } } => { "auth.signIn": "Sign In" }
 */
function flattenTranslations(obj, prefix) {
    if (prefix === void 0) { prefix = ''; }
    var result = {};
    for (var _i = 0, _a = Object.entries(obj); _i < _a.length; _i++) {
        var _b = _a[_i], key = _b[0], value = _b[1];
        var newKey = prefix ? "".concat(prefix, ".").concat(key) : key;
        if (typeof value === 'string') {
            result[newKey] = value;
        }
        else if (typeof value === 'object' && value !== null) {
            Object.assign(result, flattenTranslations(value, newKey));
        }
    }
    return result;
}
/**
 * Convert JSON to iOS Localizable.strings format
 * Format: "key" = "value";
 */
function generateiOSStrings(translations) {
    var header = "/*\n  Localizable.strings\n  WealthWise\n  \n  Auto-generated from translations/en.json\n  DO NOT EDIT MANUALLY - Changes will be overwritten\n*/\n\n";
    var entries = Object.entries(translations)
        .map(function (_a) {
        var key = _a[0], value = _a[1];
        // Escape quotes in values
        var escapedValue = value.replace(/"/g, '\\"');
        return "\"".concat(key, "\" = \"").concat(escapedValue, "\";");
    })
        .join('\n');
    return header + entries + '\n';
}
/**
 * Convert JSON to Android strings.xml format
 */
function generateAndroidXML(translations) {
    var header = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<!--\n  Auto-generated from translations/en.json\n  DO NOT EDIT MANUALLY - Changes will be overwritten\n-->\n<resources>\n";
    var footer = "</resources>\n";
    var entries = Object.entries(translations)
        .map(function (_a) {
        var key = _a[0], value = _a[1];
        // Convert dot notation to underscore for Android
        var androidKey = key.replace(/\./g, '_');
        // Escape XML special characters
        var escapedValue = value
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, "\\'");
        // Handle interpolation variables ({{var}} -> %s or %1$s)
        var interpolationMatches = escapedValue.match(/\{\{[^}]+\}\}/g);
        if (interpolationMatches) {
            // Replace {{variable}} with %s for simple cases
            escapedValue = escapedValue.replace(/\{\{[^}]+\}\}/g, '%s');
        }
        return "    <string name=\"".concat(androidKey, "\">").concat(escapedValue, "</string>");
    })
        .join('\n');
    return header + entries + '\n' + footer;
}
/**
 * Generate TypeScript types from translation keys
 */
function generateTypeScriptTypes(translations) {
    var keys = Object.keys(translations);
    var header = "/**\n * Auto-generated translation keys\n * DO NOT EDIT MANUALLY - Changes will be overwritten\n */\n\nexport type TranslationKey = \n";
    var keyTypes = keys
        .map(function (key) { return "  | '".concat(key, "'"); })
        .join('\n');
    var footer = ";\n\n/**\n * Type-safe translation function\n */\nexport type TFunction = (key: TranslationKey, defaultValue?: string) => string;\n";
    return header + keyTypes + footer;
}
/**
 * Main transformation function
 */
function transformTranslations() {
    console.log('🌍 Starting cross-platform i18n transformation...\n');
    // Create output directory
    if (!(0, node_fs_1.existsSync)(OUTPUT_DIR)) {
        (0, node_fs_1.mkdirSync)(OUTPUT_DIR, { recursive: true });
    }
    for (var _i = 0, SUPPORTED_LANGUAGES_1 = SUPPORTED_LANGUAGES; _i < SUPPORTED_LANGUAGES_1.length; _i++) {
        var lang = SUPPORTED_LANGUAGES_1[_i];
        var inputPath = (0, node_path_1.join)(TRANSLATIONS_DIR, "".concat(lang.code, ".json"));
        if (!(0, node_fs_1.existsSync)(inputPath)) {
            console.warn("\u26A0\uFE0F  Translation file not found: ".concat(inputPath));
            continue;
        }
        console.log("\uD83D\uDCDD Processing ".concat(lang.name, " (").concat(lang.code, ")..."));
        // Read and parse JSON
        var rawJson = (0, node_fs_1.readFileSync)(inputPath, 'utf-8');
        var translations = JSON.parse(rawJson);
        // Flatten translations
        var flatTranslations = flattenTranslations(translations);
        console.log("   Found ".concat(Object.keys(flatTranslations).length, " translation keys"));
        // Generate iOS .strings
        var iosOutput = (0, node_path_1.join)(OUTPUT_DIR, 'ios', "".concat(lang.iosCode, ".lproj"));
        (0, node_fs_1.mkdirSync)(iosOutput, { recursive: true });
        var iosStrings = generateiOSStrings(flatTranslations);
        (0, node_fs_1.writeFileSync)((0, node_path_1.join)(iosOutput, 'Localizable.strings'), iosStrings, 'utf-8');
        console.log("   \u2705 Generated iOS strings: ".concat(iosOutput, "/Localizable.strings"));
        // Generate Android strings.xml
        var androidOutput = (0, node_path_1.join)(OUTPUT_DIR, 'android', "values".concat(lang.androidCode !== 'en' ? "-".concat(lang.androidCode) : ''));
        (0, node_fs_1.mkdirSync)(androidOutput, { recursive: true });
        var androidXML = generateAndroidXML(flatTranslations);
        (0, node_fs_1.writeFileSync)((0, node_path_1.join)(androidOutput, 'strings.xml'), androidXML, 'utf-8');
        console.log("   \u2705 Generated Android XML: ".concat(androidOutput, "/strings.xml"));
        // Generate Web JSON (already exists, but copy to public folder)
        var webOutput = (0, node_path_1.join)(ROOT_DIR, 'packages/webapp/public/locales');
        (0, node_fs_1.mkdirSync)(webOutput, { recursive: true });
        (0, node_fs_1.writeFileSync)((0, node_path_1.join)(webOutput, "".concat(lang.code, ".json")), rawJson, 'utf-8');
        console.log("   \u2705 Copied Web JSON: ".concat(webOutput, "/").concat(lang.code, ".json"));
        // Generate TypeScript types (only for English)
        if (lang.code === 'en') {
            var typesOutput = (0, node_path_1.join)(ROOT_DIR, 'packages/shared-types/src');
            (0, node_fs_1.mkdirSync)(typesOutput, { recursive: true });
            var tsTypes = generateTypeScriptTypes(flatTranslations);
            (0, node_fs_1.writeFileSync)((0, node_path_1.join)(typesOutput, 'i18n.types.ts'), tsTypes, 'utf-8');
            console.log("   \u2705 Generated TypeScript types: ".concat(typesOutput, "/i18n.types.ts"));
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
}
catch (error) {
    console.error('❌ Error during transformation:', error);
    process.exit(1);
}
