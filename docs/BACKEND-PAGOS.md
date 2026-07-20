# Backend de validación de pagos

Estado: **diseño / propuesta**. Aún no existe backend; hoy la Tienda usa
`StubStoreRepository` (compras simuladas en local) y los *entitlements* viven
solo en Hive dentro del dispositivo. Este documento define **cómo debería ser**
el backend para validar pagos reales cuando se publiquen las apps nativas, cómo
encaja con la arquitectura actual, y qué **más** debería incluir.

> Contexto obligatorio antes de leer: **público niños (<13)** → COPPA / GDPR-K /
> reglas Kids de las tiendas; **monetización solo IAP, sin anuncios**; analítica
> **first-party** (sin SDK de terceros). Ver `docs/ESTADO-PROYECTO.md` y
> `docs/MONETIZACION.md`.

---

## 1. Por qué hace falta un backend

Con `in_app_purchase` en el cliente **la compra funciona sin servidor**: la
tienda cobra y devuelve un recibo. El problema es la **confianza**:

- Un recibo validado **solo en el cliente** es falsificable (apps rooteadas,
  cheats, respuestas mockeadas). Regalar gemas/VIP a quien no pagó es fraude.
- Los *entitlements* solo en Hive **se pierden** al reinstalar o cambiar de
  dispositivo, y **no se sincronizan** entre iOS y Android del mismo niño.
- Las **suscripciones** (VIP `vip_monthly`) cambian de estado *fuera de la app*:
  renuevan, se cancelan, entran en *grace period*, hacen *refund*/*chargeback*.
  Sin servidor, la app nunca se entera de esas transiciones.
- Apple y Google **exigen o recomiendan validación server-to-server** para
  suscripciones y para reaccionar a reembolsos.

**Regla de oro:** el backend es la **única fuente de verdad** de los
*entitlements*. El cliente **pide**, el servidor **verifica con la tienda y
concede**. El cliente nunca se auto-concede nada que valga dinero.

---

## 2. Rol del backend (qué hace y qué NO hace)

**Hace:**
- Recibe el token/recibo de compra del cliente y lo **verifica contra Apple /
  Google** (server-to-server).
- Es dueño del estado de *entitlements* por cuenta (gemas, VIP, poseídos) y lo
  **sirve** al cliente.
- Escucha **notificaciones de servidor** de las tiendas (renovación, cancelación,
  reembolso, *chargeback*) y actualiza el estado sin que el niño abra la app.
- **Acredita** las gemas consumibles y marca el *token* como consumido
  (anti-*replay*: un recibo se canjea una sola vez).
- Guarda un **registro de auditoría** de transacciones para soporte y disputas.

**NO hace:**
- No cobra (lo hace la tienda). No guarda datos de tarjeta (nunca los ve).
- No corre lógica de juego (física, puntajes de partida): eso sigue local.
- No usa SDK de analítica de terceros (prohibido en apps Kids).

---

## 3. Flujo de validación (compra de un producto)

```
  App (Flutter)                 Backend                     Tienda (Apple/Google)
      │                            │                                 │
  1. ParentalGate OK              │                                 │
  2. in_app_purchase.buy(sku) ───────────────────────────────────▶ │  cobra
      │  ◀─── PurchaseDetails (verificationData/purchaseToken) ──── │
  3. POST /purchases/verify ────▶ │                                 │
      │   {platform, sku,         │  4. verifica token/recibo ────▶ │
      │    token, txId}           │   (App Store Server API /       │
      │                           │    Google Play Developer API)   │
      │                           │  ◀───── válido + estado ─────── │
      │                           │  5. concede entitlement,        │
      │                           │     marca token consumido,      │
      │                           │     escribe auditoría           │
      │  ◀── 200 {entitlements} ──│                                 │
  6. completePurchase() ─────────────────────────────────────────▶ │  (finish/ack)
  7. UI actualiza wallet/estado   │                                 │
```

Puntos críticos:

- **No conceder antes de verificar.** El orden es: comprar → verificar en
  servidor → conceder → **luego** `completePurchase()`/`acknowledge`. Si no se
  hace *acknowledge* en Android en 3 días, Google **reembolsa** automáticamente.
- **Idempotencia:** la clave es `transactionId` (Apple) /
  `orderId`/`purchaseToken` (Google). Reenvíos del mismo token no vuelven a
  acreditar gemas.
- **Consumibles vs no consumibles:** las gemas (`gems_small`, `gems_medium`) se
  acreditan al saldo y el token queda **consumido**; `remove_ads`,
  `bundle_starter` y la suscripción son **estado permanente** por cuenta.

### 3.1 Apple (iOS)
- Verificar con **App Store Server API** (JWS/`StoreKit 2` transactions) —
  preferible al viejo `verifyReceipt` (deprecado).
- Suscribirse a **App Store Server Notifications V2** (webhook) para
  renovaciones, `DID_RENEW`, `EXPIRED`, `REFUND`, `GRACE_PERIOD`.
- Autenticación con **clave de API de App Store Connect** (JWT ES256).

### 3.2 Google (Android)
- Verificar con **Google Play Developer API**
  (`purchases.products.get` para consumibles/no consumibles;
  `purchases.subscriptionsv2.get` para VIP).
- Suscribirse a **Real-Time Developer Notifications (RTDN)** vía Pub/Sub para
  el ciclo de vida de la suscripción y reembolsos.
- Autenticación con **service account** (OAuth2) con permiso de finanzas.
- **Acknowledge** la compra vía API o el cliente en <3 días.

---

## 4. Modelo de datos del servidor (mínimo)

Sin PII de niños siempre que se pueda (COPPA — ver §7). Cuentas **anónimas por
dispositivo/instalación**, no email de menores.

```
account
  id (uuid)                      # cuenta anónima; puede unir iOS+Android por login opcional del tutor
  created_at

entitlement                      # estado derivado, servido al cliente
  account_id
  gems (int)                     # saldo consumible
  ads_removed (bool)             # se conserva por esquema aunque no haya ads
  vip_active (bool)
  vip_expires_at (nullable)
  owned_product_ids (json array)
  updated_at

purchase_txn                     # auditoría + idempotencia
  id (uuid)
  account_id
  platform (apple|google)
  sku
  transaction_id (unique)        # clave de idempotencia
  original_transaction_id        # enlace de renovaciones de suscripción
  status (verified|refunded|chargeback|expired)
  raw_payload (json)             # respuesta de la tienda, para disputas
  created_at

gem_ledger                       # libro mayor de gemas (por qué subió/bajó el saldo)
  id, account_id, delta, reason (purchase|redeem|grant), ref_txn_id, created_at
```

`entitlement` es el espejo servidor de `Entitlements` del cliente
(`lib/features/monetization/domain/entities/entitlements.dart`). El
`gem_ledger` permite reconstruir el saldo y da trazabilidad para soporte.

---

## 5. Contrato de API (borrador)

Todo sobre **HTTPS**, JSON, con un token de sesión de la cuenta anónima.

| Método | Ruta | Qué hace |
|--------|------|----------|
| `POST` | `/v1/session` | Crea/recupera cuenta anónima para esta instalación; devuelve token. |
| `GET`  | `/v1/entitlements` | Estado actual (fuente de verdad). El cliente lo cachea en Hive. |
| `POST` | `/v1/purchases/verify` | Verifica un recibo/token y concede. Idempotente por `transactionId`. |
| `POST` | `/v1/purchases/restore` | Restaura no-consumibles + suscripción (requisito de tiendas). |
| `POST` | `/v1/gems/spend` | Gasta gemas de forma atómica en servidor (evita saldo negativo por carreras). |
| `POST` | `/v1/webhooks/apple` | App Store Server Notifications V2. |
| `POST` | `/v1/webhooks/google` | Google RTDN (Pub/Sub push). |

Estos endpoints mapean **1:1** con los métodos de `StoreRepository`
(`getEntitlements`, `buy`, `restorePurchases`, `spendGems`), así que el cliente
casi no cambia (ver §6).

---

## 6. Cómo encaja con el código actual

El proyecto ya está preparado para esto: `StoreRepository` es una **interfaz
agnóstica del proveedor** y hoy la cumple `StubStoreRepository`. Se añade una
tercera implementación sin tocar la UI:

```
StubStoreRepository        ← hoy: simulado, todo local (web/dev)
InAppPurchaseStoreRepository ← compra en tienda, valida SOLO en cliente (no recomendado en prod)
ServerStoreRepository       ← compra en tienda + verifica y sincroniza con backend  ✅ objetivo
```

`ServerStoreRepository` orquesta: `in_app_purchase` para el flujo de compra +
un `PaymentsApiClient` (HTTP) que habla con el backend. Cambio de **una línea**
en `lib/core/di/injection.dart`, igual que el patrón de `ScoreRepository`:

```dart
sl.registerLazySingleton<StoreRepository>(() => StubStoreRepository(sl()));
// →
sl.registerLazySingleton<StoreRepository>(
  () => ServerStoreRepository(purchases: sl(), api: sl()),
);
```

- **La web sigue con el stub** (los plugins nativos no soportan web y no hay
  cobro real en la demo): seleccionar implementación tras `kIsWeb`.
- Hive pasa a ser **caché offline** del estado del servidor, no la verdad.
- La **compuerta parental** sigue en la capa de presentación, **antes** de
  llamar a `buy` (sin cambios).

---

## 7. Kids-safe / cumplimiento (condiciona el diseño)

- **COPPA / GDPR-K:** minimizar datos. Cuenta **anónima por instalación**, sin
  pedir email/nombre del niño. Si se quiere sincronizar iOS↔Android, hacerlo con
  un **login opcional del tutor**, no del menor.
- **Sin SDK de analítica/atribución de terceros** en el backend orientado a la
  app (regla Apple Kids). La telemetría agregada que llegue al backend debe ser
  **first-party** y sin identificadores de dispositivo persistentes.
- **Compuerta parental** obligatoria antes de comprar (ya implementada en
  cliente). El backend **no** sustituye eso; lo complementa.
- **Sin pago-para-ganar ni cajas de botín con dinero real:** el backend concede
  cosméticos/gemas con premios **deterministas**, nunca aleatorios pagados.
- **Retención y borrado:** endpoint/proceso para **borrar la cuenta y sus datos**
  (derecho de acceso/borrado). Guardar `raw_payload` de transacciones el mínimo
  legal necesario para disputas y luego purgar.
- **Cifrado en tránsito y en reposo**; secretos (claves de App Store/Google) en
  un gestor de secretos, nunca en el repo.

---

## 8. Qué MÁS debería tener el backend (recomendaciones)

Más allá de validar pagos, con relativamente poco esfuerzo el mismo backend
habilita varias cosas del roadmap pendiente (`ESTADO-PROYECTO.md §5`):

1. **Manejo de reembolsos/chargebacks (imprescindible):** al recibir el webhook,
   **revocar** el entitlement (o descontar gemas ya gastadas contra saldo). Sin
   esto, un reembolso deja premios regalados.
2. **Entrega de beneficios VIP reales:** el backend es el sitio natural para
   acreditar **gemas diarias**, aplicar **multiplicador de monedas** y cosméticos
   exclusivos mientras `vip_active` y `vip_expires_at` sean válidos. Hoy el VIP
   se compra pero no hace nada.
3. **Sincronización multi-dispositivo / restauración real:** que el progreso de
   compras (y opcionalmente el wallet) sobreviva a reinstalar y viaje entre los
   dispositivos del niño.
4. **Configuración remota del catálogo (server-driven):** precios de ejemplo,
   packs y ofertas servidos desde el backend, para **cambiar la Tienda sin
   publicar** una versión nueva (respetando siempre los SKUs de las consolas).
5. **Sink de analítica agregada first-party:** recibir los eventos que hoy son
   locales (`app_open`, `run_start`, `purchase_*`…) de forma **anonimizada** para
   ver funnel y retención D1/D7 a nivel de producto. Debe ser propio, sin SDK
   externos (Kids).
6. **Ranking / leaderboard online:** ya hay `ScoreRepository` desacoplado con un
   `ScoreLocalRepository`; el backend puede exponer un ranking global real
   (moderado, sin nombres personales de menores).
7. **Anti-fraude / rate limiting:** límites por cuenta e IP, detección de
   tokens reusados, alertas de patrones raros de canjeo.
8. **Observabilidad:** logs estructurados, métricas y alertas (especialmente en
   los webhooks: si se caen, se pierden transiciones de suscripción).
9. **Panel de soporte mínimo:** buscar una cuenta por `transactionId`, ver su
   `gem_ledger` y reemitir un entitlement — para resolver quejas de padres.
10. **Migraciones y versionado de API** (`/v1`) para no romper apps ya
    publicadas cuando el niño no actualiza.

**Lo que NO recomendaría meter** (para no inflar alcance ni riesgo Kids):
chat/social, publicidad, SDKs de terceros de analítica/atribución, login
obligatorio del menor, o cualquier aleatoriedad pagada.

---

## 9. Stack sugerido y hoja de ruta por fases

**Stack:** el proyecto ya contempla Firebase como opción. Dos caminos válidos:

- **Firebase (Cloud Functions + Firestore):** rápido de arrancar, webhooks y
  service accounts fáciles. **Cuidado:** **no** incluir Firebase Analytics/otros
  SDKs de tracking en la app Kids; usar solo Functions/Firestore/Auth anónimo.
- **Servicio propio ligero** (p. ej. Dart `shelf`/Node/Go + Postgres): más
  control sobre datos y cumplimiento, sin dependencias de tracking. Recomendado
  si se quiere máxima independencia de terceros.

> Recomendación: empezar por **Cloud Functions + Firestore con Auth anónimo**
> por velocidad, aislando toda la lógica de pagos detrás de la API de §5 para
> poder migrar a servidor propio después sin tocar el cliente.

**Fases:**

1. **Fase 0 (hoy):** stub local. Sin backend. ✅
2. **Fase 1 — Validación:** `/session`, `/entitlements`, `/purchases/verify`,
   `/restore`; verificación Apple+Google; idempotencia; webhooks de reembolso.
   `ServerStoreRepository` en cliente.
3. **Fase 2 — Suscripción viva:** webhooks V2/RTDN completos, VIP con gemas
   diarias y multiplicador, `/gems/spend` atómico.
4. **Fase 3 — Producto:** catálogo server-driven, analítica agregada
   first-party, ranking online, panel de soporte, anti-fraude.

---

## 10. Acciones del usuario (no-código) para habilitarlo

- `flutter create .` para generar `android/` e `ios/` (aún no existen).
- Alta de productos en **Google Play Console** y **App Store Connect** con los
  **mismos SKUs** que `store_product.dart`.
- Credenciales server-to-server: **clave de API de App Store Connect** (JWT) y
  **service account** de Google Play con permiso de finanzas.
- Configurar **App Store Server Notifications V2** y **RTDN (Pub/Sub)** apuntando
  a los webhooks del backend.
- **Política de privacidad** y formularios Data Safety / categoría Kids que
  reflejen el backend y el manejo de datos.

---

### Referencias en el código

- Interfaz: `lib/features/monetization/domain/repositories/store_repository.dart`
- Estado: `lib/features/monetization/domain/entities/entitlements.dart`
- Catálogo/SKUs: `lib/features/monetization/domain/entities/store_product.dart`
- Stub actual: `lib/features/monetization/data/repositories/stub_store_repository.dart`
- Punto de cambio (1 línea): `lib/core/di/injection.dart`
- Docs relacionadas: `MONETIZACION.md`, `ESTADO-PROYECTO.md`
