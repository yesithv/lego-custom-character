# Monetización

Estado: **pagos reales cableados (MVP v1)**. En móvil la Tienda cobra con
**Google Play Billing / StoreKit** (`in_app_purchase`); en la demo web sigue con
compras **simuladas** porque el plugin no tiene implementación para web. El
cambio es automático por plataforma en `core/di/injection.dart`.

Falta un paso que **no es código**: dar de alta los productos en Google Play
Console con los mismos IDs del catálogo.

> **La economía completa (monedas, gemas, precios, conversión, análisis de
> mercado y decisiones) está en [`ECONOMIA.md`](ECONOMIA.md).** Este documento
> cubre la **arquitectura** de la monetización; aquél, el **balance económico**.

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
  entities/store_product.dart   # catálogo IAP (SKUs) + tipos + badge/coinAmount
  entities/gem_product.dart     # canjería de gemas (cosméticos premium + monedas)
  entities/entitlements.dart    # estado: gemas, totalGemsEarned, VIP, poseídos
  repositories/store_repository.dart  # interfaz (buy/spendGems/grantGems/claimVipDaily)
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
y añadir testers de licencia para probar sin cobro real. Si un ID no existe, la
compra devuelve "producto no encontrado" sin romper la app.

Catálogo actual (`store_product.dart`), en orden de conversión:

| SKU | Tipo | Precio | Entrega |
|-----|------|--------|---------|
| `bundle_starter` | no consumible | USD 2.99 | Capa vampiro EXCLUSIVA + 150 💎 + 1000 🪙 (una vez) |
| `vip_monthly` | suscripción | USD 4.99/mes | 25 💎/día + monedas ×1.5 + regalo VIP |
| `vip_yearly` | suscripción | USD 29.99/año | Igual que VIP, ~50% de ahorro |
| `gems_small` | consumible | USD 1.99 | 200 💎 |
| `gems_medium` | consumible | USD 4.99 | 550 💎 (+10%) |
| `gems_large` | consumible | USD 9.99 | 1200 💎 (+20%) |

Las tarjetas muestran **etiquetas de marketing** (`StoreProduct.badge`: "OFERTA
ÚNICA", "MÁS POPULAR", "MEJOR VALOR"…) para guiar la conversión.

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
- Pase de temporada.
- Cosméticos *legendary* comprables con monedas (dar techo a la progresión gratis).
- Rediseño del *trade dress* visual (minifigura/studs) — riesgo de IP real.

## Club VIP (suscripción)

`vip_monthly` (mensual) y `vip_yearly` (anual, ~50% de ahorro) dan los mismos
beneficios reales (`vip_perks.dart`), sin anuncios de por medio:
- **Gemas diarias** (+25 💎): reclamables en la Tienda con `StoreRepository.claimVipDaily()`
  (una vez por día natural; se guarda `Entitlements.lastVipClaim`).
- **Monedas ×1.5 en carrera**: `BrixRunGame.coinMultiplier`, leído al arrancar la
  partida vía `StoreRepository.entitlementsSync().subscriptionActive`.

No hay producto "quitar anuncios" (el juego no tiene anuncios); el campo
`adsRemoved` se conserva solo por estabilidad del esquema Hive.

## Obtener gemas gratis (faucet)

Además del VIP diario, todo jugador consigue gemas **jugando**: cada misión
completada regala **+1 💎** (en `runner_page`, vía `StoreRepository.grantGems`).
Es un goteo lento a propósito (el VIP es ~25× más rápido), para que las gemas
sean aspiracionales sin quitar el incentivo de compra. `grantGems` solo
incrementa el saldo (y `Entitlements.totalGemsEarned`), sin dinero real.

## Gastar gemas (canjería)

Las gemas (moneda dura) se canjean en `/gems` (`GemStorePage`) por premios de
**precio fijo y determinista** — sin azar ni cajas de botín (kid-safe):
- **Cosméticos EXCLUSIVOS** (piezas `premium`, no comprables con monedas):
  `capa vampiro` (120 💎), `botas propulsión` (140 💎).
- **Paquetes de monedas** (conveniencia): 500/40 💎, 1500/100 💎, 4000/240 💎.

El gasto se hace con `StoreRepository.spendGems` y el premio se entrega sobre el
wallet existente (`EarnCoinsEvent` / `UnlockPartEvent`). Se accede desde un botón
en la Tienda. Ningún cosmético de gemas existe también en monedas → no hay
productos "dominados".

## Billetera (resumen de economía)

Al tocar las monedas en el Home se abre **`/wallet`** (`WalletPage`): saldo de
monedas y gemas, cuánto se ha **ganado / gastado / queda** de cada una, y logros
(piezas, mundos, racha, VIP). El gastado se deriva: monedas =
`totalCoinsEarned − coins`; gemas = `totalGemsEarned − gems`.

[`ParentalGate`]: ../lib/features/monetization/presentation/widgets/parental_gate.dart
