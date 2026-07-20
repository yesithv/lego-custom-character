# Monetización

Estado: **cimientos (Fase 1)**. La Tienda funciona con compras **simuladas**
(stub) para poder construir y probar la UI sin plugins nativos ni configurar
productos en las tiendas. El pago real se conecta más adelante sustituyendo una
sola implementación.

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
  repositories/stub_store_repository.dart   # ⬅ implementación SIMULADA
presentation/
  widgets/parental_gate.dart    # compuerta parental reutilizable
  pages/store_page.dart         # la Tienda (ruta /store, botón en Home)
```

Los packs cosméticos desbloquean accesorios reutilizando el flujo existente del
wallet (`UnlockPartEvent`).

## Conectar el pago real (cuando haya apps nativas)

1. `flutter create .` para generar las carpetas `android/` e `ios/`.
2. Añadir `in_app_purchase` (y en Android `google_mobile_ads`). **Ojo:** estos
   plugins no soportan web; mantener la web con el stub o tras `kIsWeb`.
3. Crear los productos en Google Play Console y App Store Connect con los mismos
   `id` que en `store_product.dart` (`remove_ads`, `vip_monthly`, `gems_*`,
   `bundle_starter`).
4. Implementar `InAppPurchaseStoreRepository implements StoreRepository` y
   cambiar **una línea** en `injection.dart`:
   ```dart
   sl.registerLazySingleton<StoreRepository>(() => StubStoreRepository(sl()));
   // →
   sl.registerLazySingleton<StoreRepository>(() => InAppPurchaseStoreRepository(...));
   ```
5. Validar recibos (idealmente en backend) antes de conceder `entitlements`.

## Pendiente (siguientes pasos)

- Compuerta parental también antes de enlaces externos (políticas, redes).
- Vías de ganar gemas gratis además del VIP diario (misiones, hitos).
- Pase de temporada.
- Adaptador `in_app_purchase` real que sustituya el stub.
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
