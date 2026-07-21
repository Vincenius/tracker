import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { initToken, replaceOnServer, syncWithServer } from './api';
import { BADGES, unlockedBadges, type Badge } from './badges';
import { toISODate } from './date';
import { mergeData, sameData } from './merge';
import { computeStats } from './stats';
import { exportFile, importFile, loadData, saveData, emptyData } from './storage';
import type { AppData, Intensity, Session, SessionType } from './types';

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
  const stats = computeStats(data.sessions);
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

  const stats = useMemo(() => computeStats(data.sessions), [data.sessions]);

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
      const sessions = [...prev.sessions, session];
      const nextStats = computeStats(sessions);
      const unlocked = unlockedBadges(nextStats);
      const fresh = unlocked.filter((id) => !prev.seenBadges.includes(id));
      const leveledUp = nextStats.level > prev.seenLevel;

      if (leveledUp || fresh.length) {
        setCelebration({
          level: leveledUp ? nextStats.level : undefined,
          badges: BADGES.filter((b) => fresh.includes(b.id)),
        });
      }

      commit({ ...prev, sessions, seenBadges: unlocked, seenLevel: nextStats.level });
      schedulePush();
      return session;
    },
    [commit, schedulePush],
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
        seenLevel: computeStats(sessions).level,
      });
      schedulePush();
      flash('Einheit entfernt.');
    },
    [commit, flash, schedulePush],
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
    resetAll,
    doExport,
    doImport,
  };
}

export type Tracker = ReturnType<typeof useTracker>;
