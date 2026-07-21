import type { CleanKind } from './types';

export interface LaneMeta {
  kind: CleanKind;
  /** Was der Tag bedeutet, positiv formuliert */
  title: string;
  /** Kurzform für enge Stellen */
  short: string;
  emoji: string;
  color: string;
  tagline: string;
  /** Frage, die der Tages-Button stellt */
  ask: string;
}

/**
 * Beide Spuren sind Verzicht, werden aber als Gewinn gezeigt: nicht "keine
 * Schokolade", sondern ein sauberer Tag, der Punkte bringt.
 */
export const LANES: Record<CleanKind, LaneMeta> = {
  snacks: {
    kind: 'snacks',
    title: 'Ohne Schokolade & Chips',
    short: 'Snacks',
    emoji: '🍫',
    color: 'var(--color-cocoa)',
    tagline: 'Ein Tag ohne Süßkram und Knabberzeug.',
    ask: 'Heute weder Schokolade noch Chips',
  },
  drinks: {
    kind: 'drinks',
    title: 'Ohne Zuckergetränke',
    short: 'Getränke',
    emoji: '🥤',
    color: 'var(--color-mint)',
    tagline: 'Wasser, Tee, Kaffee — alles ohne Zucker.',
    ask: 'Heute nichts Zuckerhaltiges getrunken',
  },
};

export const LANE_LIST = [LANES.snacks, LANES.drinks];
