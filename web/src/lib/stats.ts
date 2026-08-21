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
  PauseEvent,
  Session,
  SessionType,
  Stair,
  Treat,
  TreatKind,
  Walk,
} from './types';
import { TREAT_KINDS, WALK_GOAL, XP_PER_LEVEL, XP_STAIR, XP_TREAT, XP_WALK, xpFor } from './types';
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
  kind: TreatKind;
  /** Einträge je Tag */
  perDay: Map<string, number>;
  /** Einträge insgesamt */
  total: number;
  /** Einträge heute */
  today: number;
  /** Tage mit mindestens einem Eintrag */
  days: number;
  /** meiste Einträge an einem Tag */
  worstDay: number;
  /** laufende Serie an Tagen ohne Eintrag in dieser Spur */
  cleanStreak: number;
  longestCleanStreak: number;
  /** XP, die diese Spur gekostet hat */
  xpLost: number;
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
  treats: Treat[];
  /** Einträge dieser Woche, je Spur */
  treatsByKind: Record<TreatKind, number>;
  /** Einträge dieser Woche insgesamt */
  treatCount: number;
  /** Tage dieser Woche mit mindestens einem Eintrag */
  treatDays: number;
  /** vergangene Tage dieser Woche ganz ohne Eintrag */
  cleanDays: number;
  /** die ganze Woche ohne einen einzigen Eintrag */
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

  // ——— Ernährung: gezählt wird, was danebenging ———
  lanes: Record<TreatKind, LaneStats>;
  /** Einträge insgesamt (beide Spuren) */
  treatTotal: number;
  /** Einträge heute */
  treatToday: number;
  /** Tage mit mindestens einem Eintrag */
  treatDays: number;
  /** meiste Einträge an einem Tag */
  treatWorstDay: number;
  /** XP, die die Ernährung insgesamt gekostet hat */
  treatXpLost: number;
  /** laufende Serie an Tagen ganz ohne Eintrag */
  cleanStreak: number;
  longestCleanStreak: number;
  /** getrackte Tage ganz ohne Eintrag */
  cleanDayTotal: number;
  /** Serien von 7 sauberen Tagen nach einem Ausrutscher */
  cleanComebacks: number;
  /** Wochen ganz ohne Eintrag */
  cleanPerfectWeeks: number;
  /** Wochen mit Trainingsziel, allen Spaziergängen und ohne einen Ausrutscher */
  tripleGoalWeeks: number;
  /** Erster Tag mit irgendeinem Eintrag — davor wird nichts gewertet */
  trackedSince: string | null;

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

export interface CleanScan {
  /** Alle sauberen Tage — getrackt, nicht pausiert, ohne Eintrag */
  dates: Set<string>;
  /** Laufende Serie bis heute */
  current: number;
  longest: number;
  /** Wie oft eine Serie die 7 Tage erreicht hat */
  sevens: number;
}

/**
 * Sauber ist ein Tag, an dem *nichts* eingetragen wurde — die Serie ergibt
 * sich also aus dem Ausbleiben von Einträgen. Damit das nicht rückwirkend bis
 * zum Urknall gilt, zählt erst ab dem ersten getrackten Tag. Pausierte Tage
 * werden übersprungen: sie zählen nicht mit, brechen aber auch nichts.
 */
function cleanScan(
  treatDates: Set<string>,
  from: string | null,
  today: string,
  paused: Set<string>,
): CleanScan {
  const dates = new Set<string>();
  let current = 0;
  let longest = 0;
  let sevens = 0;
  if (!from || from > today) return { dates, current, longest, sevens };
  let guard = 0;
  for (let d = from; d <= today && guard++ < 20000; d = addDays(d, 1)) {
    if (paused.has(d)) continue;
    if (treatDates.has(d)) {
      current = 0;
      continue;
    }
    dates.add(d);
    current++;
    if (current > longest) longest = current;
    if (current === CLEAN_GOAL) sevens++;
  }
  return { dates, current, longest, sevens };
}

export function summarizeWeek(
  key: string,
  sessions: Session[],
  walks: Walk[] = [],
  treats: Treat[] = [],
  stairs: Stair[] = [],
  cleanDates: Set<string> = new Set(),
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

  const treatsByKind: Record<TreatKind, number> = { sweets: 0, drinks: 0 };
  for (const t of treats) treatsByKind[t.kind]++;
  const weekDays = [0, 1, 2, 3, 4, 5, 6].map((i) => addDays(key, i));
  // Saubere Tage kommen fertig gerechnet von computeStats: ob ein Tag zählt,
  // hängt am Trackingstart, am heutigen Datum und am Pausenmodus.
  const cleanDays = weekDays.filter((d) => cleanDates.has(d)).length;

  return {
    key,
    sessions,
    count,
    fulfilled,
    fallbackWeek: fulfilled && has('fallback') && !has('boulder'),
    walks,
    walkDays,
    walkPerfect: walkDays >= WALK_GOAL,
    treats,
    treatsByKind,
    treatCount: treats.length,
    treatDays: new Set(treats.map((t) => t.date)).size,
    cleanDays,
    cleanPerfect: cleanDays >= CLEAN_GOAL,
    stairs,
    stairCount: stairs.length,
    xp:
      sessions.reduce((sum, s) => sum + xpFor(s), 0) +
      dates.size * XP_WALK +
      stairs.length * XP_STAIR -
      treats.length * XP_TREAT,
  };
}

export function computeStats(
  sessions: Session[],
  walks: Walk[] = [],
  treatsInput: Treat[] = [],
  stairs: Stair[] = [],
  pauseEvents: PauseEvent[] = [],
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

  const treatBuckets = new Map<string, Treat[]>();
  for (const t of treatsInput) {
    const k = weekKeyOf(t.date);
    const arr = treatBuckets.get(k);
    if (arr) arr.push(t);
    else treatBuckets.set(k, [t]);
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

  // Der erste Tag, an dem überhaupt etwas eingetragen wurde. Vorher gibt es
  // keine sauberen Tage — sonst wäre jede frisch installierte App im Rekord.
  let trackedSince: string | null = null;
  for (const date of [
    ...sessions.map((s) => s.date),
    ...walks.map((w) => w.date),
    ...treatsInput.map((t) => t.date),
    ...stairs.map((s) => s.date),
  ]) {
    if (!trackedSince || date < trackedSince) trackedSince = date;
  }

  // ——— Ernährung: gezählt wird, was danebenging ———
  const lanePerDay: Record<TreatKind, Map<string, number>> = {
    sweets: new Map(),
    drinks: new Map(),
  };
  const treatPerDay = new Map<string, number>();
  for (const t of treatsInput) {
    const lane = lanePerDay[t.kind];
    lane.set(t.date, (lane.get(t.date) ?? 0) + 1);
    treatPerDay.set(t.date, (treatPerDay.get(t.date) ?? 0) + 1);
  }

  const lanes = {} as Record<TreatKind, LaneStats>;
  for (const kind of TREAT_KINDS) {
    const perDay = lanePerDay[kind];
    const scan = cleanScan(new Set(perDay.keys()), trackedSince, today, paused);
    let total = 0;
    let worstDay = 0;
    for (const n of perDay.values()) {
      total += n;
      if (n > worstDay) worstDay = n;
    }
    lanes[kind] = {
      kind,
      perDay,
      total,
      today: perDay.get(today) ?? 0,
      days: perDay.size,
      worstDay,
      cleanStreak: scan.current,
      longestCleanStreak: scan.longest,
      xpLost: total * XP_TREAT,
    };
  }

  const clean = cleanScan(new Set(treatPerDay.keys()), trackedSince, today, paused);
  // Die erste 7er-Serie ist der Normalfall; jede weitere folgt auf einen
  // Ausrutscher — genau das ist der Wiedereinstieg.
  const cleanComebacks = Math.max(0, clean.sevens - 1);
  const treatXpLost = treatsInput.length * XP_TREAT;

  const thisWeek = currentWeekKey(now);
  const keys = [
    ...buckets.keys(),
    ...walkBuckets.keys(),
    ...treatBuckets.keys(),
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
      (treatBuckets.get(k) ?? []).slice().sort((a, b) => a.ts - b.ts),
      (stairBuckets.get(k) ?? []).slice().sort((a, b) => a.ts - b.ts),
      clean.dates,
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
  let earned = 0;
  let earlyBird = 0;
  let nightOwl = 0;
  let weekendSessions = 0;
  let minSessions = 0;
  let fullChecklists = 0;
  for (const s of sessions) {
    byType[s.type]++;
    earned += xpFor(s);
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
  earned += walkDates.size * XP_WALK;
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
  earned += stairs.length * XP_STAIR;

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

  // Unter null geht es nicht: ein schlechter Monat kostet Fortschritt, aber
  // niemals das Konto.
  const xp = Math.max(0, earned - treatXpLost);
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
    treatTotal: treatsInput.length,
    treatToday: treatPerDay.get(today) ?? 0,
    treatDays: treatPerDay.size,
    treatWorstDay: Math.max(0, ...treatPerDay.values()),
    treatXpLost,
    cleanStreak: clean.current,
    longestCleanStreak: clean.longest,
    cleanDayTotal: clean.dates.size,
    cleanComebacks,
    cleanPerfectWeeks,
    tripleGoalWeeks,
    trackedSince,
    stairTotal: stairs.length,
    stairToday: stairPerDay.get(today) ?? 0,
    stairDays: stairDates.size,
    stairBestDay: Math.max(0, ...stairPerDay.values()),
    stairStreak,
    longestStairStreak,
    pauseActive: activeSince !== null,
    pausedSince: activeSince,
  };
}
