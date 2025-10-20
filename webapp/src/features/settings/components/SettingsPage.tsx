/**
 * Settings Page
 * Application preferences and configuration
 * WCAG 2.1 AA compliant
 */

import * as Dialog from '@radix-ui/react-dialog';
import * as Select from '@radix-ui/react-select';
import { Calendar, Monitor, Moon, Sun } from 'lucide-react';
import { useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  SegmentedControl,
  type SegmentedControlOption,
} from '@/shared/components';
import {
  clearAllData,
  downloadExportFile,
  type ExportData,
  exportData,
  importData,
  parseImportFile,
} from '../../../core/services/dataExportService';
import { CategoryManager } from './CategoryManager';
import './SettingsPage.css';

type Theme = 'light' | 'dark' | 'system';
type DateFormat = 'DD/MM/YYYY' | 'MM/DD/YYYY' | 'YYYY-MM-DD';
type Currency = 'INR' | 'USD' | 'EUR' | 'GBP';

// Theme options with icons
const THEME_OPTIONS: SegmentedControlOption<Theme>[] = [
  { value: 'light', label: 'Light', icon: <Sun size={16} /> },
  { value: 'dark', label: 'Dark', icon: <Moon size={16} /> },
  { value: 'system', label: 'System', icon: <Monitor size={16} /> },
];

// Date format options
const DATE_FORMAT_OPTIONS: SegmentedControlOption<DateFormat>[] = [
  { value: 'DD/MM/YYYY', label: 'DD/MM/YYYY', icon: <Calendar size={16} /> },
  { value: 'MM/DD/YYYY', label: 'MM/DD/YYYY', icon: <Calendar size={16} /> },
  { value: 'YYYY-MM-DD', label: 'YYYY-MM-DD', icon: <Calendar size={16} /> },
];

export function SettingsPage() {
  const { t, i18n } = useTranslation();
  const fileInputRef = useRef<HTMLInputElement>(null);

  // State
  const [isExporting, setIsExporting] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [showClearDialog, setShowClearDialog] = useState(false);
  const [showImportDialog, setShowImportDialog] = useState(false);
  const [importDataState, setImportDataState] = useState<ExportData | null>(
    null
  );

  // Load from localStorage or use defaults
  const [theme, setTheme] = useState<Theme>(
    (localStorage.getItem('theme') as Theme) || 'system'
  );
  const [dateFormat, setDateFormat] = useState<DateFormat>(
    (localStorage.getItem('dateFormat') as DateFormat) || 'DD/MM/YYYY'
  );
  const [currency, setCurrency] = useState<Currency>(
    (localStorage.getItem('currency') as Currency) || 'INR'
  );

  const handleThemeChange = (value: Theme) => {
    setTheme(value);
    localStorage.setItem('theme', value);

    // Apply theme to document immediately (live update)
    if (value === 'system') {
      const prefersDark = window.matchMedia(
        '(prefers-color-scheme: dark)'
      ).matches;
      document.documentElement.setAttribute(
        'data-theme',
        prefersDark ? 'dark' : 'light'
      );
    } else {
      document.documentElement.setAttribute('data-theme', value);
    }
  };

  const handleLanguageChange = (value: string) => {
    i18n.changeLanguage(value);
  };

  const handleDateFormatChange = (value: DateFormat) => {
    setDateFormat(value);
    localStorage.setItem('dateFormat', value);
  };

  const handleCurrencyChange = (value: Currency) => {
    setCurrency(value);
    localStorage.setItem('currency', value);
  };

  const handleExportData = async () => {
    try {
      setIsExporting(true);
      const data = await exportData();
      downloadExportFile(data);
      alert(t('settings.dataManagement.export.success'));
    } catch (error) {
      console.error('Export failed:', error);
      alert(t('settings.dataManagement.export.error'));
    } finally {
      setIsExporting(false);
    }
  };

  const handleImportFileSelect = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = event.target.files?.[0];
    if (file) {
      parseImportFile(file)
        .then((data) => {
          setImportDataState(data);
          setShowImportDialog(true);
        })
        .catch((error) => {
          console.error('Parse failed:', error);
          alert(t('settings.dataManagement.import.parseError'));
        });
    }
  };

  const handleImportConfirm = async () => {
    if (!importDataState) return;

    try {
      setIsImporting(true);
      await importData(importDataState);
      setShowImportDialog(false);
      alert(t('settings.dataManagement.import.success'));
      // Reload page to refresh all data
      window.location.reload();
    } catch (error) {
      console.error('Import failed:', error);
      alert(t('settings.dataManagement.import.error'));
    } finally {
      setIsImporting(false);
    }
  };

  const handleImportData = () => {
    fileInputRef.current?.click();
  };

  const handleClearData = () => {
    setShowClearDialog(true);
  };

  const handleClearConfirm = async () => {
    try {
      await clearAllData();
      setShowClearDialog(false);
      alert(t('settings.privacy.clearData.success'));
      // Reload page to refresh all data
      window.location.reload();
    } catch (error) {
      console.error('Clear data failed:', error);
      alert(t('settings.privacy.clearData.error'));
    }
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <div className="page-header__content">
          <div className="page-header__text">
            <h1 className="page-header__title">{t('settings.title')}</h1>
            <p className="page-header__subtitle">{t('settings.description')}</p>
          </div>
        </div>
      </div>

      <div className="page-content">
        {/* Appearance Section */}
        <section className="section settings-section">
          <div className="section-header">
            <h2 className="section-header__title">
              {t('settings.appearance.title')}
            </h2>
            <p className="section-header__description">
              {t('settings.appearance.description')}
            </p>
          </div>

          <div className="settings-field">
            <label className="settings-field__label" id="theme-label">
              {t('settings.appearance.theme.label')}
            </label>
            <SegmentedControl
              options={THEME_OPTIONS}
              value={theme}
              onChange={handleThemeChange}
              size="medium"
              aria-labelledby="theme-label"
            />
          </div>
        </section>

        {/* Localization Section */}
        <section className="section settings-section">
          <div className="section-header">
            <h2 className="section-header__title">
              {t('settings.localization.title')}
            </h2>
            <p className="section-header__description">
              {t('settings.localization.description')}
            </p>
          </div>

          <div className="settings-field">
            <label className="settings-field__label" htmlFor="language-select">
              {t('settings.localization.language.label')}
            </label>
            <Select.Root
              value={i18n.language}
              onValueChange={handleLanguageChange}
            >
              <Select.Trigger
                className="settings-select-trigger"
                id="language-select"
                aria-label={t('settings.localization.language.label')}
              >
                <Select.Value />
                <Select.Icon className="settings-select-icon">▼</Select.Icon>
              </Select.Trigger>

              <Select.Portal>
                <Select.Content className="settings-select-content">
                  <Select.Viewport className="settings-select-viewport">
                    <Select.Item value="en-IN" className="settings-select-item">
                      <Select.ItemText>🇮🇳 English (India)</Select.ItemText>
                    </Select.Item>
                    <Select.Item value="hi" className="settings-select-item">
                      <Select.ItemText>🇮🇳 हिन्दी (Hindi)</Select.ItemText>
                    </Select.Item>
                    <Select.Item value="te-IN" className="settings-select-item">
                      <Select.ItemText>🇮🇳 తెలుగు (Telugu)</Select.ItemText>
                    </Select.Item>
                  </Select.Viewport>
                </Select.Content>
              </Select.Portal>
            </Select.Root>
          </div>

          <div className="settings-field">
            <label className="settings-field__label" htmlFor="currency-select">
              {t('settings.localization.currency.label')}
            </label>
            <Select.Root value={currency} onValueChange={handleCurrencyChange}>
              <Select.Trigger
                className="settings-select-trigger"
                id="currency-select"
                aria-label={t('settings.localization.currency.label')}
              >
                <Select.Value />
                <Select.Icon className="settings-select-icon">▼</Select.Icon>
              </Select.Trigger>

              <Select.Portal>
                <Select.Content className="settings-select-content">
                  <Select.Viewport className="settings-select-viewport">
                    <Select.Item value="INR" className="settings-select-item">
                      <Select.ItemText>₹ INR - Indian Rupee</Select.ItemText>
                    </Select.Item>
                    <Select.Item value="USD" className="settings-select-item">
                      <Select.ItemText>$ USD - US Dollar</Select.ItemText>
                    </Select.Item>
                    <Select.Item value="EUR" className="settings-select-item">
                      <Select.ItemText>€ EUR - Euro</Select.ItemText>
                    </Select.Item>
                    <Select.Item value="GBP" className="settings-select-item">
                      <Select.ItemText>£ GBP - British Pound</Select.ItemText>
                    </Select.Item>
                  </Select.Viewport>
                </Select.Content>
              </Select.Portal>
            </Select.Root>
          </div>

          <div className="settings-field">
            <label className="settings-field__label" id="date-format-label">
              {t('settings.localization.dateFormat.label')}
            </label>
            <SegmentedControl
              options={DATE_FORMAT_OPTIONS}
              value={dateFormat}
              onChange={handleDateFormatChange}
              size="medium"
              aria-labelledby="date-format-label"
            />
          </div>
        </section>

        {/* Data Management Section */}
        <section className="section settings-section">
          <div className="section-header">
            <h2 className="section-header__title">
              {t('settings.dataManagement.title')}
            </h2>
            <p className="section-header__description">
              {t('settings.dataManagement.description')}
            </p>
          </div>

          <div className="settings-actions">
            <button
              type="button"
              className="settings-action-button"
              onClick={handleExportData}
              disabled={isExporting}
            >
              <span className="settings-action-icon">💾</span>
              <span className="settings-action-text">
                <span className="settings-action-title">
                  {isExporting 
                    ? t('settings.dataManagement.export.exporting', 'Exporting...')
                    : t('settings.dataManagement.export.label')}
                </span>
                <span className="settings-action-description">
                  {t('settings.dataManagement.export.description')}
                </span>
              </span>
            </button>

            <button
              type="button"
              className="settings-action-button"
              onClick={handleImportData}
              disabled={isImporting}
            >
              <span className="settings-action-icon">📁</span>
              <span className="settings-action-text">
                <span className="settings-action-title">
                  {isImporting
                    ? t('settings.dataManagement.import.importing', 'Importing...')
                    : t('settings.dataManagement.import.label')}
                </span>
                <span className="settings-action-description">
                  {t('settings.dataManagement.import.description')}
                </span>
              </span>
            </button>
          </div>

          {/* Hidden file input */}
          <input
            ref={fileInputRef}
            type="file"
            accept=".json"
            style={{ display: 'none' }}
            onChange={handleImportFileSelect}
          />
        </section>

        {/* Categories Section */}
        <section className="section settings-section">
          <div className="section-header">
            <h2 className="section-header__title">
              {t('settings.categories.title')}
            </h2>
            <p className="section-header__description">
              {t('settings.categories.description')}
            </p>
          </div>
          <CategoryManager />
        </section>

        {/* Privacy Section */}
        <section className="section settings-section">
          <div className="section-header">
            <h2 className="section-header__title">
              {t('settings.privacy.title')}
            </h2>
            <p className="section-header__description">
              {t('settings.privacy.description')}
            </p>
          </div>

          <div className="settings-actions">
            <button
              type="button"
              className="settings-action-button settings-action-button--danger"
              onClick={handleClearData}
            >
              <span className="settings-action-icon">🗑️</span>
              <span className="settings-action-text">
                <span className="settings-action-title">
                  {t('settings.privacy.clearData.label')}
                </span>
                <span className="settings-action-description">
                  {t('settings.privacy.clearData.description')}
                </span>
              </span>
            </button>
          </div>
        </section>
      </div>

      {/* Import Confirmation Dialog */}
      <Dialog.Root open={showImportDialog} onOpenChange={setShowImportDialog}>
        <Dialog.Portal>
          <Dialog.Overlay className="dialog-overlay" />
          <Dialog.Content className="dialog-content">
            <Dialog.Title className="dialog-title">
              {t('settings.dataManagement.import.confirmTitle')}
            </Dialog.Title>
            <Dialog.Description className="dialog-description">
              {t('settings.dataManagement.import.confirmMessage')}
            </Dialog.Description>

            {importDataState && (
              <div className="import-summary">
                <p>
                  <strong>
                    {t('settings.dataManagement.import.accounts')}:
                  </strong>{' '}
                  {importDataState.accounts.length}
                </p>
                <p>
                  <strong>
                    {t('settings.dataManagement.import.transactions')}:
                  </strong>{' '}
                  {importDataState.transactions.length}
                </p>
                <p>
                  <strong>
                    {t('settings.dataManagement.import.budgets')}:
                  </strong>{' '}
                  {importDataState.budgets.length}
                </p>
                <p>
                  <strong>{t('settings.dataManagement.import.goals')}:</strong>{' '}
                  {importDataState.goals.length}
                </p>
              </div>
            )}

            <div className="dialog-actions">
              <Dialog.Close asChild>
                <button
                  type="button"
                  className="dialog-button dialog-button--secondary"
                >
                  {t('common.cancel')}
                </button>
              </Dialog.Close>
              <button
                type="button"
                className="dialog-button dialog-button--primary"
                onClick={handleImportConfirm}
                disabled={isImporting}
              >
                {isImporting ? t('common.loading') : t('common.confirm')}
              </button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      {/* Clear Data Confirmation Dialog */}
      <Dialog.Root open={showClearDialog} onOpenChange={setShowClearDialog}>
        <Dialog.Portal>
          <Dialog.Overlay className="dialog-overlay" />
          <Dialog.Content className="dialog-content">
            <Dialog.Title className="dialog-title">
              {t('settings.privacy.clearData.confirmTitle')}
            </Dialog.Title>
            <Dialog.Description className="dialog-description">
              {t('settings.privacy.clearData.confirmMessage')}
            </Dialog.Description>

            <div className="dialog-actions">
              <Dialog.Close asChild>
                <button
                  type="button"
                  className="dialog-button dialog-button--secondary"
                >
                  {t('common.cancel')}
                </button>
              </Dialog.Close>
              <button
                type="button"
                className="dialog-button dialog-button--danger"
                onClick={handleClearConfirm}
              >
                {t('settings.privacy.clearData.confirm')}
              </button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  );
}
