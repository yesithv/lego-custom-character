# Checklist de publicación — Run For Win

Lista maestra para llevar el juego de "web demo con tienda simulada" a
**publicado y cobrando** en Google Play y App Store. Marca `[x]` a medida que
avances. Los que dicen **(código)** los puede hacer Claude; el resto son
acciones tuyas (cuentas, trámites, arte).

## Bloqueadores duros (resolver sí o sí antes de lanzar)

- [ ] 🎨 **Rediseño del _trade dress_ visual** (minifigura, studs, acabado
  plástico) para no parecerse a LEGO. Painters: `character_preview.dart`,
  `coin_component.dart`, `background_component.dart`, `obstacle_component.dart`,
  `scenery_component.dart`, `appearance_colors.dart`.
- [ ] 🔒 **Cumplimiento infantil** completo (documentos de esta carpeta +
  formularios de las tiendas).

## 1. Cuentas y bases

- [ ] Cuenta **Google Play Console** (25 USD, pago único).
- [ ] Cuenta **Apple Developer** (99 USD/año).
- [ ] Datos fiscales y bancarios para recibir pagos (ambas consolas).
- [ ] Decidir **bundle id / applicationId** (p. ej. `com.[empresa].runforwin`).

## 2. Proyecto nativo **(código + tú)**

- [ ] `flutter create .` para generar las carpetas `android/` e `ios/`.
- [ ] Configurar **nombre de app**, **bundle id**, **icono** y **splash**.
- [ ] Verificar que la build web sigue funcionando (los plugins de pago se aíslan
  por plataforma).

## 3. Compras integradas (IAP) **(código)**

- [ ] Añadir el plugin `in_app_purchase` (aislado para no romper web).
- [ ] Implementar `InAppPurchaseStoreRepository implements StoreRepository`.
- [ ] Cambiar **una línea** en `core/di/injection.dart` (stub → real).
- [ ] Mantener la **compuerta parental** antes de cada compra (ya existe).
- [ ] Manejar: stream de compras, completar/reconocer compra, **restaurar
  compras** (botón ya existe).
- [ ] (Recomendado) **Validación de recibos** en un backend mínimo.

## 4. Productos en las consolas

- [ ] Crear los IAP con los **mismos IDs** del catálogo
  (`store_product.dart`): `vip_monthly` (suscripción), `gems_small`,
  `gems_medium` (consumibles), `bundle_starter` (no consumible), etc.
- [ ] Fijar precios por región.
- [ ] Configurar el grupo de **suscripción** VIP (Apple/Google).

## 5. Documentación y cumplimiento (esta carpeta)

- [ ] **Política de privacidad** publicada en una **URL pública** →
  `POLITICA-DE-PRIVACIDAD.md`.
- [ ] **Términos de uso** (opcional pero recomendado) → `TERMINOS-DE-USO.md`.
- [ ] **Google Data Safety** rellenado → `FORMULARIOS-TIENDAS.md`.
- [ ] **Apple App Privacy** ("Data Not Collected") → `FORMULARIOS-TIENDAS.md`.
- [ ] **Clasificación por edad** (cuestionario IARC / Apple) → `FORMULARIOS-TIENDAS.md`.
- [ ] **Google "Diseñado para familias"** activado.
- [ ] **Apple categoría Kids** + banda de edad elegida.
- [ ] **URL / correo de soporte** configurado.

## 6. Ficha de la tienda (`FICHA-DE-TIENDA.md`)

- [ ] Nombre, subtítulo/descripción breve, descripción completa (ES + EN).
- [ ] Palabras clave (App Store).
- [ ] **Icono** (512² Google / 1024² Apple) — con el trade dress ya rediseñado.
- [ ] **Capturas** (mín. 2 Google / 3 Apple) y gráfico destacado (Google).
- [ ] Categoría, precio (Gratis + IAP), "sin anuncios".

## 7. Build de lanzamiento

- [ ] Android: generar **AAB firmado** (keystore) y subir a Play Console.
- [ ] iOS: build en **Xcode** y subir a **App Store Connect** vía TestFlight.
- [ ] Probar las **compras reales** en modo sandbox/prueba antes de publicar.

## 8. Revisión y publicación

- [ ] Enviar a revisión (Apple: días; Google: horas-días; **apps infantiles =
  escrutinio extra**).
- [ ] Responder a posibles rechazos (motivos frecuentes: privacidad, compuerta
  parental, contenido, claridad de la suscripción).
- [ ] Publicar (recomendado: **lanzamiento por fases** en Google Play).

## 9. Post-lanzamiento

- [ ] Vigilar la **analítica** (hoy local; considerar un backend para métricas
  agregadas).
- [ ] Recoger reseñas y planear la siguiente actualización (VIP, pase de
  temporada, más mundos).

---

### Estado del código de monetización (referencia)

Ya construido y funcionando con **stub**: Tienda, gemas, **Club VIP** (gemas
diarias + monedas ×1.5), compuerta parental, entitlements en Hive, analítica
first-party, desbloqueo de mundos por monedas acumuladas. Lo único que falta en
código para cobrar es el **adaptador `in_app_purchase` real** (paso 3).
