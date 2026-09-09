import 'package:hive/hive.dart';

import '../models/analytics_event_model.dart';

/// Acceso local a la analítica: un log de eventos (append-only) y una caja de
/// metadatos (primer uso, sesiones, días activos).
abstract class AnalyticsLocalDatasource {
  /// Añade un evento al log, **acotando** su tamaño (ver
  /// [AnalyticsLocalDatasourceImpl.maxEvents]).
  Future<void> append(AnalyticsEventModel event);

  /// Los eventos guardados, del más antiguo al más reciente.
  List<AnalyticsEventModel> events();

  int? get firstOpenMs;
  Future<void> setFirstOpenMs(int ms);

  int get sessions;
  Future<void> setSessions(int value);

  List<String> get activeDays;
  Future<void> setActiveDays(List<String> days);

  Future<void> clear();
}

class AnalyticsLocalDatasourceImpl implements AnalyticsLocalDatasource {
  final Box<AnalyticsEventModel> _events;
  final Box<dynamic> _meta;

  AnalyticsLocalDatasourceImpl({
    required Box<AnalyticsEventModel> events,
    required Box<dynamic> meta,
  })  : _events = events,
        _meta = meta;

  static const _kFirstOpen = 'firstOpenMs';
  static const _kSessions = 'sessions';
  static const _kActiveDays = 'activeDays';

  /// Tope de eventos guardados.
  ///
  /// El log es append-only y antes crecía **sin límite**: cada carrera, cada
  /// apertura de tienda y cada tirada de ruleta dejaban una fila para siempre.
  /// Y la caja se deserializa entera al abrir la app, así que a los meses de
  /// juego el arranque tenía que leer miles de eventos: la app se volvía más
  /// lenta de arrancar cuanto más se jugaba.
  ///
  /// 500 eventos cubren de sobra para lo que sirve esto —QA e instrumentación
  /// del dispositivo, no métricas de negocio—, y los agregados que de verdad
  /// importan (sesiones, primer uso, días activos) viven en la caja de
  /// metadatos y no se tocan al podar. Mismo criterio que
  /// `ScoreLocalRepository`, que ya acota su caja.
  static const int maxEvents = 500;

  /// Cuántos eventos de margen se dejan acumular por encima de [maxEvents]
  /// antes de recortar. Podar en bloque hace que el borrado ocurra una vez
  /// cada [_pruneMargin] eventos en vez de en cada escritura.
  static const int _pruneMargin = 100;

  @override
  Future<void> append(AnalyticsEventModel event) async {
    await _events.add(event);
    if (_events.length <= maxEvents + _pruneMargin) return;
    // Las claves de una caja append-only son autoincrementales, así que el
    // orden de `keys` es el de llegada: los primeros son los más antiguos.
    final excess = _events.length - maxEvents;
    await _events.deleteAll(_events.keys.take(excess).toList());
  }

  @override
  List<AnalyticsEventModel> events() => _events.values.toList();

  @override
  int? get firstOpenMs => _meta.get(_kFirstOpen) as int?;

  @override
  Future<void> setFirstOpenMs(int ms) => _meta.put(_kFirstOpen, ms);

  @override
  int get sessions => (_meta.get(_kSessions) as int?) ?? 0;

  @override
  Future<void> setSessions(int value) => _meta.put(_kSessions, value);

  @override
  List<String> get activeDays =>
      ((_meta.get(_kActiveDays) as List?)?.cast<String>()) ?? const [];

  @override
  Future<void> setActiveDays(List<String> days) =>
      _meta.put(_kActiveDays, days);

  @override
  Future<void> clear() async {
    await _events.clear();
    await _meta.clear();
  }
}
