/**
 * Index (home) route
 * Redirects to dashboard
 */

import { createFileRoute, redirect } from '@tanstack/react-router'

export const Route = createFileRoute('/')({
  beforeLoad: () => {
    throw redirect({
      to: '/dashboard',
    })
  },
})
