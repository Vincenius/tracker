import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { initToken, replaceOnServer, syncWithServer } from './api';
import { BADGES, unlockedBadges, type Badge } from './badges';
import { toISODate } from './date';
import { mergeData, sameData } from './merge';
import { computeStats } from './stats';
import { exportFile, importFile, loadData, saveData, emptyData } from './storage';
import type { AppData, Intensity, Session, SessionType, Walk } from './types';

export interface Celebration {
  level?: number;
  badges: Badge[];
}

export type SyncState = 'idle' | 'syncing' | 'synced' | 'offline';

const PUSH_DELAY = 600;
const POLL_INTERVAL = 60_000;

function newId(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}

/** Beim Laden/Mergen gelten alle erfüllten Badges/Level als gesehen – keine Nachfeier. */
function normalizeSeen(data: AppData): AppData {
  const stats = computeStats(data.sessions, data.walks);
  return { ...data, seenBadges: unlockedBadges(stats), seenLevel: stats.level };
}

export function useTracker() {
  const [data, setData] = useState<AppData>(() => normalizeSeen(loadData()));
  const [celebration, setCelebration] = useState<Celebration | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [sync, setSync] = useState<SyncState>('idle');
  const toastTimer = useRef<number | null>(null);
  const pushTimer = useRef<number | null>(null);
  const latest = useRef(data);
  latest.current = data;

  const stats = useMemo(() => computeStats(data.sessions, data.walks), [data.sessions, data.walks]);

  const flash = useCallback((msg: string) => {
    setToast(msg);
    if (toastTimer.current) window.clearTimeout(toastTimer.current);
    toastTimer.current = window.setTimeout(() => setToast(null), 3200);
  }, []);

  const commit = useCallback((next: AppData) => {
    latest.current = next;
    setData(next);
    saveData(next);
  }, []);

  /** Lokalen Stand hochschicken und den gemergten Server-Stand übernehmen. */
  const pushAndPull = useCallback(async () => {
    setSync('syncing');
    try {
      const remote = await syncWithServer(latest.current);
      // Erneut mergen: währenddessen kann lokal etwas dazugekommen sein.
      const merged = normalizeSeen(mergeData(latest.current, remote));
      if (!sameData(merged, latest.current)) commit(merged);
      else saveData(merged);
      setSync('synced');
      return true;
    } catch {
      setSync('offline');
      return false;
    }
  }, [commit]);

  const schedulePush = useCallback(() => {
    if (pushTimer.current) window.clearTimeout(pushTimer.current);
    pushTimer.current = window.setTimeout(() => void pushAndPull(), PUSH_DELAY);
  }, [pushAndPull]);

  // Sync beim Start, im Hintergrund und immer wenn das Gerät wieder aufwacht.
  useEffect(() => {
    initToken();
    void pushAndPull();

    const onWake = () => {
      if (document.visibilityState === 'visible') void pushAndPull();
    };
    const timer = window.setInterval(onWake, POLL_INTERVAL);
    window.addEventListener('focus', onWake);
    window.addEventListener('online', onWake);
    document.addEventListener('visibilitychange', onWake);
    return () => {
      window.clearInterval(timer);
      window.removeEventListener('focus', onWake);
      window.removeEventListener('online', onWake);
      document.removeEventListener('visibilitychange', onWake);
    };
  }, [pushAndPull]);

  /** Fortschritt übernehmen und alles feiern, was dabei neu freigeschaltet wurde. */
  const commitEarned = useCallback(
    (prev: AppData, next: Pick<AppData, 'sessions' | 'walks'>) => {
      const nextStats = computeStats(next.sessions, next.walks);
      const unlocked = unlockedBadges(nextStats);
      const fresh = unlocked.filter((id) => !prev.seenBadges.includes(id));
      const leveledUp = nextStats.level > prev.seenLevel;

      if (leveledUp || fresh.length) {
        setCelebration({
          level: leveledUp ? nextStats.level : undefined,
          badges: BADGES.filter((b) => fresh.includes(b.id)),
        });
      }

      commit({ ...prev, ...next, seenBadges: unlocked, seenLevel: nextStats.level });
      schedulePush();
    },
    [commit, schedulePush],
  );

  const addSession = useCallback(
    (type: SessionType, intensity: Intensity, done: string[] = []) => {
      const prev = latest.current;
      const session: Session = {
        id: newId(),
        type,
        intensity,
        date: toISODate(new Date()),
        ts: Date.now(),
        done,
      };
      commitEarned(prev, { sessions: [...prev.sessions, session], walks: prev.walks });
      return session;
    },
    [commitEarned],
  );

  const removeSession = useCallback(
    (id: string) => {
      const prev = latest.current;
      const sessions = prev.sessions.filter((s) => s.id !== id);
      commit({
        ...prev,
        sessions,
        // Tombstone, sonst schiebt ein anderes Gerät die Einheit zurück.
        deleted: [...new Set([...prev.deleted, id])],
        seenLevel: computeStats(sessions, prev.walks).level,
      });
      schedulePush();
      flash('Einheit entfernt.');
    },
    [commit, flash, schedulePush],
  );

  /**
   * Spaziergang für einen Tag an- oder abhaken. Pro Tag zählt genau einer —
   * ein zweiter Klick nimmt ihn wieder zurück.
   */
  const toggleWalk = useCallback(
    (date: string) => {
      const prev = latest.current;
      const existing = prev.walks.filter((w) => w.date === date);

      if (existing.length) {
        const ids = new Set(existing.map((w) => w.id));
        const walks = prev.walks.filter((w) => !ids.has(w.id));
        commit({
          ...prev,
          walks,
          deleted: [...new Set([...prev.deleted, ...ids])],
          seenLevel: computeStats(prev.sessions, walks).level,
        });
        schedulePush();
        flash('Spaziergang entfernt.');
        return;
      }

      // ts trägt den Zeitpunkt des Eintragens – das Datum steht in `date`.
      const walk: Walk = { id: newId(), date, ts: Date.now() };
      commitEarned(prev, { sessions: prev.sessions, walks: [...prev.walks, walk] });
    },
    [commit, commitEarned, flash, schedulePush],
  );

  /** Import & Zurücksetzen ersetzen den Server-Stand, statt ihn zu mergen. */
  const replaceEverywhere = useCallback(
    async (next: AppData, msg: string) => {
      const local = normalizeSeen(next);
      commit(local);
      flash(msg);
      try {
        setSync('syncing');
        await replaceOnServer(local);
        setSync('synced');
      } catch {
        setSync('offline');
      }
    },
    [commit, flash],
  );

  const resetAll = useCallback(
    () => void replaceEverywhere({ ...emptyData }, 'Alle Daten gelöscht.'),
    [replaceEverywhere],
  );

  const doExport = useCallback(() => {
    exportFile(latest.current);
    flash('Backup heruntergeladen.');
  }, [flash]);

  const doImport = useCallback(
    async (file: File) => {
      try {
        const incoming = await importFile(file);
        await replaceEverywhere(incoming, `${incoming.sessions.length} Einheiten importiert.`);
      } catch {
        flash('Datei konnte nicht gelesen werden.');
      }
    },
    [flash, replaceEverywhere],
  );

  return {
    data,
    stats,
    sync,
    syncNow: pushAndPull,
    celebration,
    dismissCelebration: () => setCelebration(null),
    toast,
    flash,
    addSession,
    removeSession,
    toggleWalk,
    resetAll,
    doExport,
    doImport,
  };
}

export type Tracker = ReturnType<typeof useTracker>;
