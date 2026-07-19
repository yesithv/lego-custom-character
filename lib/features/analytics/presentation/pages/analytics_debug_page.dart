import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../domain/analytics_service.dart';
import '../../domain/entities/analytics_event.dart';
import '../../domain/entities/analytics_summary.dart';

/// Panel de depuración de la analítica (herramienta interna).
///
/// Muestra el resumen del funnel y los últimos eventos de **este dispositivo**.
/// Accesible desde la hoja del modo de prueba.
class AnalyticsDebugPage extends StatefulWidget {
  const AnalyticsDebugPage({super.key});

  @override
  State<AnalyticsDebugPage> createState() => _AnalyticsDebugPageState();
}

class _AnalyticsDebugPageState extends State<AnalyticsDebugPage> {
  final AnalyticsService _analytics = sl<AnalyticsService>();
  late Future<(AnalyticsSummary, List<AnalyticsEvent>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(AnalyticsSummary, List<AnalyticsEvent>)> _load() async {
    final summary = await _analytics.getSummary();
    final events = await _analytics.recentEvents(limit: 60);
    return (summary, events);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _clear() async {
    await _analytics.clear();
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Text('📊 Analítica (local)',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
          ),
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Borrar datos',
          ),
        ],
      ),
      body: FutureBuilder<(AnalyticsSummary, List<AnalyticsEvent>)>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white54));
          }
          final (summary, events) = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _Note(),
              const SizedBox(height: 12),
              _SummaryCard(summary: summary),
              const SizedBox(height: 16),
              const Text(
                'Eventos recientes',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
              const SizedBox(height: 8),
              if (events.isEmpty)
                const Text('Sin eventos todavía.',
                    style: TextStyle(color: Colors.white54, fontSize: 13))
              else
                ...events.map((e) => _EventRow(event: e)),
            ],
          );
        },
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB388FF), width: 1),
      ),
      child: const Text(
        'Datos solo de este dispositivo (first-party). Para métricas agregadas '
        'de negocio se enviarán a un backend propio.',
        style: TextStyle(color: Colors.white, fontSize: 11.5),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AnalyticsSummary summary;
  const _SummaryCard({required this.summary});

  static String _pct(double? v) => v == null ? '—' : '${(v * 100).round()}%';
  static String _date(DateTime? d) =>
      d == null ? '—' : '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Metric(label: 'Sesiones', value: '${summary.sessions}'),
              _Metric(label: 'Eventos', value: '${summary.totalEvents}'),
              _Metric(label: 'Días activos', value: '${summary.activeDays}'),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            children: [
              _Metric(label: 'Carreras', value: '${summary.runs}'),
              _Metric(label: 'Victorias', value: '${summary.victories}'),
              _Metric(
                  label: 'Tasa victoria',
                  value: _pct(summary.victoryRate)),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            children: [
              _Metric(label: 'Tienda', value: '${summary.storeOpens}'),
              _Metric(label: 'Compras', value: '${summary.purchases}'),
              _Metric(
                  label: 'Conversión',
                  value: _pct(summary.purchaseConversion)),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            children: [
              _Metric(label: 'D1', value: summary.retainedD1 ? '✓' : '—'),
              _Metric(label: 'D7', value: summary.retainedD7 ? '✓' : '—'),
              _Metric(label: '1er uso', value: _date(summary.firstOpen)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w900,
                fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final AnalyticsEvent event;
  const _EventRow({required this.event});

  String get _time {
    final t = event.timestamp;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                if (event.params.isNotEmpty)
                  Text(
                    event.params.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(_time,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
