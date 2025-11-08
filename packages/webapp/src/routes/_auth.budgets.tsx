/**
 * Budgets route
 * Manage spending budgets
 */

import { createFileRoute } from '@tanstack/react-router';
import { BudgetsList } from '@/features/budgets';

export const Route = createFileRoute('/_auth/budgets')({
  component: BudgetsList,
});
