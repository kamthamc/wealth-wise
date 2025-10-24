/**
 * Data Export/Import Service
 * Handles exporting and importing all application data
 */

import { db } from '../db';

export interface ExportData {
  version: string;
  exportDate: string;
  accounts: unknown[];
  transactions: unknown[];
  budgets: unknown[];
  goals: unknown[];
  goalContributions: unknown[];
  categories: unknown[];
}

/**
 * Export all data from the database
 */
export async function exportData(): Promise<ExportData> {
  try {
    // Fetch all data from database
    const [
      accounts,
      transactions,
      budgets,
      goals,
      goalContributions,
      categories,
    ] = await Promise.all([
      db.query('SELECT * FROM accounts ORDER BY created_at'),
      db.query('SELECT * FROM transactions ORDER BY created_at'),
      db.query('SELECT * FROM budgets ORDER BY created_at'),
      db.query('SELECT * FROM goals ORDER BY created_at'),
      db.query('SELECT * FROM goal_contributions ORDER BY created_at'),
      db.query('SELECT * FROM categories ORDER BY created_at'),
    ]);

    // Create export object
    const exportData: ExportData = {
      version: '1.0.0',
      exportDate: new Date().toISOString(),
      accounts: accounts.rows,
      transactions: transactions.rows,
      budgets: budgets.rows,
      goals: goals.rows,
      goalContributions: goalContributions.rows,
      categories: categories.rows,
    };

    return exportData;
  } catch (error) {
    console.error('Error exporting data:', error);
    throw new Error('Failed to export data');
  }
}

/**
 * Download export data as JSON file
 */
export function downloadExportFile(data: ExportData): void {
  const jsonString = JSON.stringify(data, null, 2);
  const blob = new Blob([jsonString], { type: 'application/json' });
  const url = URL.createObjectURL(blob);

  const link = document.createElement('a');
  link.href = url;
  link.download = `wealthwise-backup-${new Date().toISOString().split('T')[0]}.json`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);

  // Clean up the URL object
  URL.revokeObjectURL(url);
}

/**
 * Import data from JSON file
 */
export async function importData(data: ExportData): Promise<void> {
  try {
    // Validate data structure
    if (!data.version || !data.accounts || !data.transactions) {
      throw new Error('Invalid data format');
    }

    // Start transaction
    await db.query('BEGIN');

    // Clear existing data (optional - ask user first)
    // await db.query('TRUNCATE accounts, transactions, budgets, goals, goal_contributions, categories CASCADE');

    // Import categories first (they're referenced by transactions)
    if (data.categories && data.categories.length > 0) {
      for (const category of data.categories) {
        await db.query(
          `INSERT INTO categories (id, name, type, icon, color, parent_id, is_default, created_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
           ON CONFLICT (id) DO UPDATE SET
             name = EXCLUDED.name,
             type = EXCLUDED.type,
             icon = EXCLUDED.icon,
             color = EXCLUDED.color,
             parent_id = EXCLUDED.parent_id,
             is_default = EXCLUDED.is_default`,
          [
            (category as any).id,
            (category as any).name,
            (category as any).type,
            (category as any).icon,
            (category as any).color,
            (category as any).parent_id,
            (category as any).is_default,
            (category as any).created_at,
          ]
        );
      }
    }

    // Import accounts
    if (data.accounts && data.accounts.length > 0) {
      for (const account of data.accounts) {
        await db.query(
          `INSERT INTO accounts (id, name, type, balance, currency, icon, color, is_active, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
           ON CONFLICT (id) DO UPDATE SET
             name = EXCLUDED.name,
             type = EXCLUDED.type,
             balance = EXCLUDED.balance,
             currency = EXCLUDED.currency,
             icon = EXCLUDED.icon,
             color = EXCLUDED.color,
             is_active = EXCLUDED.is_active,
             updated_at = EXCLUDED.updated_at`,
          [
            (account as any).id,
            (account as any).name,
            (account as any).type,
            (account as any).balance,
            (account as any).currency,
            (account as any).icon,
            (account as any).color,
            (account as any).is_active,
            (account as any).created_at,
            (account as any).updated_at,
          ]
        );
      }
    }

    // Import transactions
    if (data.transactions && data.transactions.length > 0) {
      for (const transaction of data.transactions) {
        await db.query(
          `INSERT INTO transactions (id, account_id, type, category, amount, description, date, tags, location, receipt_url, is_recurring, recurring_frequency, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
           ON CONFLICT (id) DO UPDATE SET
             account_id = EXCLUDED.account_id,
             type = EXCLUDED.type,
             category = EXCLUDED.category,
             amount = EXCLUDED.amount,
             description = EXCLUDED.description,
             date = EXCLUDED.date,
             tags = EXCLUDED.tags,
             location = EXCLUDED.location,
             receipt_url = EXCLUDED.receipt_url,
             is_recurring = EXCLUDED.is_recurring,
             recurring_frequency = EXCLUDED.recurring_frequency,
             updated_at = EXCLUDED.updated_at`,
          [
            (transaction as any).id,
            (transaction as any).account_id,
            (transaction as any).type,
            (transaction as any).category,
            (transaction as any).amount,
            (transaction as any).description,
            (transaction as any).date,
            (transaction as any).tags,
            (transaction as any).location,
            (transaction as any).receipt_url,
            (transaction as any).is_recurring,
            (transaction as any).recurring_frequency,
            (transaction as any).created_at,
            (transaction as any).updated_at,
          ]
        );
      }
    }

    // Import budgets
    if (data.budgets && data.budgets.length > 0) {
      for (const budget of data.budgets) {
        await db.query(
          `INSERT INTO budgets (id, name, category, amount, spent, period, start_date, end_date, alert_threshold, is_active, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
           ON CONFLICT (id) DO UPDATE SET
             name = EXCLUDED.name,
             category = EXCLUDED.category,
             amount = EXCLUDED.amount,
             spent = EXCLUDED.spent,
             period = EXCLUDED.period,
             start_date = EXCLUDED.start_date,
             end_date = EXCLUDED.end_date,
             alert_threshold = EXCLUDED.alert_threshold,
             is_active = EXCLUDED.is_active,
             updated_at = EXCLUDED.updated_at`,
          [
            (budget as any).id,
            (budget as any).name,
            (budget as any).category,
            (budget as any).amount,
            (budget as any).spent,
            (budget as any).period,
            (budget as any).start_date,
            (budget as any).end_date,
            (budget as any).alert_threshold,
            (budget as any).is_active,
            (budget as any).created_at,
            (budget as any).updated_at,
          ]
        );
      }
    }

    // Import goals
    if (data.goals && data.goals.length > 0) {
      for (const goal of data.goals) {
        await db.query(
          `INSERT INTO goals (id, name, target_amount, current_amount, target_date, category, priority, status, icon, color, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
           ON CONFLICT (id) DO UPDATE SET
             name = EXCLUDED.name,
             target_amount = EXCLUDED.target_amount,
             current_amount = EXCLUDED.current_amount,
             target_date = EXCLUDED.target_date,
             category = EXCLUDED.category,
             priority = EXCLUDED.priority,
             status = EXCLUDED.status,
             icon = EXCLUDED.icon,
             color = EXCLUDED.color,
             updated_at = EXCLUDED.updated_at`,
          [
            (goal as any).id,
            (goal as any).name,
            (goal as any).target_amount,
            (goal as any).current_amount,
            (goal as any).target_date,
            (goal as any).category,
            (goal as any).priority,
            (goal as any).status,
            (goal as any).icon,
            (goal as any).color,
            (goal as any).created_at,
            (goal as any).updated_at,
          ]
        );
      }
    }

    // Import goal contributions
    if (data.goalContributions && data.goalContributions.length > 0) {
      for (const contribution of data.goalContributions) {
        await db.query(
          `INSERT INTO goal_contributions (id, goal_id, amount, date, note, created_at)
           VALUES ($1, $2, $3, $4, $5, $6)
           ON CONFLICT (id) DO NOTHING`,
          [
            (contribution as any).id,
            (contribution as any).goal_id,
            (contribution as any).amount,
            (contribution as any).date,
            (contribution as any).note,
            (contribution as any).created_at,
          ]
        );
      }
    }

    // Commit transaction
    await db.query('COMMIT');
  } catch (error) {
    // Rollback on error
    await db.query('ROLLBACK');
    console.error('Error importing data:', error);
    throw new Error('Failed to import data');
  }
}

/**
 * Parse and validate import file
 */
export function parseImportFile(file: File): Promise<ExportData> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (event) => {
      try {
        const data = JSON.parse(event.target?.result as string);

        // Basic validation
        if (!data.version || !data.exportDate) {
          reject(new Error('Invalid file format'));
          return;
        }

        resolve(data);
      } catch (error) {
        reject(new Error('Failed to parse file'));
      }
    };

    reader.onerror = () => {
      reject(new Error('Failed to read file'));
    };

    reader.readAsText(file);
  });
}

/**
 * Clear all data from database
 */
export async function clearAllData(): Promise<void> {
  try {
    await db.query('BEGIN');

    // Truncate all tables in correct order (respecting foreign keys)
    await db.query('TRUNCATE goal_contributions CASCADE');
    await db.query('TRUNCATE goals CASCADE');
    await db.query('TRUNCATE budgets CASCADE');
    await db.query('TRUNCATE transactions CASCADE');
    await db.query('TRUNCATE accounts CASCADE');
    await db.query('TRUNCATE categories CASCADE');

    await db.query('COMMIT');
  } catch (error) {
    await db.query('ROLLBACK');
    console.error('Error clearing data:', error);
    throw new Error('Failed to clear data');
  }
}
