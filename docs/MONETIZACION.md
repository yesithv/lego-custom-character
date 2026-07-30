# Monetización

Estado: **pagos reales cableados (MVP v1)**. En móvil la Tienda cobra con
**Google Play Billing / StoreKit** (`in_app_purchase`); en la demo web sigue con
compras **simuladas** porque el plugin no tiene implementación para web. El
cambio es automático por plataforma en `core/di/injection.dart`.

Falta un paso que **no es código**: dar de alta los productos en Google Play
Console con los mismos IDs del catálogo.

## Producto para niños — reglas que condicionan todo

- **Decisión de producto: SIN anuncios en ninguna plataforma.** Máxima confianza
  de los padres y sin la complejidad de cumplimiento de ads. Se monetiza solo con
  **IAP (cosméticos) + gemas + suscripción VIP**. (Apple Kids prohíbe ads/analítica
  de terceros de todas formas; por eso la analítica es first-party.)
- **Toda compra pasa por [`ParentalGate`]** (compuerta parental). Obligatorio.
- Nada de pago-para-ganar ni cajas de botín con dinero real. Solo cosmético o
  conveniencia, a precio transparente.

## Arquitectura (feature `monetization`)

Sigue el mismo patrón desacoplado que `ScoreRepository`:

```
domain/
  entities/store_product.dart   # catálogo de productos (SKUs) + tipos
  entities/entitlements.dart    # estado: gemas, sin-ads, VIP, poseídos
  repositories/store_repository.dart  # interfaz agnóstica del proveedor
data/
  models/entitlements_model.dart(.g.dart)  # Hive typeId 4 (caja 'entitlements')
  datasources/store_local_datasource.dart
  repositories/in_app_purchase_store_repository.dart  # ⬅ REAL (móvil)
  repositories/stub_store_repository.dart            # ⬅ SIMULADA (web)
presentation/
  widgets/parental_gate.dart    # compuerta parental reutilizable
  pages/store_page.dart         # la Tienda (ruta /store, botón en Home)
```

Los packs cosméticos desbloquean accesorios reutilizando el flujo existente del
wallet (`UnlockPartEvent`).

## Cómo está cableado el pago real

`InAppPurchaseStoreRepository` usa la tienda del sistema para **comprar y
restaurar**, y el datasource local para el **estado** (gemas/VIP/poseídos). El
registro en `injection.dart` elige implementación por plataforma:

```dart
sl.registerLazySingleton<StoreRepository>(
  () => kIsWeb ? StubStoreRepository(sl()) : InAppPurchaseStoreRepository(sl()),
);
```

Lo que queda por hacer está **en la consola, no en el código**: crear los
productos en Google Play Console con los mismos `id` que en `store_product.dart`
(`vip_monthly`, `gems_small`, `gems_medium`, `bundle_starter`) y añadir testers de
licencia para probar sin cobro real. Si un ID no existe, la compra devuelve
"producto no encontrado" sin romper la app.

### Limitaciones asumidas (sin backend, decisión del MVP v1)

- **Sin validación de recibos en servidor**: el beneficio se concede en el
  cliente cuando la tienda confirma la compra.
- **La suscripción no controla el vencimiento**: se marca activa al comprar o
  restaurar; si el usuario cancela, sigue activa en ese dispositivo.
- **Estado solo local**: tras reinstalar hay que usar "Restaurar compras" para
  lo no consumible; las gemas gastadas no se recuperan.

Son aceptables para un juego de cosméticos sin ranking en línea. El diseño de un
backend que las resolvería está archivado en `docs/BACKEND-PAGOS.md` (post-MVP).

## Pendiente (siguientes pasos)

- Compuerta parental también antes de enlaces externos (políticas, redes).
- Vías de ganar gemas gratis además del VIP diario (misiones, hitos).
- Pase de temporada.
- Rediseño del *trade dress* visual (minifigura/studs) — riesgo de IP real.

## Club VIP (suscripción)

`vip_monthly` da beneficios reales (`vip_perks.dart`), sin anuncios de por medio:
- **Gemas diarias** (+25 💎): reclamables en la Tienda con `StoreRepository.claimVipDaily()`
  (una vez por día natural; se guarda `Entitlements.lastVipClaim`).
- **Monedas ×1.5 en carrera**: `BrixRunGame.coinMultiplier`, leído al arrancar la
  partida vía `StoreRepository.entitlementsSync().subscriptionActive`.

No hay producto "quitar anuncios" (el juego no tiene anuncios); el campo
`adsRemoved` se conserva solo por estabilidad del esquema Hive.

## Gastar gemas (canjería)

Las gemas (moneda dura, se obtienen comprando packs en la Tienda) se canjean
en `/gems` (`GemStorePage`) por premios de **precio fijo y determinista** —
sin azar ni cajas de botín (kid-safe): monedas o cosméticos concretos
(`gem_product.dart`). El gasto se hace con `StoreRepository.spendGems` y el
premio se entrega sobre el wallet existente (`EarnCoinsEvent` /
`UnlockPartEvent`). Se accede desde un botón en la Tienda.

[`ParentalGate`]: ../lib/features/monetization/presentation/widgets/parental_gate.dart
