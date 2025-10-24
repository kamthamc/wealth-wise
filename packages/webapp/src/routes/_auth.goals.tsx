/**
 * Goals route
 * Manage financial goals and savings targets
 */

import { createFileRoute } from '@tanstack/react-router';
import { GoalsList } from '@/features/goals';

export const Route = createFileRoute('/_auth/goals')({
  component: GoalsPage,
});

function GoalsPage() {
  return (
    <div className="container">
      <main id="main-content">
        <GoalsList />
      </main>
    </div>
  );
}
