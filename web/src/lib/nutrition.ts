import type { TreatKind } from './types';

export interface LaneMeta {
  kind: TreatKind;
  /** Was der Eintrag bedeutet */
  title: string;
  /** Kurzform für enge Stellen */
  short: string;
  emoji: string;
  color: string;
  tagline: string;
  /** Beschriftung des Plus-Knopfes */
  add: string;
}

/**
 * Zwei Spuren, beide negativ: eingetragen wird, was daneben ging. Der Ton
 * bleibt trotzdem sachlich — ein Eintrag ist Buchhaltung, keine Strafpredigt.
 */
export const LANES: Record<TreatKind, LaneMeta> = {
  sweets: {
    kind: 'sweets',
    title: 'Süßes gegessen',
    short: 'Gegessen',
    emoji: '🍫',
    color: 'var(--color-cocoa)',
    tagline: 'Schokolade, Kuchen, Chips — alles, was zwischendurch reinrutscht.',
    add: 'Genascht',
  },
  drinks: {
    kind: 'drinks',
    title: 'Süßes getrunken',
    short: 'Getrunken',
    emoji: '🥤',
    color: 'var(--color-mint)',
    tagline: 'Limo, Saft, Zucker im Kaffee — alles außer Wasser und Tee.',
    add: 'Getrunken',
  },
};

export const LANE_LIST = [LANES.sweets, LANES.drinks];
