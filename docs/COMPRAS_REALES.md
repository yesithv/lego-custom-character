# Compras reales (in-app purchases)

Cómo pasar de la tienda simulada al cobro real, y qué hay que dejar atado
antes de que un usuario pueda gastar dinero.

## Qué ya está hecho

El código estaba preparado desde el principio. La capa de dominio no sabe de
tiendas: `StoreRepository` define el contrato y hay dos implementaciones.

| Implementación | Qué hace | Dónde se usa |
|---|---|---|
| `StubStoreRepository` | Simula la compra y concede el beneficio al instante | Web (demo) |
| `InAppPurchaseStoreRepository` | Compra real vía Google Play Billing / StoreKit | Android e iOS |

El registro en `core/di/injection.dart` ya elige según la plataforma:

```dart
sl.registerLazySingleton<StoreRepository>(
  () => kIsWeb
      ? StubStoreRepository(sl())
      : InAppPurchaseStoreRepository(sl()),
);
```

La compuerta es `kIsWeb` y no un import condicional a propósito: el paquete
`in_app_purchase` se resuelve igual en todas las plataformas; lo que no se puede
es *usarlo* en el navegador, donde no existe `InAppPurchase.instance`.

**Consecuencia importante:** la demo web sigue siendo simulada. Nadie paga nada
en `yesithv.github.io`, y así debe quedarse.

## El catálogo es la fuente de verdad

Los ids de `lib/features/monetization/domain/entities/store_product.dart` son
los SKU. Tienen que coincidir **exactamente** con los de las consolas, letra
por letra:

| id | Producto | Precio de referencia | Tipo en la tienda |
|---|---|---|---|
| `bundle_starter` | Pack de bienvenida (skin exclusivo + 150 💎 + 1000 🪙) | USD 2,99 | No consumible |
| `vip_monthly` | Club VIP | USD 4,99 / mes | **Suscripción** |
| `vip_yearly` | Club VIP anual | USD 29,99 / año | **Suscripción** |
| `gems_small` | Puñado de gemas (200) | USD 1,99 | Consumible |
| `gems_medium` | Cofre de gemas (550) | USD 4,99 | Consumible |
| `gems_large` | Baúl de gemas (1200) | USD 9,99 | Consumible |

Los `priceLabel` del código son solo texto de relleno para la demo web. En
móvil, la Tienda pide los precios reales a la tienda al abrirse
(`StoreRepository.loadPrices` → `queryProductDetails`) y muestra el precio ya
localizado en la moneda del usuario; el `priceLabel` solo se usa como respaldo
si la tienda no responde. No uses ninguno de los dos para lógica.

## Lo que falta, en orden

### 1. Proyecto nativo

`in_app_purchase` es un plugin con código nativo, así que sin carpeta nativa no
hay compras.

- **Android: ✅ ya generado y configurado.** `android/` existe con
  `applicationId = "com.iron_coding.runforwin"` (en `android/app/build.gradle.kts`).
  Ese identificador **no se puede cambiar nunca** tras publicar en Google Play.
- **iOS: ⛔ pendiente.** No existe `ios/` todavía. Cuando toque publicar en la
  App Store: `flutter create --platforms=ios .` y dejar solo orientaciones
  portrait en `Info.plist`.

Sigue pendiente, antes de la primera release:

- **Keystore de firma.** Hoy solo hay `android/key.properties.example`; falta
  crear el keystore real y rellenar `android/key.properties` (ignorado por git).
  Si no está, la firma de release cae a claves de depuración y **Play rechaza la
  subida**. Si el keystore se pierde, no se pueden publicar más actualizaciones:
  activa Play App Signing y guárdalo con su contraseña en dos sitios distintos.

### 2. Permiso de facturación en Android

**✅ Ya declarado** en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

El plugin también lo aporta y se fusiona en el manifiesto final; se dejó
explícito para que la intención sea visible.

### 3. Alta de productos en las consolas

En **Google Play Console**: *Monetizar → Productos*. Los consumibles y el no
consumible van en «Productos integrados en la aplicación»; el VIP va en
«Suscripciones», que es una sección aparte con su propio plan base.

En **App Store Connect**: *Compras dentro de la app*, y las suscripciones en un
grupo de suscripción.

Requisitos previos que suelen frenar aquí:

- **Perfil de pagos verificado** en Play Console, con datos fiscales y cuenta
  bancaria. Sin él los productos no se activan.
- La app tiene que tener **al menos una release subida** (aunque sea a prueba
  interna) antes de poder crear productos.

### 4. Probar sin gastar dinero

- **Android:** añade tu cuenta en *Configuración → Pruebas de licencia*. Las
  compras se procesan de verdad pero no se cobran, y las suscripciones se
  renuevan en minutos en lugar de meses.
- **iOS:** usa cuentas Sandbox de App Store Connect.

Casos que hay que probar a mano, porque son los que fallan:

1. Compra completada.
2. Compra cancelada por el usuario a mitad.
3. Compra **pendiente** — «Pedir permiso» / Ask to Buy: un menor pide
   autorización y la compra queda en `PurchaseStatus.pending` hasta que un
   adulto la aprueba. La UI ya lo contempla: al llegar `pending` se desbloquea
   el botón y se muestra el aviso `iap_purchase_pending`; el beneficio se
   concede cuando llega `purchased` (se persiste aunque ya no haya diálogo
   abierto) y se ve al recargar la Tienda.
4. Restaurar compras en un dispositivo nuevo (el pack cosmético y el VIP deben
   volver; las gemas consumidas no).
5. Cancelar la suscripción y comprobar qué pasa al vencer.
6. Sin conexión: la tienda no responde y la app no debe quedarse colgada.

## Limitaciones que asumimos en la v1

El adaptador las documenta en su propia cabecera. Están asumidas a conciencia,
pero conviene saberlas:

- **Sin validación de recibos en servidor.** El beneficio se concede en el
  cliente. Un dispositivo modificado puede conseguir gemas gratis. Aceptable
  para un juego cosmético sin economía competitiva; inaceptable si algún día hay
  ranking online con premios.
- **La suscripción no controla el vencimiento.** Se marca `subscriptionActive`
  al comprar o restaurar, pero no se rastrea la fecha de expiración. Hace falta
  un backend, o la Play Developer API / App Store Server API, para saber cuándo
  caducó. **Hoy un VIP cancelado sigue siendo VIP en el dispositivo.** Es la
  limitación más gorda y la primera que hay que cerrar si el VIP se vende.
- **Sin webhooks de la tienda**, así que no nos enteramos de reembolsos ni
  cancelaciones.

## Consecuencias fuera del código

Activar compras reales no es solo técnico:

- **Formulario de Seguridad de los Datos** de Play: hay que declarar la compra
  y el identificador asociado.
- **Clasificación por edades y público objetivo.** El juego es *kid-safe* por
  diseño —sin anuncios, sin cajas de botín, precios deterministas y compuerta
  parental— pero con una suscripción de por medio la declaración de «sin edad
  mínima» deja de sostenerse sola. Hay que decidirla explícitamente.
- **Política de privacidad y términos** de la app, en
  `iron-coding.art/proyectos/run-for-win/`. Decían «sin compras dentro de la
  aplicación»; ya están corregidos, pero cualquier cambio de catálogo hay que
  reflejarlo ahí.
- **Transferencia de cuenta.** Si algún día la app pasa de cuenta personal a
  cuenta de empresa: en Apple, las apps con suscripciones tienen condiciones
  añadidas para poder transferirse. Confírmalo en App Store Connect **antes** de
  publicar con `vip_monthly` activo.

## Comprobación rápida antes de subir una release

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Y ojo con la web, que comparte el mismo código:

```bash
flutter build web --release --base-href "/lego-custom-character/"
```

Si la build web falla después de tocar monetización, casi siempre es que algo
del adaptador real se está instanciando fuera del `kIsWeb`.
