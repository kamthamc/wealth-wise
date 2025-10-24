#!/usr/bin/env node

/**
 * Test script to verify Firestore configuration
 * Tests rules, indexes, and Cloud Functions integration
 */

import { initializeApp } from 'firebase/app';
import { getAuth, signInAnonymously } from 'firebase/auth';
import { getFirestore, collection, addDoc, getDocs, query, where } from 'firebase/firestore';
import { getFunctions, httpsCallable, connectFunctionsEmulator } from 'firebase/functions';
import { connectAuthEmulator } from 'firebase/auth';
import { connectFirestoreEmulator } from 'firebase/firestore';

// Firebase config for emulators
const firebaseConfig = {
  apiKey: 'demo-api-key',
  authDomain: 'demo-project.firebaseapp.com',
  projectId: 'svc-wealthwise',
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const functions = getFunctions(app);

// Connect to emulators
connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
connectFirestoreEmulator(db, '127.0.0.1', 8080);
connectFunctionsEmulator(functions, '127.0.0.1', 5001);

async function testFirestoreConfiguration() {
  console.log('🔥 Testing Firestore Configuration...\n');

  try {
    // Test 1: Authentication
    console.log('1️⃣ Testing Authentication...');
    const userCredential = await signInAnonymously(auth);
    console.log('✅ Authenticated with UID:', userCredential.user.uid);

    // Test 2: Create Account via Cloud Function
    console.log('\n2️⃣ Testing Cloud Function: createAccount...');
    const createAccount = httpsCallable(functions, 'createAccount');
    const accountResult = await createAccount({
      name: 'Test Bank Account',
      type: 'bank',
      balance: 10000,
      currency: 'INR',
    });
    console.log('✅ Account created:', accountResult.data);

    // Test 3: Read from Firestore directly
    console.log('\n3️⃣ Testing Firestore Read...');
    const accountsQuery = query(
      collection(db, 'accounts'),
      where('user_id', '==', userCredential.user.uid)
    );
    const accountsSnapshot = await getDocs(accountsQuery);
    console.log(`✅ Found ${accountsSnapshot.size} account(s)`);
    accountsSnapshot.forEach((doc) => {
      console.log('  -', doc.id, ':', doc.data().name);
    });

    // Test 4: Create Transaction via Cloud Function
    console.log('\n4️⃣ Testing Cloud Function: createTransaction...');
    if (accountsSnapshot.size > 0) {
      const firstAccount = accountsSnapshot.docs[0];
      const createTransaction = httpsCallable(functions, 'createTransaction');
      const transactionResult = await createTransaction({
        account_id: firstAccount.id,
        type: 'income',
        category: 'Salary',
        amount: 5000,
        description: 'Test salary payment',
        date: new Date().toISOString(),
      });
      console.log('✅ Transaction created:', transactionResult.data);
    }

    // Test 5: Create Budget via Cloud Function
    console.log('\n5️⃣ Testing Cloud Function: createBudget...');
    const createBudget = httpsCallable(functions, 'createBudget');
    const budgetResult = await createBudget({
      name: 'Monthly Budget',
      period_type: 'monthly',
      start_date: new Date().toISOString(),
      is_recurring: true,
      rollover_enabled: false,
      categories: [
        { category: 'Food', allocated_amount: 5000, alert_threshold: 0.8 },
        { category: 'Transport', allocated_amount: 2000, alert_threshold: 0.9 },
      ],
    });
    console.log('✅ Budget created:', budgetResult.data);

    // Test 6: Query all collections
    console.log('\n6️⃣ Testing Collection Queries...');
    const budgetsQuery = query(
      collection(db, 'budgets'),
      where('user_id', '==', userCredential.user.uid)
    );
    const budgetsSnapshot = await getDocs(budgetsQuery);
    console.log(`✅ Budgets: ${budgetsSnapshot.size}`);

    const transactionsQuery = query(
      collection(db, 'transactions'),
      where('user_id', '==', userCredential.user.uid)
    );
    const transactionsSnapshot = await getDocs(transactionsQuery);
    console.log(`✅ Transactions: ${transactionsSnapshot.size}`);

    console.log('\n✅ All tests passed! Firestore is configured correctly.\n');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Test failed:', error);
    process.exit(1);
  }
}

// Run tests
testFirestoreConfiguration();
