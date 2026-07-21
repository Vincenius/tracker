export type SessionType = 'boulder' | 'home' | 'fallback';
export type Intensity = 'full' | 'min';

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

export interface AppData {
  version: 1;
  sessions: Session[];
  /** Bereits gefeierte Badges – verhindert doppelte Animationen */
  seenBadges: string[];
  /** Bereits erreichtes Level – für die Level-Up-Animation */
  seenLevel: number;
  /** IDs gelöschter Einheiten (Tombstones), damit sie beim Sync nicht zurückkommen */
  deleted: string[];
}

export const XP: Record<SessionType, Record<Intensity, number>> = {
  boulder: { full: 15, min: 15 },
  home: { full: 10, min: 5 },
  fallback: { full: 12, min: 6 },
};

export const XP_PER_LEVEL = 100;

export function xpFor(s: Session): number {
  return XP[s.type][s.intensity];
}
