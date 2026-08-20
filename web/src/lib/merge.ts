import type { AppData } from './types';

/**
 * Zusammenführen zweier Stände (lokal ⟷ Server). Einheiten und Spaziergänge sind
 * unveränderlich und haben eindeutige IDs, deshalb reicht die Vereinigung.
 * Gelöschtes bleibt gelöscht — dafür die Tombstones in `deleted`.
 *
 * Dieselbe Logik steckt in server/index.js — bei Änderungen dort mitziehen.
 */
function union<T extends { id: string; ts: number }>(a: T[], b: T[], deleted: Set<string>): T[] {
  const byId = new Map<string, T>();
  for (const item of [...a, ...b]) {
    if (!deleted.has(item.id)) byId.set(item.id, item);
  }
  return [...byId.values()].sort((x, y) => x.ts - y.ts);
}

export function mergeData(a: AppData, b: AppData): AppData {
  const deleted = new Set([...a.deleted, ...b.deleted]);
  return {
    version: 1,
    sessions: union(a.sessions, b.sessions, deleted),
    walks: union(a.walks, b.walks, deleted),
    cleanDays: union(a.cleanDays, b.cleanDays, deleted),
    stairs: union(a.stairs, b.stairs, deleted),
    cheatDays: union(a.cheatDays, b.cheatDays, deleted),
    pauses: union(a.pauses, b.pauses, deleted),
    seenBadges: [...new Set([...a.seenBadges, ...b.seenBadges])],
    seenLevel: Math.max(a.seenLevel, b.seenLevel),
    deleted: [...deleted],
  };
}

export function sameData(a: AppData, b: AppData): boolean {
  return (
    a.sessions.length === b.sessions.length &&
    a.walks.length === b.walks.length &&
    a.cleanDays.length === b.cleanDays.length &&
    a.stairs.length === b.stairs.length &&
    a.cheatDays.length === b.cheatDays.length &&
    a.pauses.length === b.pauses.length &&
    a.deleted.length === b.deleted.length &&
    a.sessions.every((s, i) => s.id === b.sessions[i]?.id) &&
    a.walks.every((w, i) => w.id === b.walks[i]?.id) &&
    a.cleanDays.every((c, i) => c.id === b.cleanDays[i]?.id) &&
    a.stairs.every((s, i) => s.id === b.stairs[i]?.id) &&
    a.cheatDays.every((c, i) => c.id === b.cheatDays[i]?.id) &&
    a.pauses.every((p, i) => p.id === b.pauses[i]?.id)
  );
}
