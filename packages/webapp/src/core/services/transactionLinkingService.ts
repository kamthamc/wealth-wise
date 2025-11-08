/**
 * Transaction Linking Service
 * Links related transactions together (e.g., transfers between accounts)
 */

import { collection, doc, getDoc, getDocs, getFirestore, query, updateDoc, where } from 'firebase/firestore';

export interface TransactionLink {
  transaction_id: string;
  linked_transaction_id: string;
  link_type: 'transfer' | 'split' | 'refund' | 'reimbursement';
  created_at: Date;
}

export interface LinkedTransaction {
  id: string;
  account_id: string;
  account_name?: string;
  type: 'income' | 'expense' | 'transfer';
  amount: number;
  description: string;
  date: Date;
  category?: string;
}

class TransactionLinkingService {
  private db = getFirestore();

  /**
   * Link two transactions together (e.g., transfer between accounts)
   */
  async linkTransactions(
    transactionId1: string,
    transactionId2: string,
    linkType: 'transfer' | 'split' | 'refund' | 'reimbursement' = 'transfer'
  ): Promise<void> {
    try {
      const transaction1Ref = doc(this.db, 'transactions', transactionId1);
      const transaction2Ref = doc(this.db, 'transactions', transactionId2);

      // Update both transactions with linked_transaction_id
      await Promise.all([
        updateDoc(transaction1Ref, {
          linked_transaction_id: transactionId2,
          link_type: linkType,
          updated_at: new Date(),
        }),
        updateDoc(transaction2Ref, {
          linked_transaction_id: transactionId1,
          link_type: linkType,
          updated_at: new Date(),
        }),
      ]);

      console.log(`Successfully linked transactions: ${transactionId1} ↔ ${transactionId2}`);
    } catch (error) {
      console.error('Error linking transactions:', error);
      throw new Error('Failed to link transactions');
    }
  }

  /**
   * Unlink two transactions
   */
  async unlinkTransactions(transactionId: string): Promise<void> {
    try {
      const transactionRef = doc(this.db, 'transactions', transactionId);
      const transactionSnap = await getDoc(transactionRef);

      if (!transactionSnap.exists()) {
        throw new Error('Transaction not found');
      }

      const linkedTransactionId = transactionSnap.data().linked_transaction_id;

      if (!linkedTransactionId) {
        console.warn('Transaction is not linked');
        return;
      }

      const linkedTransactionRef = doc(this.db, 'transactions', linkedTransactionId);

      // Remove link from both transactions
      await Promise.all([
        updateDoc(transactionRef, {
          linked_transaction_id: null,
          link_type: null,
          updated_at: new Date(),
        }),
        updateDoc(linkedTransactionRef, {
          linked_transaction_id: null,
          link_type: null,
          updated_at: new Date(),
        }),
      ]);

      console.log(`Successfully unlinked transaction: ${transactionId}`);
    } catch (error) {
      console.error('Error unlinking transactions:', error);
      throw new Error('Failed to unlink transactions');
    }
  }

  /**
   * Get the linked transaction for a given transaction
   */
  async getLinkedTransaction(transactionId: string): Promise<LinkedTransaction | null> {
    try {
      const transactionRef = doc(this.db, 'transactions', transactionId);
      const transactionSnap = await getDoc(transactionRef);

      if (!transactionSnap.exists()) {
        throw new Error('Transaction not found');
      }

      const linkedTransactionId = transactionSnap.data().linked_transaction_id;

      if (!linkedTransactionId) {
        return null;
      }

      const linkedTransactionRef = doc(this.db, 'transactions', linkedTransactionId);
      const linkedTransactionSnap = await getDoc(linkedTransactionRef);

      if (!linkedTransactionSnap.exists()) {
        console.warn('Linked transaction not found');
        return null;
      }

      const data = linkedTransactionSnap.data();

      return {
        id: linkedTransactionSnap.id,
        account_id: data.account_id,
        account_name: data.account_name,
        type: data.type,
        amount: data.amount,
        description: data.description,
        date: data.date?.toDate() || new Date(),
        category: data.category,
      };
    } catch (error) {
      console.error('Error getting linked transaction:', error);
      return null;
    }
  }

  /**
   * Get all transfer pairs for a user
   */
  async getTransferPairs(userId: string): Promise<Array<{
    from: LinkedTransaction;
    to: LinkedTransaction;
  }>> {
    try {
      const q = query(
        collection(this.db, 'transactions'),
        where('user_id', '==', userId),
        where('type', '==', 'transfer'),
        where('linked_transaction_id', '!=', null)
      );

      const querySnapshot = await getDocs(q);
      const transactions = querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));

      // Group into pairs (avoid duplicates)
      const pairs: Array<{ from: LinkedTransaction; to: LinkedTransaction }> = [];
      const processed = new Set<string>();

      for (const txn of transactions) {
        if (processed.has(txn.id)) continue;

        const linkedTxn = await this.getLinkedTransaction(txn.id);
        if (linkedTxn) {
          // Determine which is "from" (expense) and which is "to" (income)
          const data = txn as any;
          const from: LinkedTransaction = {
            id: txn.id,
            account_id: data.account_id,
            account_name: data.account_name,
            type: data.type,
            amount: data.amount,
            description: data.description,
            date: data.date?.toDate() || new Date(),
            category: data.category,
          };

          pairs.push({ from, to: linkedTxn });
          processed.add(txn.id);
          processed.add(linkedTxn.id);
        }
      }

      return pairs;
    } catch (error) {
      console.error('Error getting transfer pairs:', error);
      return [];
    }
  }

  /**
   * Check if a transaction is linked
   */
  async isLinked(transactionId: string): Promise<boolean> {
    try {
      const transactionRef = doc(this.db, 'transactions', transactionId);
      const transactionSnap = await getDoc(transactionRef);

      if (!transactionSnap.exists()) {
        return false;
      }

      return !!transactionSnap.data().linked_transaction_id;
    } catch (error) {
      console.error('Error checking transaction link:', error);
      return false;
    }
  }
}

export const transactionLinkingService = new TransactionLinkingService();
