/**
 * Export utilities for transactions and account statements
 * Supports Excel (.xlsx) and PDF formats with proper formatting
 */

import type { Account, Transaction } from '../../../core/db/types';

/**
 * Export transactions to Excel format
 */
export async function exportToExcel(
  transactions: Transaction[],
  accountName: string
): Promise<void> {
  try {
    // Dynamic import to avoid bundling if not used
    const XLSX = await import('xlsx');

    // Prepare data
    const data = [
      ['Date', 'Description', 'Amount', 'Type', 'Category', 'Balance'],
      ...transactions.map(txn => [
        new Date(txn.date).toLocaleDateString('en-IN'),
        txn.description,
        txn.amount,
        txn.type,
        txn.category || '',
        '', // Balance can be calculated if needed
      ]),
    ];

    // Create workbook and worksheet
    const workbook = XLSX.utils.book_new();
    const worksheet = XLSX.utils.aoa_to_sheet(data);

    // Set column widths
    worksheet['!cols'] = [
      { wch: 12 }, // Date
      { wch: 40 }, // Description
      { wch: 15 }, // Amount
      { wch: 10 }, // Type
      { wch: 15 }, // Category
      { wch: 15 }, // Balance
    ];

    // Add worksheet to workbook
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Transactions');

    // Generate filename
    const filename = `${accountName}_transactions_${new Date().toISOString().split('T')[0]}.xlsx`;

    // Save file
    XLSX.writeFile(workbook, filename);
  } catch (error) {
    throw new Error('Excel export library not available. Please install xlsx package.');
  }
}

/**
 * Export account statement to PDF
 */
export async function exportStatementToPDF(
  account: Account,
  transactions: Transaction[]
): Promise<void> {
  try {
    // Dynamic imports
    const jsPDF = (await import('jspdf')).default;
    const autoTable = (await import('jspdf-autotable')).default;

    // Create PDF
    const doc = new jsPDF();

    // Add title
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text('ACCOUNT STATEMENT', 105, 20, { align: 'center' });

    // Add account details
    doc.setFontSize(11);
    doc.setFont('helvetica', 'normal');
    const startY = 35;
    const leftCol = 20;
    const rightCol = 110;

    doc.text('Account Details:', leftCol, startY);
    doc.text(`Account Name: ${account.name}`, leftCol, startY + 7);
    doc.text(`Account Type: ${formatAccountType(account.type)}`, leftCol, startY + 14);
    doc.text(`Account Number: ${account.id.substring(0, 8)}...`, leftCol, startY + 21);

    doc.text(`Current Balance: ₹${account.balance.toLocaleString('en-IN', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`, rightCol, startY + 7);
    doc.text(`Statement Date: ${new Date().toLocaleDateString('en-IN')}`, rightCol, startY + 14);
    doc.text(`Total Transactions: ${transactions.length}`, rightCol, startY + 21);

    // Add transactions table
    const tableData = transactions.map(txn => {
      const desc = txn.description || '';
      return [
        new Date(txn.date).toLocaleDateString('en-IN'),
        desc.length > 40 ? desc.substring(0, 37) + '...' : desc,
        txn.type,
        `₹${txn.amount.toLocaleString('en-IN')}`,
      ];
    });

    autoTable(doc, {
      startY: startY + 35,
      head: [['Date', 'Description', 'Type', 'Amount']],
      body: tableData,
      theme: 'striped',
      headStyles: {
        fillColor: [41, 128, 185],
        textColor: 255,
        fontStyle: 'bold',
      },
      columnStyles: {
        0: { cellWidth: 25 },
        1: { cellWidth: 80 },
        2: { cellWidth: 30 },
        3: { cellWidth: 35, halign: 'right' },
      },
      styles: {
        fontSize: 9,
        cellPadding: 3,
      },
      alternateRowStyles: {
        fillColor: [245, 245, 245],
      },
    });

    // Add footer
    const pageCount = doc.getNumberOfPages();
    for (let i = 1; i <= pageCount; i++) {
      doc.setPage(i);
      doc.setFontSize(9);
      doc.setTextColor(128);
      doc.text(
        `Page ${i} of ${pageCount}`,
        doc.internal.pageSize.getWidth() / 2,
        doc.internal.pageSize.getHeight() - 10,
        { align: 'center' }
      );
    }

    // Generate filename and save
    const filename = `${account.name}_statement_${new Date().toISOString().split('T')[0]}.pdf`;
    doc.save(filename);
  } catch (error) {
    throw new Error(`PDF generation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * Export all accounts to Excel with multiple sheets
 */
export async function exportAllAccountsToExcel(
  accounts: Account[],
  transactionsByAccount: Record<string, Transaction[]>
): Promise<void> {
  try {
    const XLSX = await import('xlsx');

    const workbook = XLSX.utils.book_new();

    // Add summary sheet
    const summaryData = [
      ['Account Summary'],
      [],
      ['Account Name', 'Type', 'Balance', 'Transactions'],
      ...accounts.map(acc => [
        acc.name,
        formatAccountType(acc.type),
        acc.balance,
        transactionsByAccount[acc.id]?.length || 0,
      ]),
      [],
      ['Total Balance', '', accounts.reduce((sum, acc) => sum + acc.balance, 0), ''],
    ];

    const summarySheet = XLSX.utils.aoa_to_sheet(summaryData);
    summarySheet['!cols'] = [{ wch: 30 }, { wch: 20 }, { wch: 15 }, { wch: 15 }];
    XLSX.utils.book_append_sheet(workbook, summarySheet, 'Summary');

    // Add sheet for each account
    accounts.forEach(account => {
      const transactions = transactionsByAccount[account.id] || [];
      const data = [
        ['Date', 'Description', 'Amount', 'Type', 'Category'],
        ...transactions.map(txn => [
          new Date(txn.date).toLocaleDateString('en-IN'),
          txn.description,
          txn.amount,
          txn.type,
          txn.category || '',
        ]),
      ];

      const worksheet = XLSX.utils.aoa_to_sheet(data);
      worksheet['!cols'] = [
        { wch: 12 },
        { wch: 40 },
        { wch: 15 },
        { wch: 10 },
        { wch: 15 },
      ];

      // Sanitize sheet name (max 31 chars, no special characters)
      const sheetName = account.name.substring(0, 31).replace(/[:\\/?*\[\]]/g, '_');
      XLSX.utils.book_append_sheet(workbook, worksheet, sheetName);
    });

    const filename = `all_accounts_${new Date().toISOString().split('T')[0]}.xlsx`;
    XLSX.writeFile(workbook, filename);
  } catch (error) {
    throw new Error('Excel export library not available. Please install xlsx package.');
  }
}

/**
 * Format account type for display
 */
function formatAccountType(type: string): string {
  const typeMap: Record<string, string> = {
    bank: 'Bank Account',
    credit_card: 'Credit Card',
    upi: 'UPI Account',
    brokerage: 'Brokerage Account',
    cash: 'Cash',
    wallet: 'Wallet',
    fixed_deposit: 'Fixed Deposit',
    recurring_deposit: 'Recurring Deposit',
    ppf: 'Public Provident Fund',
    nsc: 'National Savings Certificate',
    kvp: 'Kisan Vikas Patra',
    scss: 'Senior Citizen Savings Scheme',
    post_office: 'Post Office Savings',
  };

  return typeMap[type] || type;
}
