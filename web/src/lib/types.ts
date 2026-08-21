export type SessionType = 'boulder' | 'home' | 'fallback';
export type Intensity = 'full' | 'min';

/** Die zwei Spuren der Ernährung: Süßes gegessen, Süßes getrunken. */
export type TreatKind = 'sweets' | 'drinks';

export const TREAT_KINDS: TreatKind[] = ['sweets', 'drinks'];

export interface Session {
  id: string;
  type: SessionType;
  intensity: Intensity;
  /** ISO-Datum, z.B. 2026-07-20 */
  date: string;
  ts: number;
  /** IDs der abgehakten Übungen (optional, rein informativ) */
  done?: string[];
}

/** Ein Spaziergang an einem Tag. Ziel: Montag bis Freitag jeweils einer. */
export interface Walk {
  id: string;
  /** ISO-Datum, z.B. 2026-07-20 */
  date: string;
  ts: number;
}

/**
 * Einmal etwas Süßes gegessen oder getrunken. Anders als alles andere ist das
 * ein Minus: jeder Eintrag kostet XP. Wie beim Treppenaufstieg zählt jeder
 * einzelne — beliebig oft am Tag, und nichts einzutragen ist der gute Fall.
 */
export interface Treat {
  id: string;
  /** ISO-Datum, z.B. 2026-07-20 */
  date: string;
  kind: TreatKind;
  ts: number;
}

/**
 * Einmal die Treppe statt des Aufzugs genommen. Anders als beim Spaziergang
 * zählt jeder Eintrag — beliebig oft am Tag.
 */
export interface Stair {
  id: string;
  /** ISO-Datum, z.B. 2026-07-20 */
  date: string;
  ts: number;
}

/**
 * Pausenmodus als Ereignis-Paar: 'start' öffnet eine Pause, 'stop' schließt
 * sie. Ereignisse sind unveränderlich mit eigener ID — der Sync merged sie wie
 * alles andere per Vereinigung, der Zustand ergibt sich aus der Reihenfolge.
 */
export interface PauseEvent {
  id: string;
  /** ISO-Datum, z.B. 2026-07-20 */
  date: string;
  ts: number;
  action: 'start' | 'stop';
}

export interface AppData {
  version: 1;
  sessions: Session[];
  walks: Walk[];
  treats: Treat[];
  stairs: Stair[];
  pauses: PauseEvent[];
  /** Bereits gefeierte Badges – verhindert doppelte Animationen */
  seenBadges: string[];
  /** Bereits erreichtes Level – für die Level-Up-Animation */
  seenLevel: number;
  /** IDs gelöschter Einträge (Tombstones), damit sie beim Sync nicht zurückkommen */
  deleted: string[];
}

/** Ein Spaziergang ist klein — er zählt trotzdem. */
export const XP_WALK = 6;

/** Ein Treppenaufstieg ist noch kleiner — dafür ist er unbegrenzt. */
export const XP_STAIR = 2;

/** Zielanzahl Spaziergänge pro Woche: Montag bis Freitag. */
export const WALK_GOAL = 5;

export const XP: Record<SessionType, Record<Intensity, number>> = {
  boulder: { full: 20, min: 20 },
  home: { full: 14, min: 8 },
  fallback: { full: 16, min: 8 },
};

/**
 * Ernährung gibt keine Punkte — sauber essen ist der Normalfall, nicht die
 * Leistung. Jeder eingetragene Ausrutscher kostet dafür XP: ungefähr so viel,
 * wie ein Spaziergang bringt.
 */
export const XP_TREAT = 5;

export const XP_PER_LEVEL = 150;

export function xpFor(s: Session): number {
  return XP[s.type][s.intensity];
}
