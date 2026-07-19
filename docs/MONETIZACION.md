# Monetización

Estado: **cimientos (Fase 1)**. La Tienda funciona con compras **simuladas**
(stub) para poder construir y probar la UI sin plugins nativos ni configurar
productos en las tiendas. El pago real se conecta más adelante sustituyendo una
sola implementación.

## Producto para niños — reglas que condicionan todo

- **Apple (categoría Kids):** prohíbe anuncios de terceros y analítica de
  terceros. → en iOS se monetiza con **IAP + suscripción**, sin ads de terceros.
- **Android (Designed for Families):** anuncios recompensados **no
  personalizados** con SDK certificado.
- **Toda compra pasa por [`ParentalGate`]** (compuerta parental). Obligatorio.
- Nada de pago-para-ganar ni cajas de botín con dinero real. Solo cosmético,
  conveniencia o quitar-anuncios.

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
- Anuncios recompensados **solo Android** (×2 monedas, giro extra de ruleta).
- Analítica de funnel **first-party** (kid-safe para iOS).
- Suscripción VIP con entregas diarias; pase de temporada.
- Gastar gemas (ruleta premium determinista, cosméticos) — hoy solo se acumulan.
- Rediseño del *trade dress* visual (minifigura/studs) — riesgo de IP real.

[`ParentalGate`]: ../lib/features/monetization/presentation/widgets/parental_gate.dart
