/**
 * WealthWise - Main Application Component
 * Local-first personal finance management application
 */

function App() {
  return (
    <div className="container" style={{ paddingTop: 'var(--space-8)' }}>
      <a href="#main-content" className="skip-link">
        Skip to main content
      </a>

      <main id="main-content">
        <h1>WealthWise</h1>
        <p>
          Personal finance management - <strong>Local-first, Accessible, Secure</strong>
        </p>

        <div style={{ marginTop: 'var(--space-8)' }}>
          <h2>Phase 0: Setup Complete ✅</h2>
          <ul style={{ listStyle: 'disc', paddingLeft: 'var(--space-6)' }}>
            <li>✅ Vite + React 19.2 + TypeScript</li>
            <li>✅ Biome (linting & formatting)</li>
            <li>✅ Vitest + Testing Library</li>
            <li>✅ Playwright (E2E testing)</li>
            <li>✅ Project structure created</li>
            <li>✅ Design tokens defined</li>
            <li>✅ Global styles configured</li>
          </ul>
        </div>

        <div style={{ marginTop: 'var(--space-6)' }}>
          <h3>Next: Phase 1 - Core Infrastructure</h3>
          <p style={{ color: 'var(--text-secondary)' }}>
            Database setup (PGlite), State management (Zustand), Routing (TanStack Router)
          </p>
        </div>
      </main>
    </div>
  )
}

export default App
