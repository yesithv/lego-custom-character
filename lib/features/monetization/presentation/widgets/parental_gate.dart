import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Compuerta parental.
///
/// **Obligatoria** antes de cualquier compra o enlace externo en un producto
/// para niños (requisito de App Store Kids y Google Play Designed for Families).
/// Plantea una operación simple que un adulto resuelve y un niño pequeño no.
///
/// Uso:
/// ```dart
/// if (await ParentalGate.show(context)) { /* continuar con la compra */ }
/// ```
class ParentalGate {
  const ParentalGate._();

  /// Muestra la compuerta y resuelve `true` si se supera, `false` si se
  /// cancela.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ParentalGateDialog(),
    );
    return result ?? false;
  }
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  final _rng = Random();
  late int _a;
  late int _b;
  late List<int> _options;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    _a = 3 + _rng.nextInt(7); // 3..9
    _b = 3 + _rng.nextInt(7); // 3..9
    final correct = _a * _b;
    final options = <int>{correct};
    while (options.length < 3) {
      final delta = _rng.nextInt(9) - 4; // -4..4
      final candidate = correct + (delta == 0 ? 5 : delta);
      if (candidate > 0) options.add(candidate);
    }
    _options = options.toList()..shuffle(_rng);
  }

  void _answer(int value) {
    if (value == _a * _b) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _wrong = true;
        _generate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text(context.l10n.tr('parental_title'))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.tr('parental_prompt'),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Text(
            '$_a × $_b = ?',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _options
                .map((o) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _answer(o),
                      child: Text(
                        '$o',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ))
                .toList(),
          ),
          if (_wrong) ...[
            const SizedBox(height: 12),
            Text(
              context.l10n.tr('parental_wrong'),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.tr('cancel')),
        ),
      ],
    );
  }
}
