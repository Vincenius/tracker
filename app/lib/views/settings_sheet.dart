import 'package:flutter/material.dart';

import '../core/config.dart';
import '../store.dart';
import '../theme.dart';

/// Serveradresse und — falls der Server eins verlangt — das Zugriffstoken.
///
/// Die App braucht *kein* Token: läuft der Server ohne `TRACKER_TOKEN`, bleibt
/// das Feld leer und alles funktioniert. Erst wenn der Server 401 antwortet,
/// zeigt die Wochenansicht den Hinweis und hier lässt sich das Token nachtragen.
Future<void> showSettingsSheet(BuildContext context, TrackerStore store) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: C.rock900,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SettingsSheet(store: store),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.store});

  final TrackerStore store;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final _url = TextEditingController(text: Config.baseUrl);
  late final _token = TextEditingController(text: Config.token);

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SERVER & TOKEN', style: displaySize(20)),
          const SizedBox(height: 4),
          const Text(
            'Die App synchronisiert gegen dasselbe Backend wie die Web-App. '
            'Ein Token braucht sie nur, wenn der Server TRACKER_TOKEN gesetzt hat.',
            style: TextStyle(fontSize: 14, color: C.chalkDim),
          ),
          const SizedBox(height: 20),
          _Field(
            controller: _url,
            label: 'Serveradresse',
            hint: 'http://192.168.1.20:3025',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _token,
            label: 'Token (optional)',
            hint: 'leer lassen, wenn der Server offen ist',
            obscure: true,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await Config.setBaseUrl(_url.text);
              await Config.setToken(_token.text);
              navigator.pop();
              await widget.store.pushAndPull();
            },
            style: FilledButton.styleFrom(
              backgroundColor: C.tape,
              foregroundColor: C.rock950,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Speichern & synchronisieren',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(fontSize: 14, color: C.chalk),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: C.chalkFaint, fontSize: 13),
            filled: true,
            fillColor: C.rock950,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: C.rock700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: C.rock500),
            ),
          ),
        ),
      ],
    );
  }
}
