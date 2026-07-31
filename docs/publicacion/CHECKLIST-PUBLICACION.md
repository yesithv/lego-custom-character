# Checklist de publicación — Run For Win

Lista maestra para llevar el juego a **publicado y cobrando**. El objetivo
inmediato es el **MVP v1 en Google Play**: app autónoma (sin backend ni API) con
pagos reales. Marca `[x]` a medida que avances. Los que dicen **(código)** los
puede hacer Claude; el resto son acciones tuyas (cuentas, trámites, arte).

> **Alcance:** Google Play primero. iOS queda para después (la carpeta `ios/` aún
> no existe). El backend de validación de recibos está **descartado en el MVP**
> (ver `docs/BACKEND-PAGOS.md`, archivado).

## Bloqueadores duros (resolver sí o sí antes de lanzar)

- [ ] 🎨 **Rediseño del _trade dress_ visual** (minifigura, studs, acabado
  plástico) para no parecerse a LEGO. Painters: `character_preview.dart`,
  `coin_component.dart`, `background_component.dart`, `obstacle_component.dart`,
  `scenery_component.dart`, `appearance_colors.dart`.
- [ ] 🔒 **Cumplimiento infantil** completo (documentos de esta carpeta +
  formularios de las tiendas).
- [x] 🧪 **Modo de prueba seguro en release** — resuelto: el modo de prueba
  (`core/test_mode/test_mode.dart`) queda **inerte en la build de release** que se
  sube a Play (no se puede activar). Se conserva en debug/profile y se puede
  rehabilitar en un release firmado propio con
  `--dart-define=BRIX_TESTMODE=true`. Ver README. **(código)**

## 1. Cuentas y bases

- [ ] Cuenta **Google Play Console** (25 USD, pago único).
- [ ] Datos fiscales y bancarios para recibir pagos.
- [x] **applicationId decidido:** `com.iron_coding.runforwin` — ⚠️ inamovible una vez
  publicada la app.
- [ ] Cuenta **Apple Developer** (99 USD/año) — solo cuando se aborde iOS.

## 2. Proyecto nativo **(código + tú)**

- [x] Carpeta `android/` generada y en el repositorio.
- [x] **Nombre de app** ("Run For Win"), **applicationId**, orientación vertical
  fija, compileSdk/targetSdk 36, minSdk 24.
- [x] **Config de firma** que lee `android/key.properties` (ignorado por git) con
  plantilla `key.properties.example`; sin él, cae a claves de depuración.
- [x] Verificado que la **build web sigue compilando** con el plugin de pagos
  importado (el adaptador real solo se instancia en móvil).
- [x] **Icono y splash propios**: icono clásico (5 densidades) + **adaptativo**
  (Android 8+) y splash azul Brix. Generados por código con
  `flutter test tool/gen_icon.dart`; dos variantes en `kVariant` (bloque, la que
  se publica / cabeza de minifigura).
- [ ] Crear el **keystore de subida** y rellenar `android/key.properties`
  (comandos en el README).
- [ ] `flutter build appbundle --release` **verificado en local** (las sesiones
  remotas no tienen Android SDK).
- [ ] `ios/` — más adelante.

## 3. Compras integradas (IAP) **(código)**

- [x] Plugin `in_app_purchase` en el proyecto (aislado por plataforma).
- [x] `InAppPurchaseStoreRepository implements StoreRepository`.
- [x] Registrado en `core/di/injection.dart`: **real en móvil, stub en web**.
- [x] **Compuerta parental** antes de cada compra.
- [x] Stream de compras, completar/reconocer compra y **restaurar compras**.
- [ ] ~~Validación de recibos en un backend~~ → **fuera del MVP v1** (a cambio se
  asumen las limitaciones documentadas en el README).

## 4. Productos en Play Console

- [ ] Crear los IAP con los **mismos IDs** del catálogo
  (`store_product.dart`): `vip_monthly` (suscripción), `gems_small` y
  `gems_medium` (consumibles), `bundle_starter` (no consumible).
- [ ] Fijar precios por región.
- [ ] Configurar el grupo de **suscripción** VIP.
- [ ] Añadir **testers de licencia** para probar compras sin cobro real.

## 5. Documentación y cumplimiento (esta carpeta)

- [ ] **Política de privacidad** publicada en una **URL pública** →
  `POLITICA-DE-PRIVACIDAD.md`.
- [ ] **Términos de uso** (opcional pero recomendado) → `TERMINOS-DE-USO.md`.
- [ ] **Google Data Safety** rellenado → `FORMULARIOS-TIENDAS.md`. Con el MVP v1
  la respuesta es **"no se recopilan ni comparten datos"**: la app no hace
  ninguna petición de red.
- [ ] **Clasificación por edad** (cuestionario IARC) → `FORMULARIOS-TIENDAS.md`.
- [ ] **Google "Diseñado para familias"** activado.
- [ ] **URL / correo de soporte** configurado.

## 6. Ficha de la tienda (`FICHA-DE-TIENDA.md`)

- [ ] Nombre, descripción breve y descripción completa (ES + EN).
- [x] **Icono** 512² → `docs/publicacion/icono-512.png` (revisarlo si se
  rediseña el trade dress).
- [ ] **Capturas** (mín. 2) y **gráfico destacado** (1024×500).
- [ ] Categoría, precio (Gratis + IAP), "sin anuncios".

## 7. Build de lanzamiento

- [ ] `flutter build appbundle --release` → **AAB firmado** con el keystore de
  subida.
- [ ] Subir a **Play Console** → pista de **pruebas internas** primero.
- [ ] Probar las **compras reales** con testers de licencia antes de publicar.

## 8. Revisión y publicación

- [ ] Enviar a revisión (**apps infantiles = escrutinio extra**).
- [ ] Responder a posibles rechazos (motivos frecuentes: privacidad, compuerta
  parental, contenido, claridad de la suscripción).
- [ ] Publicar con **lanzamiento por fases**.

## 9. Post-lanzamiento

- [ ] Vigilar reseñas y fallos (Play Console → Android vitals).
- [ ] Planear la siguiente actualización (más mundos, pase de temporada, iOS).
- [ ] Valorar un backend **solo si el negocio lo justifica** (validación de
  recibos, vencimiento de la suscripción, ranking global).

---

### Estado del código (referencia)

**Listo y cableado:** editor de personajes, runner con jefes, economía (monedas,
ruleta, cofres, misiones), tienda con **pagos reales de Google Play**, gemas,
**Club VIP** (gemas diarias + monedas ×1.5), compuerta parental, entitlements en
Hive, analítica first-party local, desbloqueo de mundos por monedas acumuladas,
6 idiomas y plataforma Android configurada.

**Lo que falta para publicar no es código de la app**, sino arte (capturas,
gráfico destacado, rediseño del trade dress), trámites (cuenta, formularios,
política de privacidad) y la configuración de los productos en Play Console.
