/**
 * Base repository class with common CRUD operations
 * Provides a foundation for entity-specific repositories
 */

import type { PGlite } from '@electric-sql/pglite'
import { db } from '../client'

export abstract class BaseRepository<T> {
  protected tableName: string

  constructor(tableName: string) {
    this.tableName = tableName
  }

  /**
   * Get database instance
   */
  protected getDB(): PGlite {
    return db.getDB()
  }

  /**
   * Find entity by ID
   */
  async findById(id: string): Promise<T | null> {
    const result = await db.query<T>(`SELECT * FROM ${this.tableName} WHERE id = $1`, [id])
    return result.rows[0] || null
  }

  /**
   * Find all entities
   */
  async findAll(): Promise<T[]> {
    const result = await db.query<T>(`SELECT * FROM ${this.tableName}`)
    return result.rows
  }

  /**
   * Delete entity by ID
   */
  async delete(id: string): Promise<boolean> {
    const result = await db.query(`DELETE FROM ${this.tableName} WHERE id = $1 RETURNING id`, [id])
    return result.rows.length > 0
  }

  /**
   * Count entities
   */
  async count(whereClause = '', params: unknown[] = []): Promise<number> {
    const sql = whereClause
      ? `SELECT COUNT(*) as count FROM ${this.tableName} WHERE ${whereClause}`
      : `SELECT COUNT(*) as count FROM ${this.tableName}`

    const result = await db.query<{ count: string }>(sql, params)
    return Number.parseInt(result.rows[0]?.count || '0', 10)
  }

  /**
   * Check if entity exists
   */
  async exists(id: string): Promise<boolean> {
    const result = await db.query(`SELECT 1 FROM ${this.tableName} WHERE id = $1 LIMIT 1`, [id])
    return result.rows.length > 0
  }

  /**
   * Execute a custom query
   */
  protected async query<R = T>(sql: string, params?: unknown[]): Promise<R[]> {
    const result = await db.query<R>(sql, params)
    return result.rows
  }

  /**
   * Build WHERE clause from filters
   */
  protected buildWhereClause(filters: Record<string, unknown>): {
    clause: string
    params: unknown[]
  } {
    const conditions: string[] = []
    const params: unknown[] = []
    let paramIndex = 1

    for (const [key, value] of Object.entries(filters)) {
      if (value !== undefined && value !== null) {
        conditions.push(`${key} = $${paramIndex}`)
        params.push(value)
        paramIndex++
      }
    }

    return {
      clause: conditions.length > 0 ? conditions.join(' AND ') : '',
      params,
    }
  }
}
