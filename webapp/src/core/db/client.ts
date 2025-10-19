/**
 * PGlite database client singleton
 * Manages database connection and initialization
 */

import { PGlite } from '@electric-sql/pglite';
import { DATABASE_VERSION, SCHEMA_SQL, SEED_CATEGORIES_SQL } from './schema';

const DB_NAME = 'wealthwise';

class DatabaseClient {
  private static instance: DatabaseClient;
  private db: PGlite | null = null;
  private initializing: Promise<void> | null = null;

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): DatabaseClient {
    if (!DatabaseClient.instance) {
      DatabaseClient.instance = new DatabaseClient();
    }
    return DatabaseClient.instance;
  }

  /**
   * Initialize database
   * Creates schema and seeds default data on first run
   */
  async initialize(): Promise<void> {
    // If already initializing, wait for it
    if (this.initializing) {
      return this.initializing;
    }

    // If already initialized, return
    if (this.db) {
      return;
    }

    // Start initialization
    this.initializing = this._initialize();
    await this.initializing;
    this.initializing = null;
  }

  private async _initialize(): Promise<void> {
    try {
      console.log('[DB] Initializing PGlite database...');

      // Create database instance with IndexedDB storage
      try {
        this.db = new PGlite(`idb://${DB_NAME}`);
        // Verify database is actually usable with a simple query
        await this.db.exec('SELECT 1');
        console.log('[DB] Database connection verified');
      } catch (error) {
        console.warn(
          '[DB] Failed to create working PGlite instance, clearing corrupted database...',
          error
        );
        await this.clearDatabase();
        // Wait a bit for IndexedDB cleanup to complete
        await new Promise((resolve) => setTimeout(resolve, 500));
        this.db = new PGlite(`idb://${DB_NAME}`);
        // Verify new instance works
        await this.db.exec('SELECT 1');
        console.log('[DB] Fresh database connection verified');
      }

      // Check if database is already set up
      let versionResult: { rows: unknown[] };
      try {
        versionResult = await this.db.query(
          "SELECT value FROM settings WHERE key = 'db_version'"
        );
      } catch (error) {
        // Database likely needs schema initialization or is corrupted
        console.warn(
          '[DB] Cannot read settings table, assuming fresh database...',
          error
        );
        // If query fails, it's likely a fresh database needing schema
        versionResult = { rows: [] };
      }

      if (versionResult.rows.length === 0) {
        // First time setup
        console.log('[DB] First time setup - creating schema...');
        await this.db.exec(SCHEMA_SQL);
        await this.db.exec(SEED_CATEGORIES_SQL);

        // Store database version
        await this.db.query(
          "INSERT INTO settings (key, value) VALUES ('db_version', $1)",
          [DATABASE_VERSION.toString()]
        );

        console.log('[DB] Database initialized successfully');
      } else {
        const versionRow = versionResult.rows[0] as { value: string };
        const currentVersion = Number.parseInt(versionRow.value, 10);
        console.log(
          `[DB] Database already initialized (version ${currentVersion})`
        );

        // Run migrations if needed
        if (currentVersion < DATABASE_VERSION) {
          await this.runMigrations(currentVersion, DATABASE_VERSION);
        }
      }
    } catch (error) {
      console.error('[DB] Failed to initialize database:', error);
      throw error;
    }
  }

  /**
   * Clear corrupted database from IndexedDB
   */
  private async clearDatabase(): Promise<void> {
    try {
      console.log('[DB] Clearing database from IndexedDB...');

      // Don't try to close corrupted connection - just null it out
      // Attempting to close may trigger filesystem reads that fail
      this.db = null;

      // Delete IndexedDB databases (try all possible name variations)
      const dbNames = [
        DB_NAME, // Base name
        `${DB_NAME}-opfs-vfs`, // OPFS variant
        `${DB_NAME}-idb-vfs`, // IDB variant
        `idb://${DB_NAME}`, // Full IDB path
      ];

      for (const name of dbNames) {
        try {
          await new Promise<void>((resolve, reject) => {
            const request = indexedDB.deleteDatabase(name);

            request.onsuccess = () => {
              console.log(`[DB] Successfully deleted: ${name}`);
              resolve();
            };

            request.onerror = () => {
              console.warn(`[DB] Error deleting ${name}:`, request.error);
              reject(request.error);
            };

            request.onblocked = () => {
              console.warn(
                `[DB] Delete blocked for ${name}, forcing after delay...`
              );
              // Force resolution after delay - don't let blocked state prevent cleanup
              setTimeout(() => resolve(), 1000);
            };
          });
        } catch (error) {
          console.warn(`[DB] Failed to clear ${name}:`, error);
          // Continue with other databases even if one fails
        }
      }

      // Also clear any localStorage keys related to the database
      try {
        const keysToRemove: string[] = [];
        for (let i = 0; i < localStorage.length; i++) {
          const key = localStorage.key(i);
          if (key && key.includes(DB_NAME)) {
            keysToRemove.push(key);
          }
        }
        for (const key of keysToRemove) {
          localStorage.removeItem(key);
          console.log(`[DB] Cleared localStorage key: ${key}`);
        }
      } catch (error) {
        console.warn('[DB] Error clearing localStorage:', error);
      }

      console.log('[DB] Database cleared successfully');
    } catch (error) {
      console.error('[DB] Error clearing database:', error);
      // Don't throw - we want initialization to proceed with fresh database
    }
  }

  /**
   * Run database migrations
   */
  private async runMigrations(from: number, to: number): Promise<void> {
    console.log(`[DB] Running migrations from version ${from} to ${to}`);
    // TODO: Implement migration logic when schema changes
    // For now, just update the version
    await this.db?.query(
      "UPDATE settings SET value = $1 WHERE key = 'db_version'",
      [to.toString()]
    );
  }

  /**
   * Get database instance
   * Throws error if not initialized
   */
  getDB(): PGlite {
    if (!this.db) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
    return this.db;
  }

  /**
   * Close database connection
   */
  async close(): Promise<void> {
    if (this.db) {
      await this.db.close();
      this.db = null;
      console.log('[DB] Database connection closed');
    }
  }

  /**
   * Clear and reinitialize database (useful for recovery from corruption)
   */
  async clearAndReinitialize(): Promise<void> {
    console.log('[DB] Clearing and reinitializing database...');
    await this.clearDatabase();
    // Wait for cleanup to complete
    await new Promise((resolve) => setTimeout(resolve, 500));
    this.initializing = null;
    await this.initialize();
    console.log('[DB] Database cleared and reinitialized successfully');
  }

  /**
   * Force reset database - nuclear option for severe corruption
   * This is more aggressive than clearAndReinitialize
   */
  async forceReset(): Promise<void> {
    console.log('[DB] FORCE RESET - Clearing all storage...');

    // Close any existing connection
    this.db = null;
    this.initializing = null;

    // Clear all possible database names
    const allPossibleNames = [
      DB_NAME,
      `${DB_NAME}-opfs-vfs`,
      `${DB_NAME}-idb-vfs`,
      `idb://${DB_NAME}`,
      'wealthwise', // Hardcoded fallback
      'wealthwise-opfs-vfs',
      'wealthwise-idb-vfs',
    ];

    // Get list of all IndexedDB databases
    try {
      const databases = await indexedDB.databases();
      for (const db of databases) {
        if (db.name) {
          allPossibleNames.push(db.name);
        }
      }
    } catch (error) {
      console.warn('[DB] Could not enumerate databases:', error);
    }

    // Delete all databases
    const deletePromises = allPossibleNames.map((name) =>
      new Promise<void>((resolve) => {
        try {
          const request = indexedDB.deleteDatabase(name);
          request.onsuccess = () => {
            console.log(`[DB] Deleted: ${name}`);
            resolve();
          };
          request.onerror = () => {
            console.warn(`[DB] Error deleting ${name}`);
            resolve(); // Continue anyway
          };
          request.onblocked = () => {
            console.warn(`[DB] Blocked: ${name}`);
            setTimeout(() => resolve(), 1000);
          };
          // Timeout fallback
          setTimeout(() => resolve(), 2000);
        } catch (error) {
          console.warn(`[DB] Exception deleting ${name}:`, error);
          resolve();
        }
      })
    );

    await Promise.all(deletePromises);

    // Clear all storage
    try {
      localStorage.clear();
      sessionStorage.clear();
      console.log('[DB] Cleared all storage');
    } catch (error) {
      console.warn('[DB] Error clearing storage:', error);
    }

    // Wait for cleanup
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Reinitialize
    await this.initialize();
    console.log('[DB] Force reset complete');
  }

  /**
   * Execute a query with parameters
   */
  async query<T = unknown>(
    sql: string,
    params?: unknown[]
  ): Promise<{ rows: T[] }> {
    const db = this.getDB();
    const result = await db.query<T>(sql, params);
    return result;
  }

  /**
   * Execute multiple SQL statements
   */
  async exec(sql: string): Promise<void> {
    const db = this.getDB();
    await db.exec(sql);
  }

  /**
   * Start a transaction
   */
  async transaction<T>(callback: (db: PGlite) => Promise<T>): Promise<T> {
    const db = this.getDB();
    await db.exec('BEGIN');
    try {
      const result = await callback(db);
      await db.exec('COMMIT');
      return result;
    } catch (error) {
      await db.exec('ROLLBACK');
      throw error;
    }
  }
}

// Export singleton instance
export const db = DatabaseClient.getInstance();

// Note: Database should be initialized explicitly by calling db.initialize()
// before use, typically in the app initialization hook
