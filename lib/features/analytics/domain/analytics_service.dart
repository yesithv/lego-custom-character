import 'entities/analytics_event.dart';
import 'entities/analytics_summary.dart';

/// Servicio de analítica **agnóstico del proveedor**.
///
/// La implementación actual ([LocalAnalyticsService]) guarda los eventos en
/// local (Hive), sin SDKs de terceros — requisito para la categoría Kids de
/// Apple. Para enviar los eventos a un backend propio, se añade un *sink*
/// remoto en la implementación (o se envuelve con un decorador) sin tocar la
/// instrumentación de las pantallas.
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
