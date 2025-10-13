/**
 * Settings route
 * Application settings and preferences
 */

import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/settings')({
  component: SettingsPage,
})

function SettingsPage() {
  return (
    <div className="container" style={{ paddingTop: 'var(--spacing-8)' }}>
      <main id="main-content">
        <h1>Settings</h1>
        <p>Configure your preferences</p>

        <div style={{ marginTop: 'var(--spacing-6)' }}>
          <h2>Coming Soon</h2>
          <ul style={{ listStyle: 'disc', paddingLeft: 'var(--spacing-6)' }}>
            <li>Theme settings (light/dark)</li>
            <li>Currency preferences</li>
            <li>Language selection</li>
            <li>Date format</li>
            <li>Categories management</li>
            <li>Data export/import</li>
            <li>Privacy settings</li>
          </ul>
        </div>
      </main>
    </div>
  )
}
