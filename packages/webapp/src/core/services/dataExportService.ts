/**
 * Data Export Service - STUB IMPLEMENTATION
 * Original functionality depends on PGlite repositories which have been removed
 * TODO: Implement with Firebase when needed
 */

export interface ExportData {
  accounts: any[];
  transactions: any[];
  budgets: any[];
  categories: any[];
  goals?: any[];
}

class DataExportService {
  async exportToJSON(): Promise<string> {
    throw new Error('Data export service not implemented with Firebase');
  }

  async exportToCSV(): Promise<string> {
    throw new Error('Data export service not implemented with Firebase');
  }

  async importFromJSON(): Promise<void> {
    throw new Error('Data export service not implemented with Firebase');
  }

  async importFromCSV(): Promise<void> {
    throw new Error('Data export service not implemented with Firebase');
  }

  async createBackup(): Promise<Blob> {
    throw new Error('Data export service not implemented with Firebase');
  }

  async restoreBackup(): Promise<void> {
    throw new Error('Data export service not implemented with Firebase');
  }
}

export const dataExportService = new DataExportService();

// Stub exports for SettingsPage
export async function exportData(): Promise<ExportData> {
  throw new Error('Export not implemented with Firebase');
}

export async function importData(_data: ExportData): Promise<void> {
  throw new Error('Import not implemented with Firebase');
}

export async function parseImportFile(_file: File): Promise<ExportData> {
  throw new Error('Parse import not implemented with Firebase');
}

export async function downloadExportFile(_data: ExportData): Promise<void> {
  throw new Error('Download export not implemented with Firebase');
}

export async function clearAllData(): Promise<void> {
  throw new Error('Clear data not implemented with Firebase');
}
