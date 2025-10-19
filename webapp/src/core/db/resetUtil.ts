/**
 * Database Reset Utility
 * Provides functions to reset the database from browser console
 */

import { db } from './client';

/**
 * Force reset the entire database
 * Usage from console: window.resetDatabase()
 */
export async function resetDatabase(): Promise<void> {
  console.log('🔄 Starting database reset...');
  
  try {
    await db.forceReset();
    console.log('✅ Database reset successfully! Please refresh the page.');
  } catch (error) {
    console.error('❌ Database reset failed:', error);
    console.log('💡 Try manually: 1) Clear IndexedDB 2) Clear localStorage 3) Refresh');
  }
}

/**
 * Clear and reinitialize database (softer reset)
 * Usage from console: window.reinitDatabase()
 */
export async function reinitDatabase(): Promise<void> {
  console.log('🔄 Reinitializing database...');
  
  try {
    await db.clearAndReinitialize();
    console.log('✅ Database reinitialized successfully!');
  } catch (error) {
    console.error('❌ Database reinitialization failed:', error);
  }
}

/**
 * Manually clear all storage
 */
export async function clearAllStorage(): Promise<void> {
  console.log('🧹 Clearing all storage...');
  
  // Clear localStorage
  localStorage.clear();
  console.log('✅ localStorage cleared');
  
  // Clear IndexedDB
  const databases = await indexedDB.databases();
  for (const db of databases) {
    if (db.name) {
      indexedDB.deleteDatabase(db.name);
      console.log(`✅ IndexedDB "${db.name}" deleted`);
    }
  }
  
  console.log('✅ All storage cleared! Please refresh the page.');
}

// Make functions available globally in development
if (import.meta.env.DEV) {
  (window as any).resetDatabase = resetDatabase;
  (window as any).reinitDatabase = reinitDatabase;
  (window as any).clearAllStorage = clearAllStorage;
  
  console.log('🛠️ Database utilities loaded:');
  console.log('  - window.resetDatabase() - Force reset database');
  console.log('  - window.reinitDatabase() - Clear and reinitialize');
  console.log('  - window.clearAllStorage() - Clear all browser storage');
}
