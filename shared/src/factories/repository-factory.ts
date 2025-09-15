// Repository Factory for WealthWise
// Provides factory pattern for creating local repositories across platforms

import {
    ILocalStorageManager,
    ITransactionRepository,
    IAccountRepository,
    IBudgetRepository,
    IAssetRepository,
    ILoanRepository,
    IInvestmentRepository,
    IReportGenerator,
    IBackupService
} from '../services/service-interfaces';

// Repository Factory Interface
export interface IRepositoryFactory {
    // Core repositories
    createTransactionRepository(): ITransactionRepository;
    createAccountRepository(): IAccountRepository;
    createBudgetRepository(): IBudgetRepository;
    createAssetRepository(): IAssetRepository;
    createLoanRepository(): ILoanRepository;
    createInvestmentRepository(): IInvestmentRepository;
    
    // Services
    createReportGenerator(): IReportGenerator;
    createBackupService(): IBackupService;
    
    // Storage manager
    createStorageManager(): ILocalStorageManager;
}

// Platform-specific implementation hints
export interface PlatformStorageConfig {
    platform: 'ios' | 'android' | 'windows';
    encryptionEnabled: boolean;
    biometricAuthEnabled: boolean;
    storageLocation?: string; // Custom storage path for testing or special requirements
    maxDatabaseSize?: number; // In MB
}

// Base repository implementation hints for platforms
export abstract class BaseRepository {
    protected storageManager: ILocalStorageManager;
    protected config: PlatformStorageConfig;
    
    constructor(storageManager: ILocalStorageManager, config: PlatformStorageConfig) {
        this.storageManager = storageManager;
        this.config = config;
    }
    
    // Common methods that all repositories might need
    protected generateId(): string {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    }
    
    protected getCurrentTimestamp(): Date {
        return new Date();
    }
    
    protected async validateEntity<T>(entity: T): Promise<boolean> {
        // Base validation logic - platforms can override
        return entity !== null && entity !== undefined;
    }
}

// Usage patterns for platforms:
/*
iOS Implementation:
- Use Core Data for local storage
- Keychain Services for secure storage
- Core ML for on-device AI (when available)

Android Implementation:
- Use Room with SQLCipher for local storage
- Android Keystore for secure storage
- ML Kit for on-device AI (when available)

Windows Implementation:
- Use Entity Framework with SQLite for local storage
- Windows Credential Manager for secure storage
- ML.NET for on-device AI (when available)
*/

export default IRepositoryFactory;