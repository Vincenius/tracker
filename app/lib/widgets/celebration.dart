import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import 'card.dart';
import 'confetti.dart';
import 'hold_icon.dart';

/// Portierung von web/src/components/Celebration.tsx als Dialog.
Future<void> showCelebration(BuildContext context, Celebration data) {
  return showDialog<void>(
    context: context,
    barrierColor: C.rock950.withValues(alpha: 0.85),
    builder: (context) => _CelebrationDialog(data: data),
  );
}

class _CelebrationDialog extends StatefulWidget {
  const _CelebrationDialog({required this.data});

  final Celebration data;

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> {
  @override
  void initState() {
    super.initState();
    // Aus dem Dialog heraus gestartet liegt das Konfetti über dem Barrier —
    // darunter würde der abgedunkelte Hintergrund es schlucken.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Fliegt schon Papier — etwa von der gerade abgehakten Einheit —, bleibt
      // es dabei: drei Salven übereinander verdecken nur den Text.
      if (data.level != null) {
        cheerConfetti(context);
      } else if (!confettiActive()) {
        burstConfetti(
          context,
          colors: [for (final b in data.badges) b.color],
          count: 70,
        );
      }
    });
  }

  Celebration get data => widget.data;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: C.rock900,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: C.rock700),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 384),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.level != null) ...[
                const Text(
                  'LEVEL UP',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 3.6,
                    fontWeight: FontWeight.w600,
                    color: C.tape,
                  ),
                ),
                Bump(
                  value: data.level!,
                  child: Text('${data.level}', style: displaySize(64)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ein Level weiter oben. Der nächste Griff wartet schon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: C.chalkDim),
                ),
              ],
              if (data.badges.isNotEmpty) ...[
                if (data.level != null) ...[
                  const SizedBox(height: 24),
                  const Divider(color: C.rock800, height: 1),
                  const SizedBox(height: 20),
                ],
                Text(
                  data.badges.length > 1 ? 'NEUE ABZEICHEN' : 'NEUES ABZEICHEN',
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 3.6,
                    fontWeight: FontWeight.w600,
                    color: C.chalkFaint,
                  ),
                ),
                const SizedBox(height: 12),
                for (final b in data.badges)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Bump(
                          value: b.id,
                          child: HoldIcon(size: 40, filled: true, color: b.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.name.toUpperCase(), style: displaySize(18)),
                              const SizedBox(height: 2),
                              Text(
                                b.desc,
                                style: const TextStyle(fontSize: 14, color: C.chalkDim),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: C.chalk,
                    foregroundColor: C.rock950,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Weiter',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
