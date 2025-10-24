/**
 * Reports route
 * Financial reports and analytics
 */

import { createFileRoute } from '@tanstack/react-router';
import { ReportsPage } from '@/features/reports';

export const Route = createFileRoute('/_auth/reports')({
  component: ReportsPageRoute,
});

function ReportsPageRoute() {
  return (
    <div className="container">
      <main id="main-content">
        <ReportsPage />
      </main>
    </div>
  );
}
