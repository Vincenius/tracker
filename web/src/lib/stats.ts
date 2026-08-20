import { cheatInfo } from './cheat';
import {
  addDays,
  addWeeks,
  currentWeekKey,
  fromISODate,
  isWeekday,
  prevWeekday,
  toISODate,
  weekKeyOf,
  weeksBetween,
} from './date';
import { pauseInfo } from './pause';
import type {
  CheatDay,
  CleanDay,
  CleanKind,
  PauseEvent,
  Session,
  SessionType,
  Stair,
  Walk,
} from './types';
import {
  CLEAN_KINDS,
  WALK_GOAL,
  XP_CLEAN_COMBO,
  XP_PER_LEVEL,
  XP_STAIR,
  XP_WALK,
  xpFor,
  xpForCleanDay,
} from './types';
import { WORKOUTS } from './workouts';

/** Wurde beim Abhaken die komplette Übungsliste mit abgehakt? */
function isFullyChecked(s: Session): boolean {
  const exercises = WORKOUTS[s.type][s.intensity].exercises;
  const done = s.done ?? [];
  return exercises.length > 0 && exercises.every((ex) => done.includes(ex.id));
}

/** Sieben Tage pro Woche — Ernährung kennt kein Wochenende. */
export const CLEAN_GOAL = 7;

export interface LaneStats {
  kind: CleanKind;
  /** Alle sauberen Tage dieser Spur */
  dates: Set<string>;
  total: number;
  /** Laufende Serie; der heutige Tag bricht sie nicht, solange er läuft */
  currentStreak: number;
  longestStreak: number;
  /** XP, die der nächste saubere Tag in dieser Spur bringt */
  nextXp: number;
  xp: number;
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
  clean: CleanDay[];
  /** saubere Tage je Spur in dieser Woche */
  cleanDays: Record<CleanKind, number>;
  /** Tage, an denen beide Spuren sauber waren */
  cleanBothDays: number;
  /** alle sieben Tage in beiden Spuren sauber */
  cleanPerfect: boolean;
  stairs: Stair[];
  /** Treppenaufstiege in dieser Woche — jeder einzelne zählt */
  stairCount: number;
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

  // ——— Ernährung ———
  lanes: Record<CleanKind, LaneStats>;
  /** Tage, an denen beide Spuren sauber waren */
  cleanBothDays: number;
  /** laufende Serie an Tagen mit beiden Spuren sauber */
  cleanBothStreak: number;
  longestCleanBothStreak: number;
  /** Serien von 7 vollen Tagen nach einem Ausrutscher */
  cleanComebacks: number;
  /** Tage, an denen mindestens eine Spur sauber war */
  cleanAnyDays: number;
  /** XP aus der Ernährung insgesamt */
  cleanXp: number;
  /** Wochen mit 7/7 in beiden Spuren */
  cleanPerfectWeeks: number;
  /** Wochen mit Trainingsziel, allen Spaziergängen und einer perfekten Ernährungswoche */
  tripleGoalWeeks: number;

  // ——— Treppe ———
  /** Treppenaufstiege insgesamt */
  stairTotal: number;
  /** Aufstiege heute */
  stairToday: number;
  /** Tage mit mindestens einem Aufstieg */
  stairDays: number;
  /** meiste Aufstiege an einem Tag */
  stairBestDay: number;
  /** laufende Serie an Tagen mit mindestens einem Aufstieg */
  stairStreak: number;
  longestStairStreak: number;

  // ——— Cheat Days ———
  /** Gesetzte Cheat-Tage — je Woche zählt nur einer */
  cheatDates: Set<string>;
  /** Cheat Day der laufenden Woche — null, wenn noch keiner gesetzt ist */
  cheatThisWeek: string | null;
  /** Cheat-Tage insgesamt */
  cheatTotal: number;

  // ——— Pausenmodus ———
  /** Pause läuft: Streaks frieren ein, Einträge zählen trotzdem */
  pauseActive: boolean;
  /** Startdatum der laufenden Pause — null, wenn keine läuft */
  pausedSince: string | null;
}

/**
 * Folgt `date` lückenlos auf `prev`? Pausierte Tage dazwischen zählen nicht
 * als Lücke — eine Serie überlebt den Urlaub.
 */
function joins(prev: string | null, date: string, paused: Set<string>): boolean {
  if (!prev) return false;
  let d = addDays(prev, 1);
  while (d < date) {
    if (!paused.has(d)) return false;
    d = addDays(d, 1);
  }
  return d === date;
}

/** XP pro Tag einer Spur — der wievielte Tag der Serie zählt, nicht der Kalendertag. */
function laneXpByDate(
  dates: Set<string>,
  paused: Set<string>,
): { xp: Map<string, number>; longest: number } {
  const xp = new Map<string, number>();
  let longest = 0;
  let run = 0;
  let prev: string | null = null;
  for (const date of [...dates].sort()) {
    run = joins(prev, date, paused) ? run + 1 : 1;
    if (run > longest) longest = run;
    xp.set(date, xpForCleanDay(run));
    prev = date;
  }
  return { xp, longest };
}

/**
 * Serie rückwärts ab heute. Ein noch nicht abgehakter heutiger Tag bricht sie
 * nicht — und pausierte Tage ohne Eintrag werden übersprungen.
 */
function streakBack(dates: Set<string>, today: string, paused: Set<string>): number {
  let streak = 0;
  let cursor = dates.has(today) ? today : addDays(today, -1);
  for (;;) {
    if (dates.has(cursor)) streak++;
    else if (!paused.has(cursor)) break;
    cursor = addDays(cursor, -1);
  }
  return streak;
}

export function summarizeWeek(
  key: string,
  sessions: Session[],
  walks: Walk[] = [],
  clean: CleanDay[] = [],
  cleanXpByDate: Map<string, number> = new Map(),
  stairs: Stair[] = [],
): WeekSummary {
  const count = sessions.length;
  const has = (t: SessionType) => sessions.some((s) => s.type === t);
  // Vergebend: zwei Einheiten reichen. Die Kombinationen Bouldern+Home und
  // Home+Fallback sind der Normalfall, alles andere wird nicht bestraft.
  const fulfilled = count >= 2;
  // Pro Tag zählt ein Spaziergang. Zwei Geräte können denselben Tag eintragen —
  // beim Mergen bleiben beide erhalten, gewertet wird der Tag trotzdem einmal.
  const dates = new Set(walks.map((w) => w.date));
  const walkDays = [...dates].filter(isWeekday).length;

  const cleanSets: Record<CleanKind, Set<string>> = { snacks: new Set(), drinks: new Set() };
  for (const c of clean) cleanSets[c.kind].add(c.date);
  const cleanDays = { snacks: cleanSets.snacks.size, drinks: cleanSets.drinks.size };
  const cleanBothDays = [...cleanSets.snacks].filter((d) => cleanSets.drinks.has(d)).length;

  // Ernährungs-XP hängt an der Serie über Wochengrenzen hinweg und kommt
  // deshalb fertig berechnet von computeStats.
  const weekDates = new Set([...cleanSets.snacks, ...cleanSets.drinks]);
  let cleanXp = 0;
  for (const d of weekDates) cleanXp += cleanXpByDate.get(d) ?? 0;

  return {
    key,
    sessions,
    count,
    fulfilled,
    fallbackWeek: fulfilled && has('fallback') && !has('boulder'),
    walks,
    walkDays,
    walkPerfect: walkDays >= WALK_GOAL,
    clean,
    cleanDays,
    cleanBothDays,
    cleanPerfect: cleanBothDays >= CLEAN_GOAL,
    stairs,
    stairCount: stairs.length,
    xp:
      sessions.reduce((sum, s) => sum + xpFor(s), 0) +
      dates.size * XP_WALK +
      stairs.length * XP_STAIR +
      cleanXp,
  };
}

export function computeStats(
  sessions: Session[],
  walks: Walk[] = [],
  cleanDaysInput: CleanDay[] = [],
  stairs: Stair[] = [],
  pauseEvents: PauseEvent[] = [],
  cheatDays: CheatDay[] = [],
  now = new Date(),
): Stats {
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

  const cleanBuckets = new Map<string, CleanDay[]>();
  for (const c of cleanDaysInput) {
    const k = weekKeyOf(c.date);
    const arr = cleanBuckets.get(k);
    if (arr) arr.push(c);
    else cleanBuckets.set(k, [c]);
  }

  const stairBuckets = new Map<string, Stair[]>();
  for (const s of stairs) {
    const k = weekKeyOf(s.date);
    const arr = stairBuckets.get(k);
    if (arr) arr.push(s);
    else stairBuckets.set(k, [s]);
  }

  const today = toISODate(now);

  // ——— Pausenmodus: diese Tage brechen keine Serie ———
  const { paused, activeSince } = pauseInfo(pauseEvents, today);
  /** Eine Woche mit mindestens einem Pausentag bricht den Wochen-Streak nicht. */
  const weekPaused = (key: string) =>
    [0, 1, 2, 3, 4, 5, 6].some((i) => paused.has(addDays(key, i)));

  // ——— Cheat Days: übersprungen wie Pausentage, aber nur bei der Ernährung.
  // Training, Spaziergang und Treppe interessiert der Cheat Day nicht.
  const cheat = cheatInfo(cheatDays);
  const cleanSkip = new Set([...paused, ...cheat.dates]);

  // ——— Ernährung: erst die Serien, daraus die XP pro Tag ———
  const laneDates: Record<CleanKind, Set<string>> = { snacks: new Set(), drinks: new Set() };
  for (const c of cleanDaysInput) laneDates[c.kind].add(c.date);

  const bothDates = [...laneDates.snacks].filter((d) => laneDates.drinks.has(d)).sort();
  const bothSet = new Set(bothDates);

  /** XP je Kalendertag über beide Spuren inkl. Kombi-Bonus — für die Wochen-XP. */
  const cleanXpByDate = new Map<string, number>();
  const lanes = {} as Record<CleanKind, LaneStats>;
  let cleanXp = 0;

  for (const kind of CLEAN_KINDS) {
    const dates = laneDates[kind];
    const { xp: byDate, longest } = laneXpByDate(dates, cleanSkip);
    const currentStreak = streakBack(dates, today, cleanSkip);
    let laneXp = 0;
    for (const [date, value] of byDate) {
      laneXp += value;
      cleanXpByDate.set(date, (cleanXpByDate.get(date) ?? 0) + value);
    }
    cleanXp += laneXp;
    lanes[kind] = {
      kind,
      dates,
      total: dates.size,
      currentStreak,
      longestStreak: Math.max(longest, currentStreak),
      // Der nächste Tag setzt die Serie fort — also ein Schritt weiter.
      nextXp: xpForCleanDay(currentStreak + 1),
      xp: laneXp,
    };
  }

  for (const date of bothDates) {
    cleanXp += XP_CLEAN_COMBO;
    cleanXpByDate.set(date, (cleanXpByDate.get(date) ?? 0) + XP_CLEAN_COMBO);
  }

  const cleanBothStreak = streakBack(bothSet, today, cleanSkip);
  let longestCleanBothStreak = 0;
  // Serien ab einer Woche zählen; ab der zweiten ist jede ein Wiedereinstieg
  // nach einem Ausrutscher.
  let longRuns = 0;
  let bothRun = 0;
  let prevBoth: string | null = null;
  for (const date of bothDates) {
    bothRun = joins(prevBoth, date, cleanSkip) ? bothRun + 1 : 1;
    if (bothRun > longestCleanBothStreak) longestCleanBothStreak = bothRun;
    if (bothRun === CLEAN_GOAL) longRuns++;
    prevBoth = date;
  }
  longestCleanBothStreak = Math.max(longestCleanBothStreak, cleanBothStreak);
  const cleanComebacks = Math.max(0, longRuns - 1);

  const thisWeek = currentWeekKey(now);
  const keys = [
    ...buckets.keys(),
    ...walkBuckets.keys(),
    ...cleanBuckets.keys(),
    ...stairBuckets.keys(),
  ].sort();
  const first = keys[0] ?? thisWeek;
  const span = weeksBetween(first < thisWeek ? first : thisWeek, thisWeek);

  const weeks = new Map<string, WeekSummary>();
  const orderedWeeks: WeekSummary[] = [];
  for (const k of span) {
    const w = summarizeWeek(
      k,
      (buckets.get(k) ?? []).slice().sort((a, b) => a.ts - b.ts),
      (walkBuckets.get(k) ?? []).slice().sort((a, b) => a.ts - b.ts),
      (cleanBuckets.get(k) ?? []).slice().sort((a, b) => a.ts - b.ts),
      cleanXpByDate,
      (stairBuckets.get(k) ?? []).slice().sort((a, b) => a.ts - b.ts),
    );
    weeks.set(k, w);
    orderedWeeks.push(w);
  }

  // Aktueller Streak: die laufende Woche zählt nur, wenn sie schon erfüllt ist –
  // sie bricht den Streak aber niemals, solange sie noch läuft. Pausierte
  // Wochen werden übersprungen statt gewertet.
  let currentStreak = 0;
  let cursor = weeks.get(thisWeek)?.fulfilled ? thisWeek : addWeeks(thisWeek, -1);
  for (;;) {
    if (weeks.get(cursor)?.fulfilled) currentStreak++;
    else if (!weekPaused(cursor)) break;
    cursor = addWeeks(cursor, -1);
  }

  let longestStreak = 0;
  let run = 0;
  for (const w of orderedWeeks) {
    run = w.fulfilled ? run + 1 : weekPaused(w.key) ? run : 0;
    if (run > longestStreak) longestStreak = run;
  }

  const byType: Record<SessionType, number> = { boulder: 0, home: 0, fallback: 0 };
  let xp = cleanXp;
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

  // Serie über Werktage: das Wochenende unterbricht nicht, es zählt nur nicht
  // mit — pausierte Werktage genauso. Der heutige Tag bricht die Serie nicht,
  // solange er noch läuft.
  let walkStreak = 0;
  let cursorDay = walkDates.has(today) && isWeekday(today) ? today : prevWeekday(today);
  for (;;) {
    if (walkDates.has(cursorDay)) walkStreak++;
    else if (!paused.has(cursorDay)) break;
    cursorDay = prevWeekday(cursorDay);
  }

  /** Vorheriger Werktag, pausierte Tage ohne Spaziergang überspringen. */
  const prevWalkDay = (d: string) => {
    let x = prevWeekday(d);
    while (paused.has(x) && !walkDates.has(x)) x = prevWeekday(x);
    return x;
  };

  let longestWalkStreak = 0;
  const sortedWeekdays = weekdayWalks.slice().sort();
  let walkRun = 0;
  let prevDay: string | null = null;
  for (const day of sortedWeekdays) {
    walkRun = prevDay && prevWalkDay(day) === prevDay ? walkRun + 1 : 1;
    if (walkRun > longestWalkStreak) longestWalkStreak = walkRun;
    prevDay = day;
  }

  // ——— Treppe: jeder Aufstieg zählt, Serien laufen über Kalendertage ———
  const stairPerDay = new Map<string, number>();
  for (const s of stairs) stairPerDay.set(s.date, (stairPerDay.get(s.date) ?? 0) + 1);
  const stairDates = new Set(stairPerDay.keys());
  xp += stairs.length * XP_STAIR;

  const stairStreak = streakBack(stairDates, today, paused);
  let longestStairStreak = 0;
  let stairRun = 0;
  let prevStairDay: string | null = null;
  for (const day of [...stairDates].sort()) {
    stairRun = joins(prevStairDay, day, paused) ? stairRun + 1 : 1;
    if (stairRun > longestStairStreak) longestStairStreak = stairRun;
    prevStairDay = day;
  }
  longestStairStreak = Math.max(longestStairStreak, stairStreak);

  let bigWeeks = 0;
  let onPlanWeeks = 0;
  let comebacks = 0;
  let allMinWeeks = 0;
  let emptyRun = 0;
  let walkPerfectWeeks = 0;
  let walkSolidWeeks = 0;
  let doubleGoalWeeks = 0;
  let cleanPerfectWeeks = 0;
  let tripleGoalWeeks = 0;
  for (const w of orderedWeeks) {
    if (w.walkPerfect) walkPerfectWeeks++;
    if (w.walkDays >= 3) walkSolidWeeks++;
    if (w.fulfilled && w.walkPerfect) doubleGoalWeeks++;
    if (w.cleanPerfect) cleanPerfectWeeks++;
    if (w.fulfilled && w.walkPerfect && w.cleanPerfect) tripleGoalWeeks++;
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
    lanes,
    cleanBothDays: bothDates.length,
    cleanBothStreak,
    longestCleanBothStreak,
    cleanComebacks,
    cleanAnyDays: new Set([...laneDates.snacks, ...laneDates.drinks]).size,
    cleanXp,
    cleanPerfectWeeks,
    tripleGoalWeeks,
    stairTotal: stairs.length,
    stairToday: stairPerDay.get(today) ?? 0,
    stairDays: stairDates.size,
    stairBestDay: Math.max(0, ...stairPerDay.values()),
    stairStreak,
    longestStairStreak,
    cheatDates: cheat.dates,
    cheatThisWeek: cheat.byWeek.get(thisWeek) ?? null,
    cheatTotal: cheat.dates.size,
    pauseActive: activeSince !== null,
    pausedSince: activeSince,
  };
}
