// WealthWise - Shared Library
// Smart Personal Finance Management That Makes You Smarter About Money
// Main entry point for all shared models, services, and utilities

// Core Data Models
export * from './models/core-models';

// Repository Interfaces (Local Storage)
export * from './services/service-interfaces';

// Repository Factory
export * from './factories/repository-factory';

// Utilities
export * from './utils/common-utils';

// App Information
export const APP_NAME = 'WealthWise';
export const APP_TAGLINE = 'Smart Personal Finance Management That Makes You Smarter About Money';
export const VERSION = '1.0.0';

// Feature Capabilities (determined at runtime based on device)
export interface DeviceCapabilities {
  hasOnDeviceAI: boolean;
  hasNeuralEngine: boolean;
  hasMLKit: boolean;
  hasVoiceProcessing: boolean;
  hasSecureEnclave: boolean;
}

// Smart Features Configuration
export const SMART_FEATURES = {
  TRANSACTION_CATEGORIZATION: 'Auto-categorize transactions when device supports AI',
  SPENDING_INSIGHTS: 'Smart spending analysis with on-device processing', 
  MERCHANT_RECOGNITION: 'Automatic merchant detection from transaction data',
  VOICE_COMMANDS: 'Natural language processing for voice input',
  PREDICTIVE_BUDGETING: 'AI-powered budget suggestions based on spending patterns'
} as const;