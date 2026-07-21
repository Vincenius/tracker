/** Signature-Element: Silhouette eines Klettergriffs. */
export function HoldIcon({
  className = '',
  filled = false,
}: {
  className?: string;
  filled?: boolean;
}) {
  return (
    <svg viewBox="0 0 32 32" aria-hidden="true" className={className}>
      <path
        d="M11.6 2.6c4.6-1.9 10.1-.4 13.4 3.4 3.6 4.1 4.4 10.4 1.6 15.2-2.4 4.2-7.3 6.9-12 6.6-3.9-.2-7.7-2.6-9.5-6.1C2.7 17.3 3.2 11.6 6 7.6c1.4-2 3.3-3.9 5.6-5Z"
        fill={filled ? 'currentColor' : 'none'}
        stroke="currentColor"
        strokeWidth={filled ? 0 : 2}
        strokeLinejoin="round"
      />
      <path
        d="M13.4 10.2c2.9-1 6.1.6 6.9 3.5.7 2.6-.9 5.4-3.5 6.2-2.4.7-5.1-.5-6.1-2.8-1.1-2.5.1-5.6 2.7-6.9Z"
        fill={filled ? 'var(--color-rock-950)' : 'none'}
        stroke={filled ? 'none' : 'currentColor'}
        strokeWidth={2}
        opacity={filled ? 0.85 : 0.55}
      />
    </svg>
  );
}
