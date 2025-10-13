/**
 * PGlite database client singleton
 * Manages database connection and initialization
 */

import { PGlite } from '@electric-sql/pglite'
import { DATABASE_VERSION, SCHEMA_SQL, SEED_CATEGORIES_SQL } from './schema'

const DB_NAME = 'wealthwise'

class DatabaseClient {
  private static instance: DatabaseClient
  private db: PGlite | null = null
  private initializing: Promise<void> | null = null

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): DatabaseClient {
    if (!DatabaseClient.instance) {
      DatabaseClient.instance = new DatabaseClient()
    }
    return DatabaseClient.instance
  }

  /**
   * Initialize database
   * Creates schema and seeds default data on first run
   */
  async initialize(): Promise<void> {
    // If already initializing, wait for it
    if (this.initializing) {
      return this.initializing
    }

    // If already initialized, return
    if (this.db) {
      return
    }

    // Start initialization
    this.initializing = this._initialize()
    await this.initializing
    this.initializing = null
  }

  private async _initialize(): Promise<void> {
    try {
      console.log('[DB] Initializing PGlite database...')

      // Create database instance with IndexedDB storage
      this.db = new PGlite(`idb://${DB_NAME}`)

      // Check if database is already set up
      const versionResult = await this.db.query(
        "SELECT value FROM settings WHERE key = 'db_version'"
      )

      if (versionResult.rows.length === 0) {
        // First time setup
        console.log('[DB] First time setup - creating schema...')
        await this.db.exec(SCHEMA_SQL)
        await this.db.exec(SEED_CATEGORIES_SQL)

        // Store database version
        await this.db.query("INSERT INTO settings (key, value) VALUES ('db_version', $1)", [
          DATABASE_VERSION.toString(),
        ])

        console.log('[DB] Database initialized successfully')
      } else {
        const versionRow = versionResult.rows[0] as { value: string }
        const currentVersion = Number.parseInt(versionRow.value, 10)
        console.log(`[DB] Database already initialized (version ${currentVersion})`)

        // Run migrations if needed
        if (currentVersion < DATABASE_VERSION) {
          await this.runMigrations(currentVersion, DATABASE_VERSION)
        }
      }
    } catch (error) {
      console.error('[DB] Failed to initialize database:', error)
      throw error
    }
  }

  /**
   * Run database migrations
   */
  private async runMigrations(from: number, to: number): Promise<void> {
    console.log(`[DB] Running migrations from version ${from} to ${to}`)
    // TODO: Implement migration logic when schema changes
    // For now, just update the version
    await this.db?.query("UPDATE settings SET value = $1 WHERE key = 'db_version'", [to.toString()])
  }

  /**
   * Get database instance
   * Throws error if not initialized
   */
  getDB(): PGlite {
    if (!this.db) {
      throw new Error('Database not initialized. Call initialize() first.')
    }
    return this.db
  }

  /**
   * Close database connection
   */
  async close(): Promise<void> {
    if (this.db) {
      await this.db.close()
      this.db = null
      console.log('[DB] Database connection closed')
    }
  }

  /**
   * Execute a query with parameters
   */
  async query<T = unknown>(sql: string, params?: unknown[]): Promise<{ rows: T[] }> {
    const db = this.getDB()
    const result = await db.query<T>(sql, params)
    return result
  }

  /**
   * Execute multiple SQL statements
   */
  async exec(sql: string): Promise<void> {
    const db = this.getDB()
    await db.exec(sql)
  }

  /**
   * Start a transaction
   */
  async transaction<T>(callback: (db: PGlite) => Promise<T>): Promise<T> {
    const db = this.getDB()
    await db.exec('BEGIN')
    try {
      const result = await callback(db)
      await db.exec('COMMIT')
      return result
    } catch (error) {
      await db.exec('ROLLBACK')
      throw error
    }
  }
}

// Export singleton instance
export const db = DatabaseClient.getInstance()

// Initialize on module load (async)
// Note: Components should await db.initialize() before using it
if (typeof window !== 'undefined') {
  db.initialize().catch((error) => {
    console.error('[DB] Failed to auto-initialize:', error)
  })
}
