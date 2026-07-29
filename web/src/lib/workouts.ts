import type { Intensity, SessionType } from './types';

export interface Exercise {
  id: string;
  name: string;
  detail: string;
  /** Sekunden – aktiviert den Timer-Button */
  timer?: number;
}

export interface WorkoutVariant {
  label: string;
  duration: string;
  rounds: number;
  exercises: Exercise[];
}

const PUSHUPS: Exercise = { id: 'pushups', name: 'Liegestütze', detail: '8–12 Wdh.' };
const SQUATS: Exercise = {
  id: 'squats',
  name: 'Kniebeugen oder Ausfallschritte',
  detail: '12–15 Wdh.',
};
const PIKE: Exercise = {
  id: 'pike',
  name: 'Pike-Liegestütze oder Wand-Schulterdrücken',
  detail: '8–10 Wdh.',
};
const PLANK: Exercise = { id: 'plank', name: 'Plank', detail: '30–45 Sek.', timer: 45 };
const GLUTE: Exercise = { id: 'glute', name: 'Glute Bridge', detail: '12–15 Wdh.' };
const PULLUPS: Exercise = {
  id: 'pullups',
  name: 'Klimmzüge',
  detail: '3–5 Wdh. — oder negative Klimmzüge / Australian Pull-ups 5–8',
};

export const WORKOUTS: Record<SessionType, Record<Intensity, WorkoutVariant>> = {
  boulder: {
    full: {
      label: 'Session in der Halle',
      duration: 'nach Lust & Laune',
      rounds: 1,
      exercises: [
        { id: 'warmup', name: 'Aufwärmen', detail: 'leichte Boulder, Schultern & Finger lösen' },
        { id: 'projects', name: 'Boulder klettern', detail: 'Grenzbereich antasten, Spaß zuerst' },
        { id: 'cooldown', name: 'Ausklang', detail: 'Unterarme & Hüfte dehnen' },
      ],
    },
    min: {
      label: 'Session in der Halle',
      duration: 'kurz & knackig',
      rounds: 1,
      exercises: [
        { id: 'warmup', name: 'Aufwärmen', detail: 'leichte Boulder' },
        { id: 'projects', name: 'Boulder klettern', detail: 'ein paar Züge sind auch Züge' },
      ],
    },
  },
  home: {
    full: {
      label: 'Volle Einheit',
      duration: '~15 Min.',
      rounds: 2,
      exercises: [PUSHUPS, SQUATS, PIKE, PLANK, GLUTE],
    },
    min: {
      label: 'Minimum',
      duration: '~5 Min.',
      rounds: 1,
      exercises: [PUSHUPS, SQUATS, PLANK],
    },
  },
  fallback: {
    full: {
      label: 'Volle Einheit',
      duration: '~15 Min.',
      rounds: 2,
      exercises: [PULLUPS, PUSHUPS, SQUATS, PIKE, PLANK, GLUTE],
    },
    min: {
      label: 'Minimum',
      duration: '~5 Min.',
      rounds: 1,
      exercises: [PULLUPS, SQUATS, PLANK],
    },
  },
};

export interface SessionMeta {
  type: SessionType;
  title: string;
  weekday: string;
  /** 0 = Montag */
  weekdayIndex: number;
  tagline: string;
  color: string;
  hint: string;
}

export const SESSION_META: Record<SessionType, SessionMeta> = {
  home: {
    type: 'home',
    title: 'Home-Workout',
    weekday: 'Montag',
    weekdayIndex: 0,
    tagline: 'Zwei Runden, Körpergewicht, fertig.',
    color: 'var(--color-grade-blue)',
    hint: 'Auch das Minimum zählt voll.',
  },
  boulder: {
    type: 'boulder',
    title: 'Bouldern',
    weekday: 'Mittwoch',
    weekdayIndex: 2,
    tagline: 'Halle. Griffe. Chalk.',
    color: 'var(--color-grade-yellow)',
    hint: 'Wenn es nicht klappt: Fallback-Einheit zu Hause.',
  },
  fallback: {
    type: 'fallback',
    title: 'Fallback-Einheit',
    weekday: 'flexibel',
    weekdayIndex: 4,
    tagline: 'Zweite Home-Einheit mit Klimmzügen.',
    color: 'var(--color-grade-purple)',
    hint: 'Ersetzt das Bouldern in dieser Woche.',
  },
};
