import * as admin from 'firebase-admin';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { onSchedule } from 'firebase-functions/v2/scheduler';

const db = admin.firestore();

/**
 * Pub/Sub topic for budget alerts
 */
export const processBudgetAlerts = onMessagePublished(
  'budget-alerts',
  async (event) => {
    const data = event.data.message.json;
    console.log('Processing budget alert:', data);

    try {
      const { userId, budgetId, spentAmount, budgetAmount, alertType } = data;

      // Create notification document
      await db.collection('notifications').add({
        user_id: userId,
        type: 'budget_alert',
        title: alertType === 'warning' ? 'Budget Warning' : 'Budget Exceeded',
        message: `You've spent ${spentAmount} of ${budgetAmount}`,
        data: {
          budgetId,
          spentAmount,
          budgetAmount,
          percentage: (spentAmount / budgetAmount) * 100,
        },
        read: false,
        created_at: admin.firestore.Timestamp.now(),
      });

      console.log(`Budget alert notification created for user ${userId}`);
    } catch (error) {
      console.error('Error processing budget alert:', error);
      throw error;
    }
  },
);

/**
 * Pub/Sub topic for transaction insights
 */
export const processTransactionInsights = onMessagePublished(
  'transaction-insights',
  async (event) => {
    const data = event.data.message.json;
    console.log('Processing transaction insights:', data);

    try {
      const { userId, insightType, insightData } = data;

      // Create notification for insights
      await db.collection('notifications').add({
        user_id: userId,
        type: 'insight',
        title: getInsightTitle(insightType),
        message: getInsightMessage(insightType, insightData),
        data: insightData,
        read: false,
        created_at: admin.firestore.Timestamp.now(),
      });

      console.log(
        `Transaction insight notification created for user ${userId}`,
      );
    } catch (error) {
      console.error('Error processing transaction insights:', error);
      throw error;
    }
  },
);

/**
 * Pub/Sub topic for scheduled reports
 */
export const processScheduledReports = onMessagePublished(
  'scheduled-reports',
  async (event) => {
    const data = event.data.message.json;
    console.log('Processing scheduled report:', data);

    try {
      const { userId, reportType, schedule } = data;

      // Get user's email
      const userDoc = await admin.auth().getUser(userId);
      const email = userDoc.email;

      if (!email) {
        console.log(`No email found for user ${userId}`);
        return;
      }

      // Generate report (this would call the generateReport function)
      // For now, just create a notification
      await db.collection('notifications').add({
        user_id: userId,
        type: 'report_ready',
        title: 'Your Report is Ready',
        message: `Your ${reportType} report has been generated`,
        data: {
          reportType,
          schedule,
        },
        read: false,
        created_at: admin.firestore.Timestamp.now(),
      });

      console.log(`Scheduled report notification created for user ${userId}`);
    } catch (error) {
      console.error('Error processing scheduled report:', error);
      throw error;
    }
  },
);

/**
 * Pub/Sub topic for data export completion
 */
export const processDataExportComplete = onMessagePublished(
  'data-export-complete',
  async (event) => {
    const data = event.data.message.json;
    console.log('Processing data export completion:', data);

    try {
      const { userId, exportId, downloadUrl, expiresAt } = data;

      // Create notification
      await db.collection('notifications').add({
        user_id: userId,
        type: 'export_ready',
        title: 'Data Export Ready',
        message: 'Your data export is ready for download',
        data: {
          exportId,
          downloadUrl,
          expiresAt,
        },
        read: false,
        created_at: admin.firestore.Timestamp.now(),
      });

      console.log(`Data export notification created for user ${userId}`);
    } catch (error) {
      console.error('Error processing data export completion:', error);
      throw error;
    }
  },
);

/**
 * Schedule function to check budgets daily
 */
export const scheduledBudgetCheck = onSchedule('0 9 * * *', async (event) => {
  console.log('Running scheduled budget check...');

  try {
    const now = admin.firestore.Timestamp.now();

    // Get all active budgets
    const budgetsSnapshot = await db
      .collection('budgets')
      .where('end_date', '>=', now)
      .get();

    for (const budgetDoc of budgetsSnapshot.docs) {
      const budget = budgetDoc.data();
      const budgetId = budgetDoc.id;

      // Get transactions for this budget period
      const transactionsSnapshot = await db
        .collection('transactions')
        .where('user_id', '==', budget.user_id)
        .where('date', '>=', budget.start_date)
        .where('date', '<=', budget.end_date)
        .where('type', '==', 'expense')
        .get();

      let totalSpent = 0;
      transactionsSnapshot.docs.forEach((doc) => {
        const txn = doc.data();
        if (budget.categories.includes(txn.category)) {
          totalSpent += txn.amount || 0;
        }
      });

      const percentage = (totalSpent / budget.amount) * 100;

      // Check if budget needs alert
      if (percentage >= 100 && !budget.exceeded_notified) {
        // Create notification directly (no need for Pub/Sub within scheduled function)
        await db.collection('notifications').add({
          user_id: budget.user_id,
          type: 'budget_alert',
          title: 'Budget Exceeded',
          message: `You've spent ${totalSpent} of ${budget.amount}`,
          data: {
            budgetId,
            spentAmount: totalSpent,
            budgetAmount: budget.amount,
            percentage,
          },
          read: false,
          created_at: admin.firestore.Timestamp.now(),
        });

        // Mark as notified
        await budgetDoc.ref.update({ exceeded_notified: true });
      } else if (percentage >= 80 && !budget.warning_notified) {
        await db.collection('notifications').add({
          user_id: budget.user_id,
          type: 'budget_alert',
          title: 'Budget Warning',
          message: `You've spent ${totalSpent} of ${budget.amount}`,
          data: {
            budgetId,
            spentAmount: totalSpent,
            budgetAmount: budget.amount,
            percentage,
          },
          read: false,
          created_at: admin.firestore.Timestamp.now(),
        });

        await budgetDoc.ref.update({ warning_notified: true });
      }
    }

    console.log('Scheduled budget check completed');
  } catch (error) {
    console.error('Error in scheduled budget check:', error);
    throw error;
  }
});

// Helper functions
function getInsightTitle(insightType: string): string {
  const titles: Record<string, string> = {
    unusual_spending: 'Unusual Spending Detected',
    savings_milestone: 'Savings Milestone Reached',
    category_trend: 'Spending Trend Alert',
    payment_reminder: 'Payment Reminder',
  };
  return titles[insightType] || 'New Insight';
}

function getInsightMessage(insightType: string, data: any): string {
  switch (insightType) {
    case 'unusual_spending':
      return `You've spent ${data.amount} on ${data.category}, which is ${data.percentageIncrease}% more than usual`;
    case 'savings_milestone':
      return `Congratulations! You've saved ${data.amount} this month`;
    case 'category_trend':
      return `Your ${data.category} spending is trending ${data.direction}`;
    case 'payment_reminder':
      return `Payment of ${data.amount} is due on ${data.dueDate}`;
    default:
      return 'You have a new financial insight';
  }
}
