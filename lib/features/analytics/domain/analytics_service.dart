import 'entities/analytics_event.dart';
import 'entities/analytics_summary.dart';

/// Servicio de analítica **agnóstico del proveedor**.
///
/// La implementación del MVP v1 ([LocalAnalyticsService]) guarda los eventos
/// **solo en el dispositivo** (Hive), sin SDKs de terceros y sin red: es lo que
/// permite declarar en Google Play que la app no recoge ni comparte datos, y
/// cumple la categoría Kids de Apple. Sirve para QA e instrumentación, no para
/// métricas de negocio agregadas.
abstract class AnalyticsService {
  /// Marca el arranque de la app: inicia sesión, fija el primer uso y registra
  /// el día activo. No lanza excepciones.
  void startSession();

  /// Registra un evento del funnel (dispara y olvida; nunca lanza).
  void track(String event, {Map<String, Object?>? params});

  /// Resumen agregado (por dispositivo) para el panel de depuración.
  Future<AnalyticsSummary> getSummary();

  /// Últimos [limit] eventos, del más reciente al más antiguo.
  Future<List<AnalyticsEvent>> recentEvents({int limit = 50});

  /// Borra todos los datos de analítica locales (herramienta de QA).
  Future<void> clear();
}
