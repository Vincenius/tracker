import {
  addWeeks,
  currentWeekKey,
  fromISODate,
  isWeekday,
  prevWeekday,
  toISODate,
  weekKeyOf,
  weeksBetween,
} from './date';
import type { Session, SessionType, Walk } from './types';
import { WALK_GOAL, XP_PER_LEVEL, XP_WALK, xpFor } from './types';
import { WORKOUTS } from './workouts';

/** Wurde beim Abhaken die komplette Übungsliste mit abgehakt? */
function isFullyChecked(s: Session): boolean {
  const exercises = WORKOUTS[s.type][s.intensity].exercises;
  const done = s.done ?? [];
  return exercises.length > 0 && exercises.every((ex) => done.includes(ex.id));
}

export interface WeekSummary {
  key: string;
  sessions: Session[];
  count: number;
  fulfilled: boolean;
  /** Woche wurde ohne Bouldern erfüllt (Home + Fallback) */
  fallbackWeek: boolean;
  walks: Walk[];
  /** Werktage (Mo–Fr) mit Spaziergang */
  walkDays: number;
  /** alle fünf Werktage mit Spaziergang */
  walkPerfect: boolean;
  xp: number;
}

export interface Stats {
  xp: number;
  level: number;
  xpInLevel: number;
  xpToNext: number;
  total: number;
  byType: Record<SessionType, number>;
  weeks: Map<string, WeekSummary>;
  orderedWeeks: WeekSummary[];
  currentStreak: number;
  longestStreak: number;
  fulfilledWeeks: number;
  fallbackWeeks: number;
  /** Einheiten vor 9 Uhr */
  earlyBird: number;
  /** Einheiten ab 21 Uhr */
  nightOwl: number;
  /** Einheiten an Samstag oder Sonntag */
  weekendSessions: number;
  /** abgehakte Minimum-Einheiten */
  minSessions: number;
  /** Einheiten, bei denen die komplette Checkliste abgehakt wurde */
  fullChecklists: number;
  /** Wochen mit 3 oder mehr Einheiten */
  bigWeeks: number;
  /** Wochen mit Home am Montag und Bouldern am Mittwoch */
  onPlanWeeks: number;
  /** erfüllte Wochen nach mindestens 2 leeren Wochen */
  comebacks: number;
  /** erfüllte Wochen, in denen ausschließlich Minimum-Einheiten liefen */
  allMinWeeks: number;
  /** Spaziergänge insgesamt */
  walkTotal: number;
  /** Werktage mit Spaziergang insgesamt */
  walkWeekdays: number;
  /** Spaziergänge am Wochenende */
  weekendWalks: number;
  /** Wochen mit allen fünf Werktagen */
  walkPerfectWeeks: number;
  /** Wochen mit mindestens drei Werktagen */
  walkSolidWeeks: number;
  /** laufende Serie an Werktagen mit Spaziergang (Wochenende zählt nicht dazwischen) */
  walkStreak: number;
  longestWalkStreak: number;
  /** Wochen, in denen sowohl Trainings- als auch Spaziergangsziel erfüllt wurden */
  doubleGoalWeeks: number;
}

export function summarizeWeek(key: string, sessions: Session[], walks: Walk[] = []): WeekSummary {
  const count = sessions.length;
  const has = (t: SessionType) => sessions.some((s) => s.type === t);
  // Vergebend: zwei Einheiten reichen. Die Kombinationen Bouldern+Home und
  // Home+Fallback sind der Normalfall, alles andere wird nicht bestraft.
  const fulfilled = count >= 2;
  // Pro Tag zählt ein Spaziergang. Zwei Geräte können denselben Tag eintragen —
  // beim Mergen bleiben beide erhalten, gewertet wird der Tag trotzdem einmal.
  const dates = new Set(walks.map((w) => w.date));
  const walkDays = [...dates].filter(isWeekday).length;
  return {
    key,
    sessions,
    count,
    fulfilled,
    fallbackWeek: fulfilled && has('fallback') && !has('boulder'),
    walks,
    walkDays,
    walkPerfect: walkDays >= WALK_GOAL,
    xp: sessions.reduce((sum, s) => sum + xpFor(s), 0) + dates.size * XP_WALK,
  };
}

export function computeStats(sessions: Session[], walks: Walk[] = [], now = new Date()): Stats {
  const buckets = new Map<string, Session[]>();
  for (const s of sessions) {
    const k = weekKeyOf(s.date);
    const arr = buckets.get(k);
    if (arr) arr.push(s);
    else buckets.set(k, [s]);
  }

  const walkBuckets = new Map<string, Walk[]>();
  for (const w of walks) {
    const k = weekKeyOf(w.date);
    const arr = walkBuckets.get(k);
    if (arr) arr.push(w);
    else walkBuckets.set(k, [w]);
  }

  const thisWeek = currentWeekKey(now);
  const keys = [...buckets.keys(), ...walkBuckets.keys()].sort();
  const first = keys[0] ?? thisWeek;
  const span = weeksBetween(first < thisWeek ? first : thisWeek, thisWeek);

  const weeks = new Map<string, WeekSummary>();
  const orderedWeeks: WeekSummary[] = [];
  for (const k of span) {
    const w = summarizeWeek(
      k,
      (buckets.get(k) ?? []).slice().sort((a, b) => a.ts - b.ts),
      (walkBuckets.get(k) ?? []).slice().sort((a, b) => a.ts - b.ts),
    );
    weeks.set(k, w);
    orderedWeeks.push(w);
  }

  // Aktueller Streak: die laufende Woche zählt nur, wenn sie schon erfüllt ist –
  // sie bricht den Streak aber niemals, solange sie noch läuft.
  let currentStreak = 0;
  let cursor = weeks.get(thisWeek)?.fulfilled ? thisWeek : addWeeks(thisWeek, -1);
  while (weeks.get(cursor)?.fulfilled) {
    currentStreak++;
    cursor = addWeeks(cursor, -1);
  }

  let longestStreak = 0;
  let run = 0;
  for (const w of orderedWeeks) {
    run = w.fulfilled ? run + 1 : 0;
    if (run > longestStreak) longestStreak = run;
  }

  const byType: Record<SessionType, number> = { boulder: 0, home: 0, fallback: 0 };
  let xp = 0;
  let earlyBird = 0;
  let nightOwl = 0;
  let weekendSessions = 0;
  let minSessions = 0;
  let fullChecklists = 0;
  for (const s of sessions) {
    byType[s.type]++;
    xp += xpFor(s);
    const hour = new Date(s.ts).getHours();
    if (hour < 9) earlyBird++;
    if (hour >= 21) nightOwl++;
    const dow = fromISODate(s.date).getDay();
    if (dow === 0 || dow === 6) weekendSessions++;
    if (s.intensity === 'min') minSessions++;
    if (isFullyChecked(s)) fullChecklists++;
  }

  // ——— Spaziergänge ———
  const walkDates = new Set(walks.map((w) => w.date));
  xp += walkDates.size * XP_WALK;
  const weekdayWalks = [...walkDates].filter(isWeekday);
  const weekendWalks = walkDates.size - weekdayWalks.length;

  // Serie über Werktage: das Wochenende unterbricht nicht, es zählt nur nicht mit.
  // Der heutige Tag bricht die Serie nicht, solange er noch läuft.
  const today = toISODate(now);
  let walkStreak = 0;
  let cursorDay = walkDates.has(today) && isWeekday(today) ? today : prevWeekday(today);
  while (walkDates.has(cursorDay)) {
    walkStreak++;
    cursorDay = prevWeekday(cursorDay);
  }

  let longestWalkStreak = 0;
  const sortedWeekdays = weekdayWalks.slice().sort();
  let walkRun = 0;
  let prevDay: string | null = null;
  for (const day of sortedWeekdays) {
    walkRun = prevDay && prevWeekday(day) === prevDay ? walkRun + 1 : 1;
    if (walkRun > longestWalkStreak) longestWalkStreak = walkRun;
    prevDay = day;
  }

  let bigWeeks = 0;
  let onPlanWeeks = 0;
  let comebacks = 0;
  let allMinWeeks = 0;
  let emptyRun = 0;
  let walkPerfectWeeks = 0;
  let walkSolidWeeks = 0;
  let doubleGoalWeeks = 0;
  for (const w of orderedWeeks) {
    if (w.walkPerfect) walkPerfectWeeks++;
    if (w.walkDays >= 3) walkSolidWeeks++;
    if (w.fulfilled && w.walkPerfect) doubleGoalWeeks++;
    if (w.count >= 3) bigWeeks++;
    if (w.fulfilled && w.sessions.every((s) => s.intensity === 'min')) allMinWeeks++;
    const onPlan =
      w.sessions.some((s) => s.type === 'home' && fromISODate(s.date).getDay() === 1) &&
      w.sessions.some((s) => s.type === 'boulder' && fromISODate(s.date).getDay() === 3);
    if (onPlan) onPlanWeeks++;
    if (w.fulfilled && emptyRun >= 2) comebacks++;
    emptyRun = w.count === 0 ? emptyRun + 1 : 0;
  }

  const level = Math.floor(xp / XP_PER_LEVEL) + 1;

  return {
    xp,
    level,
    xpInLevel: xp % XP_PER_LEVEL,
    xpToNext: XP_PER_LEVEL - (xp % XP_PER_LEVEL),
    total: sessions.length,
    byType,
    weeks,
    orderedWeeks,
    currentStreak,
    longestStreak,
    fulfilledWeeks: orderedWeeks.filter((w) => w.fulfilled).length,
    fallbackWeeks: orderedWeeks.filter((w) => w.fallbackWeek).length,
    earlyBird,
    nightOwl,
    weekendSessions,
    minSessions,
    fullChecklists,
    bigWeeks,
    onPlanWeeks,
    comebacks,
    allMinWeeks,
    walkTotal: walkDates.size,
    walkWeekdays: weekdayWalks.length,
    weekendWalks,
    walkPerfectWeeks,
    walkSolidWeeks,
    walkStreak,
    longestWalkStreak,
    doubleGoalWeeks,
  };
}
