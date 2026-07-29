import 'package:flutter/material.dart';

import '../theme.dart';
import 'types.dart';

class Exercise {
  const Exercise({required this.id, required this.name, required this.detail, this.timer});

  final String id;
  final String name;
  final String detail;

  /// Sekunden – aktiviert den Timer-Button
  final int? timer;
}

class WorkoutVariant {
  const WorkoutVariant({
    required this.label,
    required this.duration,
    required this.rounds,
    required this.exercises,
  });

  final String label;
  final String duration;
  final int rounds;
  final List<Exercise> exercises;
}

const _pushups = Exercise(id: 'pushups', name: 'Liegestütze', detail: '8–12 Wdh.');
const _squats = Exercise(
  id: 'squats',
  name: 'Kniebeugen oder Ausfallschritte',
  detail: '12–15 Wdh.',
);
const _pike = Exercise(
  id: 'pike',
  name: 'Pike-Liegestütze oder Wand-Schulterdrücken',
  detail: '8–10 Wdh.',
);
const _plank = Exercise(id: 'plank', name: 'Plank', detail: '30–45 Sek.', timer: 45);
const _glute = Exercise(id: 'glute', name: 'Glute Bridge', detail: '12–15 Wdh.');
const _pullups = Exercise(
  id: 'pullups',
  name: 'Klimmzüge',
  detail: '3–5 Wdh. — oder negative Klimmzüge / Australian Pull-ups 5–8',
);

const workouts = <SessionType, Map<Intensity, WorkoutVariant>>{
  SessionType.boulder: {
    Intensity.full: WorkoutVariant(
      label: 'Session in der Halle',
      duration: 'nach Lust & Laune',
      rounds: 1,
      exercises: [
        Exercise(
          id: 'warmup',
          name: 'Aufwärmen',
          detail: 'leichte Boulder, Schultern & Finger lösen',
        ),
        Exercise(
          id: 'projects',
          name: 'Boulder klettern',
          detail: 'Grenzbereich antasten, Spaß zuerst',
        ),
        Exercise(id: 'cooldown', name: 'Ausklang', detail: 'Unterarme & Hüfte dehnen'),
      ],
    ),
    Intensity.min: WorkoutVariant(
      label: 'Session in der Halle',
      duration: 'kurz & knackig',
      rounds: 1,
      exercises: [
        Exercise(id: 'warmup', name: 'Aufwärmen', detail: 'leichte Boulder'),
        Exercise(
          id: 'projects',
          name: 'Boulder klettern',
          detail: 'ein paar Züge sind auch Züge',
        ),
      ],
    ),
  },
  SessionType.home: {
    Intensity.full: WorkoutVariant(
      label: 'Volle Einheit',
      duration: '~15 Min.',
      rounds: 2,
      exercises: [_pushups, _squats, _pike, _plank, _glute],
    ),
    Intensity.min: WorkoutVariant(
      label: 'Minimum',
      duration: '~5 Min.',
      rounds: 1,
      exercises: [_pushups, _squats, _plank],
    ),
  },
  SessionType.fallback: {
    Intensity.full: WorkoutVariant(
      label: 'Volle Einheit',
      duration: '~15 Min.',
      rounds: 2,
      exercises: [_pullups, _pushups, _squats, _pike, _plank, _glute],
    ),
    Intensity.min: WorkoutVariant(
      label: 'Minimum',
      duration: '~5 Min.',
      rounds: 1,
      exercises: [_pullups, _squats, _plank],
    ),
  },
};

class SessionMeta {
  const SessionMeta({
    required this.type,
    required this.title,
    required this.weekday,
    required this.tagline,
    required this.color,
    required this.hint,
  });

  final SessionType type;
  final String title;
  final String weekday;
  final String tagline;
  final Color color;
  final String hint;
}

const sessionMeta = <SessionType, SessionMeta>{
  SessionType.home: SessionMeta(
    type: SessionType.home,
    title: 'Home-Workout',
    weekday: 'Montag',
    tagline: 'Zwei Runden, Körpergewicht, fertig.',
    color: C.gradeBlue,
    hint: 'Auch das Minimum zählt voll.',
  ),
  SessionType.boulder: SessionMeta(
    type: SessionType.boulder,
    title: 'Bouldern',
    weekday: 'Mittwoch',
    tagline: 'Halle. Griffe. Chalk.',
    color: C.gradeYellow,
    hint: 'Wenn es nicht klappt: Fallback-Einheit zu Hause.',
  ),
  SessionType.fallback: SessionMeta(
    type: SessionType.fallback,
    title: 'Fallback-Einheit',
    weekday: 'flexibel',
    tagline: 'Zweite Home-Einheit mit Klimmzügen.',
    color: C.gradePurple,
    hint: 'Ersetzt das Bouldern in dieser Woche.',
  ),
};
