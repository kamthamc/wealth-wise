/**
 * Account Details Route
 * Display detailed information about a single account
 */

import { createFileRoute } from '@tanstack/react-router';
import { AccountDetails } from '@/features/accounts';
import { DashboardLayout } from '@/features/dashboard/components';

export const Route = createFileRoute('/accounts/$accountId')({
  component: AccountDetailsPage,
  beforeLoad: async (context) => {
    const { params } = context;
    console.log('[Route] beforeLoad called with params:', params);
  },
  onCatch: (context) => {
    const { message, name, stack } = context;
    console.error('[Route] onCatch error:', { message, name, stack });
  }
});

function AccountDetailsPage() {
  const { accountId } = Route.useParams();
  console.log('[Route] AccountDetailsPage rendering with accountId:', accountId);

  return (
    <DashboardLayout>
      <AccountDetails accountId={accountId} />
    </DashboardLayout>
  );
}
