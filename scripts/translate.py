#!/usr/bin/env python3
"""
Translation Generator for WealthWise
Translates en-IN.json to hi-IN.json (Hindi) and te-IN.json (Telugu)
"""

import json
import sys
from pathlib import Path

# Load English translations
def load_english():
    with open('translations/en-IN.json', 'r', encoding='utf-8') as f:
        return json.load(f)

# Hindi translations mapping
HINDI_TRANSLATIONS = {
    # App
    "Manage your finances intelligently": "अपने वित्त का बुद्धिमानी से प्रबंधन करें",
    
    # Auth
    "Sign In": "साइन इन करें",
    "Sign Up": "साइन अप करें",
    "Sign Out": "साइन आउट करें",
    "Display Name": "प्रदर्शन नाम",
    "Email": "ईमेल",
    "Password": "पासवर्ड",
    "Confirm Password": "पासवर्ड की पुष्टि करें",
    "Processing...": "प्रक्रिया जारी है...",
    "Or continue with": "या जारी रखें",
    "Sign in with Google": "Google से साइन इन करें",
    "Enter your display name": "अपना प्रदर्शन नाम दर्ज करें",
    
    # Accounts
    "Accounts": "खाते",
    "Add Account": "खाता जोड़ें",
    "Transfer Money": "पैसे ट्रांसफर करें",
    "Manage your bank accounts, credit cards, and other financial accounts": "अपने बैंक खातों, क्रेडिट कार्ड और अन्य वित्तीय खातों का प्रबंधन करें",
    "Total Balance": "कुल शेष राशि",
    "Active Accounts": "सक्रिय खाते",
    "Total Accounts": "कुल खाते",
    "Search accounts by name or account number": "नाम या खाता संख्या से खोजें",
    
    # Common
    "Save": "सहेजें",
    "Cancel": "रद्द करें",
    "Delete": "हटाएं",
    "Edit": "संपादित करें",
    "Close": "बंद करें",
    "Confirm": "पुष्टि करें",
    "Loading...": "लोड हो रहा है...",
    "Error": "त्रुटि",
    "Success": "सफलता",
    "Back": "वापस",
    "Next": "अगला",
    "Previous": "पिछला",
}

# Telugu translations mapping
TELUGU_TRANSLATIONS = {
    # App
    "Manage your finances intelligently": "మీ ఆర్థిక వ్యవహారాలను తెలివిగా నిర్వహించండి",
    
    # Auth
    "Sign In": "సైన్ ఇన్ చేయండి",
    "Sign Up": "సైన్ అప్ చేయండి",
    "Sign Out": "సైన్ అవుట్ చేయండి",
    "Display Name": "ప్రదర్శన పేరు",
    "Email": "ఇమెయిల్",
    "Password": "పాస్‌వర్డ్",
    "Confirm Password": "పాస్‌వర్డ్‌ను నిర్ధారించండి",
    "Processing...": "ప్రాసెస్ అవుతోంది...",
    "Or continue with": "లేదా కొనసాగించండి",
    "Sign in with Google": "Google తో సైన్ ఇన్ చేయండి",
    "Enter your display name": "మీ ప్రదర్శన పేరును నమోదు చేయండి",
    
    # Accounts
    "Accounts": "ఖాతాలు",
    "Add Account": "ఖాతాను జోడించండి",
    "Transfer Money": "డబ్బు బదిలీ చేయండి",
    "Manage your bank accounts, credit cards, and other financial accounts": "మీ బ్యాంక్ ఖాతాలు, క్రెడిట్ కార్డ్‌లు మరియు ఇతర ఆర్థిక ఖాతాలను నిర్వహించండి",
    "Total Balance": "మొత్తం మిగులు",
    "Active Accounts": "చురుకైన ఖాతాలు",
    "Total Accounts": "మొత్తం ఖాతాలు",
    "Search accounts by name or account number": "పేరు లేదా ఖాతా సంఖ్య ద్వారా శోధించండి",
    
    # Common
    "Save": "సేవ్ చేయండి",
    "Cancel": "రద్దు చేయండి",
    "Delete": "తొలగించండి",
    "Edit": "సవరించండి",
    "Close": "మూసివేయండి",
    "Confirm": "నిర్ధారించండి",
    "Loading...": "లోడ్ అవుతోంది...",
    "Error": "లోపం",
    "Success": "విజయం",
    "Back": "వెనుకకు",
    "Next": "తదుపరి",
    "Previous": "మునుపటి",
}

def translate_value(value, translations):
    """Translate a string value using the translation mapping"""
    if isinstance(value, str):
        return translations.get(value, value)
    return value

def translate_dict(data, translations):
    """Recursively translate all string values in a dictionary"""
    if isinstance(data, dict):
        return {k: translate_dict(v, translations) for k, v in data.items()}
    elif isinstance(data, list):
        return [translate_dict(item, translations) for item in data]
    elif isinstance(data, str):
        return translate_value(data, translations)
    return data

def main():
    # Load English
    print("Loading English translations...")
    english = load_english()
    
    # Generate Hindi
    print("Generating Hindi translations...")
    hindi = translate_dict(english, HINDI_TRANSLATIONS)
    with open('translations/hi-IN.json', 'w', encoding='utf-8') as f:
        json.dump(hindi, f, ensure_ascii=False, indent=2)
    print("✓ Hindi translations saved to translations/hi-IN.json")
    
    # Generate Telugu
    print("Generating Telugu translations...")
    telugu = translate_dict(english, TELUGU_TRANSLATIONS)
    with open('translations/te-IN.json', 'w', encoding='utf-8') as f:
        json.dump(telugu, f, ensure_ascii=False, indent=2)
    print("✓ Telugu translations saved to translations/te-IN.json")
    
    print("\nTranslation complete! 🎉")
    print(f"Note: This is a partial translation. Manual review and completion recommended.")

if __name__ == "__main__":
    main()
