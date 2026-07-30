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
| `gems_small` | Puñado de gemas (100) | USD 1,99 | Consumible |
| `gems_medium` | Cofre de gemas (550) | USD 8,99 | Consumible |
| `bundle_starter` | Pack de bienvenida | USD 3,99 | No consumible |
| `vip_monthly` | Club VIP | USD 4,99 / mes | **Suscripción** |

Los `priceLabel` del código son solo texto de relleno: el precio que se muestra
al usuario debe venir de la tienda, ya localizado en su moneda. No los uses para
lógica.

## Lo que falta, en orden

### 1. Proyecto nativo

`in_app_purchase` es un plugin con código nativo, así que **sin carpeta
`android/` no hay compras**. Hoy el repositorio solo tiene `lib/`, `web/`,
`test/` y `assets/`.

```bash
flutter create --platforms=android,ios .
```

Al generarlo, dos decisiones que **no se pueden deshacer** una vez publicada la
app:

- **`applicationId` / bundle id.** No puede quedar `com.example.run_for_win`:
  Google Play lo rechaza. Y el identificador **no se puede cambiar nunca** tras
  publicar. Propuesta: `art.ironcoding.runforwin`, que sigue valiendo si más
  adelante la app pasa de persona natural a empresa.
- **Keystore de firma.** Si se pierde, no se pueden publicar más
  actualizaciones. Activa Play App Signing y guarda el keystore y su contraseña
  en dos sitios distintos.

### 2. Permiso de facturación en Android

Google Play Billing lo añade el plugin, pero verifica que el manifiesto acabe
con:

```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

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
   adulto la aprueba. Hoy la UI no resuelve nada hasta que llega el resultado
   final; conviene mostrar un estado de espera explícito.
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
