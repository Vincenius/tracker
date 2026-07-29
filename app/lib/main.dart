import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'store.dart';
import 'theme.dart';
import 'views/badges_view.dart';
import 'views/history_view.dart';
import 'views/nutrition_view.dart';
import 'views/settings_sheet.dart';
import 'views/week_view.dart';
import 'widgets/celebration.dart';
import 'widgets/hold_icon.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TrackerApp());
}

class TrackerApp extends StatefulWidget {
  const TrackerApp({super.key});

  @override
  State<TrackerApp> createState() => _TrackerAppState();
}

class _TrackerAppState extends State<TrackerApp> {
  final _store = TrackerStore();

  @override
  void initState() {
    super.initState();
    _store.init();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomePage(store: _store),
    );
  }
}

const _syncLabel = {
  SyncState.idle: 'Verbinde …',
  SyncState.syncing: 'Synchronisiert …',
  SyncState.synced: 'Mit dem Server synchron',
  SyncState.offline: 'Offline — lokal gespeichert, wird später synchronisiert',
  SyncState.unauthorized: 'Server verlangt ein Token — Daten bleiben nur lokal',
};

const _syncColor = {
  SyncState.idle: C.rock500,
  SyncState.syncing: C.gradeYellow,
  SyncState.synced: C.gradeGreen,
  SyncState.offline: C.rock500,
  SyncState.unauthorized: C.gradeRed,
};

/// `short` steht in der Mobile-Leiste — vier Tabs brauchen dort kurze Wörter.
const _tabs = [
  (label: 'Diese Woche', short: 'Woche'),
  (label: 'Ernährung', short: 'Essen'),
  (label: 'Verlauf', short: 'Verlauf'),
  (label: 'Abzeichen', short: 'Abzeichen'),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store});

  final TrackerStore store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  String? _shownToast;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChange);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChange);
    super.dispose();
  }

  /// Feier und Toast leben außerhalb des Widget-Baums (Dialog bzw. SnackBar),
  /// deshalb werden sie hier aus dem Store heraus angestoßen.
  void _onStoreChange() {
    final store = widget.store;

    final celebration = store.celebration;
    if (celebration != null && !_celebrating) {
      _celebrating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showCelebration(context, celebration);
        _celebrating = false;
        store.dismissCelebration();
      });
    }

    final toast = store.toast;
    if (toast == null) {
      _shownToast = null;
    } else if (toast != _shownToast) {
      _shownToast = toast;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(toast, style: const TextStyle(color: C.chalk)),
              backgroundColor: C.rock800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: C.rock700),
              ),
              duration: const Duration(milliseconds: 3200),
            ),
          );
      });
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final wide = MediaQuery.of(context).size.width >= 640;

    return Scaffold(
      backgroundColor: C.rock950,
      body: Container(
        // Der Tape-Schimmer aus index.css — der Rauschfilter fällt weg.
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.1,
            colors: [Color(0x17E4572E), Color(0x00E4572E)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 672),
              child: Column(
                children: [
                  _Header(store: store),
                  if (wide) _TopNav(tab: _tab, onTap: (i) => setState(() => _tab = i)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        if (store.sync == SyncState.unauthorized) ...[
                          _TokenPrompt(store: store),
                          const SizedBox(height: 20),
                        ],
                        switch (_tab) {
                          0 => WeekView(store: store),
                          1 => NutritionView(store: store),
                          2 => HistoryView(store: store),
                          _ => BadgesView(store: store),
                        },
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          wide ? null : _BottomNav(tab: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.store});

  final TrackerStore store;

  @override
  Widget build(BuildContext context) {
    final stats = store.stats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          const HoldIcon(size: 28, filled: true, color: C.tape),
          const SizedBox(width: 12),
          Text('TRACKER', style: displaySize(24).copyWith(letterSpacing: 4.3)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: C.rock700),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Lvl ${stats.level} · ${stats.xp} XP',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: C.chalkDim,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: _syncLabel[store.sync]!,
            child: GestureDetector(
              // Tippen synchronisiert, langes Drücken öffnet Server & Token.
              onTap: () => store.pushAndPull(),
              onLongPress: () => showSettingsSheet(context, store),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: C.rock700),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _syncColor[store.sync],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Erscheint, wenn der Server den Sync mit 401 ablehnt.
class _TokenPrompt extends StatefulWidget {
  const _TokenPrompt({required this.store});

  final TrackerStore store;

  @override
  State<_TokenPrompt> createState() => _TokenPromptState();
}

class _TokenPromptState extends State<_TokenPrompt> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(String value) {
    if (value.trim().isEmpty) return;
    widget.store.saveToken(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.rock900,
        border: Border.all(color: C.gradeRed.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Zugriffstoken nötig',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Der Server lehnt dieses Gerät ab. Token einmal eintragen — danach '
            'synchronisiert es wieder und deine lokalen Daten werden hochgeladen.',
            style: TextStyle(fontSize: 12, color: C.chalkDim),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Token',
                    hintStyle: const TextStyle(color: C.chalkFaint, fontSize: 14),
                    isDense: true,
                    filled: true,
                    fillColor: C.rock950,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: C.rock700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: C.rock500),
                    ),
                  ),
                  onSubmitted: _save,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _save(_controller.text),
                style: FilledButton.styleFrom(
                  backgroundColor: C.tape,
                  foregroundColor: C.rock950,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Speichern',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showSettingsSheet(context, widget.store),
              style: TextButton.styleFrom(
                foregroundColor: C.chalkFaint,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Falsche Serveradresse? Hier ändern.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({required this.tab, required this.onTap});

  final int tab;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: C.rock800),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: tab == i ? C.rock800 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _tabs[i].label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tab == i ? C.chalk : C.chalkDim,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.tab, required this.onTap});

  final int tab;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: C.rock950,
        border: Border(top: BorderSide(color: C.rock800)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 2,
                          decoration: BoxDecoration(
                            color: tab == i ? C.tape : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tabs[i].short,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tab == i ? C.chalk : C.chalkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
