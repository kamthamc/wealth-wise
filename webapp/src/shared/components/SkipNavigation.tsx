import './SkipNavigation.css';

interface SkipNavigationProps {
  mainId?: string;
  label?: string;
}

/**
 * Skip Navigation component for keyboard accessibility
 * Allows keyboard users to skip repetitive navigation and jump to main content
 *
 * @param mainId - ID of the main content element (default: 'main-content')
 * @param label - Custom label text (default: 'Skip to main content')
 *
 * @example
 * ```tsx
 * function App() {
 *   return (
 *     <>
 *       <SkipNavigation />
 *       <nav>...</nav>
 *       <main id="main-content">...</main>
 *     </>
 *   )
 * }
 * ```
 */
export function SkipNavigation({
  mainId = 'main-content',
  label = 'Skip to main content',
}: SkipNavigationProps) {
  const handleClick = (event: React.MouseEvent<HTMLAnchorElement>) => {
    event.preventDefault();
    const mainElement = document.getElementById(mainId);

    if (mainElement) {
      // Set tabindex to make it focusable if it isn't already
      if (!mainElement.hasAttribute('tabindex')) {
        mainElement.setAttribute('tabindex', '-1');
      }

      // Focus the main element
      mainElement.focus();

      // Scroll into view
      mainElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  return (
    <a href={`#${mainId}`} className="skip-navigation" onClick={handleClick}>
      {label}
    </a>
  );
}

/**
 * Additional skip links component for more complex navigation
 *
 * @example
 * ```tsx
 * function App() {
 *   return (
 *     <>
 *       <SkipLinks
 *         links={[
 *           { href: '#main-content', label: 'Skip to main content' },
 *           { href: '#navigation', label: 'Skip to navigation' },
 *           { href: '#footer', label: 'Skip to footer' },
 *         ]}
 *       />
 *       <nav id="navigation">...</nav>
 *       <main id="main-content">...</main>
 *       <footer id="footer">...</footer>
 *     </>
 *   )
 * }
 * ```
 */
export function SkipLinks({
  links,
}: {
  links: Array<{ href: string; label: string }>;
}) {
  const handleClick = (
    event: React.MouseEvent<HTMLAnchorElement>,
    targetId: string
  ) => {
    event.preventDefault();
    const targetElement = document.getElementById(targetId.replace('#', ''));

    if (targetElement) {
      if (!targetElement.hasAttribute('tabindex')) {
        targetElement.setAttribute('tabindex', '-1');
      }
      targetElement.focus();
      targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  return (
    <nav className="skip-links" aria-label="Skip links">
      {links.map((link) => (
        <a
          key={link.href}
          href={link.href}
          className="skip-navigation"
          onClick={(e) => handleClick(e, link.href)}
        >
          {link.label}
        </a>
      ))}
    </nav>
  );
}
