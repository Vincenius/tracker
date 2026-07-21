import type { AppData } from './types';

/**
 * Zusammenführen zweier Stände (lokal ⟷ Server). Einheiten sind unveränderlich
 * und haben eindeutige IDs, deshalb reicht die Vereinigung. Gelöschtes bleibt
 * gelöscht — dafür die Tombstones in `deleted`.
 *
 * Dieselbe Logik steckt in server/index.js — bei Änderungen dort mitziehen.
 */
export function mergeData(a: AppData, b: AppData): AppData {
  const deleted = new Set([...a.deleted, ...b.deleted]);
  const byId = new Map<string, AppData['sessions'][number]>();
  for (const s of [...a.sessions, ...b.sessions]) {
    if (!deleted.has(s.id)) byId.set(s.id, s);
  }
  return {
    version: 1,
    sessions: [...byId.values()].sort((x, y) => x.ts - y.ts),
    seenBadges: [...new Set([...a.seenBadges, ...b.seenBadges])],
    seenLevel: Math.max(a.seenLevel, b.seenLevel),
    deleted: [...deleted],
  };
}

export function sameData(a: AppData, b: AppData): boolean {
  return (
    a.sessions.length === b.sessions.length &&
    a.deleted.length === b.deleted.length &&
    a.sessions.every((s, i) => s.id === b.sessions[i]?.id)
  );
}
