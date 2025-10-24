/**
 * Account Details Route
 * Display detailed information about a single account
 */

import { createFileRoute } from '@tanstack/react-router';
import { AccountDetails } from '@/features/accounts';
import { DashboardLayout } from '@/features/dashboard/components';

export const Route = createFileRoute('/_auth/accounts/$accountId')({
  component: AccountDetailsPage,
});

function AccountDetailsPage() {
  const { accountId } = Route.useParams();
  return (
    <DashboardLayout>
      <AccountDetails accountId={accountId} />
    </DashboardLayout>
  );
}
