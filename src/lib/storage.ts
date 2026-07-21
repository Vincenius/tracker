import type { AppData, Session, Walk } from './types';

const KEY = 'tracker.v1';
/** Alter Schlüssel aus der Zeit, als die App "Chalk" hieß. */
const LEGACY_KEY = 'chalk.v1';

export const emptyData: AppData = {
  version: 1,
  sessions: [],
  walks: [],
  seenBadges: [],
  seenLevel: 1,
  deleted: [],
};

function isSession(v: unknown): v is Session {
  if (!v || typeof v !== 'object') return false;
  const s = v as Record<string, unknown>;
  return (
    typeof s.id === 'string' &&
    (s.type === 'boulder' || s.type === 'home' || s.type === 'fallback') &&
    (s.intensity === 'full' || s.intensity === 'min') &&
    typeof s.date === 'string' &&
    typeof s.ts === 'number'
  );
}

function isWalk(v: unknown): v is Walk {
  if (!v || typeof v !== 'object') return false;
  const w = v as Record<string, unknown>;
  return typeof w.id === 'string' && typeof w.date === 'string' && typeof w.ts === 'number';
}

export function parseData(raw: unknown): AppData {
  if (!raw || typeof raw !== 'object') return { ...emptyData };
  const d = raw as Record<string, unknown>;
  const sessions = Array.isArray(d.sessions) ? d.sessions.filter(isSession) : [];
  const walks = Array.isArray(d.walks) ? d.walks.filter(isWalk) : [];
  const strings = (v: unknown) =>
    Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : [];
  return {
    version: 1,
    sessions: sessions.sort((a, b) => a.ts - b.ts),
    walks: walks.sort((a, b) => a.ts - b.ts),
    seenBadges: strings(d.seenBadges),
    seenLevel: typeof d.seenLevel === 'number' ? d.seenLevel : 1,
    deleted: strings(d.deleted),
  };
}

export function loadData(): AppData {
  try {
    const raw = localStorage.getItem(KEY) ?? localStorage.getItem(LEGACY_KEY);
    if (!raw) return { ...emptyData };
    const data = parseData(JSON.parse(raw));
    if (!localStorage.getItem(KEY)) saveData(data); // einmalige Migration
    return data;
  } catch {
    return { ...emptyData };
  }
}

export function saveData(data: AppData): void {
  try {
    localStorage.setItem(KEY, JSON.stringify(data));
  } catch {
    /* Speicher voll oder blockiert – die App läuft trotzdem weiter */
  }
}

export function exportFile(data: AppData): void {
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  const stamp = new Date().toISOString().slice(0, 10);
  a.href = url;
  a.download = `tracker-backup-${stamp}.json`;
  a.click();
  URL.revokeObjectURL(url);
}

export async function importFile(file: File): Promise<AppData> {
  const text = await file.text();
  return parseData(JSON.parse(text));
}
