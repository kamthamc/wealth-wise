/**
 * Budget Progress Component
 * Display budget progress for different categories
 */

import { Card, ProgressBar } from '@/shared/components'
import './BudgetProgress.css'

interface BudgetItem {
  id: string
  category: string
  spent: number
  limit: number
  icon: string
}

export function BudgetProgress() {
  // TODO: Replace with real data from store
  const budgets: BudgetItem[] = [
    { id: '1', category: 'Food & Dining', spent: 12450, limit: 15000, icon: '🍽️' },
    { id: '2', category: 'Transportation', spent: 4200, limit: 5000, icon: '🚗' },
    { id: '3', category: 'Entertainment', spent: 2850, limit: 3000, icon: '🎬' },
    { id: '4', category: 'Shopping', spent: 8900, limit: 8000, icon: '🛍️' },
    { id: '5', category: 'Utilities', spent: 3200, limit: 5000, icon: '💡' },
  ]

  const getVariant = (spent: number, limit: number) => {
    const percentage = (spent / limit) * 100
    if (percentage >= 100) return 'danger'
    if (percentage >= 80) return 'warning'
    return 'success'
  }

  return (
    <section className="budget-progress">
      <Card>
        <div className="budget-progress__header">
          <h2 className="budget-progress__title">Budget Progress</h2>
          <span className="budget-progress__subtitle">This month</span>
        </div>

        <div className="budget-progress__list">
          {budgets.map((budget) => {
            const percentage = (budget.spent / budget.limit) * 100
            const variant = getVariant(budget.spent, budget.limit)

            return (
              <div key={budget.id} className="budget-item">
                <div className="budget-item__header">
                  <div className="budget-item__category">
                    <span className="budget-item__icon">{budget.icon}</span>
                    <span className="budget-item__name">{budget.category}</span>
                  </div>
                  <span className="budget-item__amount">
                    {new Intl.NumberFormat('en-IN', {
                      style: 'currency',
                      currency: 'INR',
                      maximumFractionDigits: 0,
                    }).format(budget.spent)}{' '}
                    /{' '}
                    {new Intl.NumberFormat('en-IN', {
                      style: 'currency',
                      currency: 'INR',
                      maximumFractionDigits: 0,
                    }).format(budget.limit)}
                  </span>
                </div>
                <ProgressBar
                  value={budget.spent}
                  max={budget.limit}
                  variant={variant}
                  size="medium"
                  showValue
                />
                {percentage >= 100 && <p className="budget-item__warning">⚠️ Budget exceeded!</p>}
              </div>
            )
          })}
        </div>
      </Card>
    </section>
  )
}
