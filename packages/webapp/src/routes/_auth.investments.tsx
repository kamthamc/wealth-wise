import { createFileRoute } from '@tanstack/react-router'

import { InvestmentsPage } from '@/features/investments/pages/InvestmentsPage'

export const Route = createFileRoute('/_auth/investments')({
  component: InvestmentsPage,
})
