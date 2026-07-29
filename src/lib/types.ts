export type SessionType = 'boulder' | 'home' | 'fallback';
export type Intensity = 'full' | 'min';

/** Die zwei Verzicht-Spuren der Ernährung. Jede läuft für sich. */
export type CleanKind = 'snacks' | 'drinks';

export const CLEAN_KINDS: CleanKind[] = ['snacks', 'drinks'];

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
 * Ein sauberer Tag in einer Spur — also ein Tag ohne Schokolade/Chips bzw. ohne
 * zuckerhaltige Getränke. Wie Sessions und Spaziergänge unveränderlich mit
 * eigener ID, damit der Sync ohne Sonderfälle mergen kann.
 */
export interface CleanDay {
  id: string;
  /** ISO-Datum, z.B. 2026-07-20 */
  date: string;
  kind: CleanKind;
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
  cleanDays: CleanDay[];
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
 * Ernährung: der erste saubere Tag bringt wenig, jeder Tag in Folge mehr —
 * bis zur Deckelung. Das belohnt Serien, ohne dass ein Rückfall alles
 * Gesammelte entwertet: verdiente XP bleiben, nur der Zähler startet neu.
 */
export const XP_CLEAN_BASE = 2;
export const XP_CLEAN_STEP = 1;
export const XP_CLEAN_CAP = 6;
/** Extra, wenn an einem Tag beide Spuren sauber sind. */
export const XP_CLEAN_COMBO = 2;

/** XP für den `streakDay`-ten Tag einer Serie (1-basiert). */
export function xpForCleanDay(streakDay: number): number {
  return Math.min(XP_CLEAN_BASE + XP_CLEAN_STEP * (streakDay - 1), XP_CLEAN_CAP);
}

/** Tage bis die Serie das Maximum erreicht. */
export const CLEAN_CAP_DAY = (XP_CLEAN_CAP - XP_CLEAN_BASE) / XP_CLEAN_STEP + 1;

export const XP_PER_LEVEL = 150;

export function xpFor(s: Session): number {
  return XP[s.type][s.intensity];
}
