# Respuestas para los formularios de las tiendas

> Respuestas sugeridas **fieles al código actual** (sin anuncios, sin SDKs de
> terceros, sin backend, sin cuentas; todo local en el dispositivo). Si cambias
> las prácticas de datos, **revisa estas respuestas**.

---

## 1. Google Play — "Seguridad de los datos" (Data safety)

| Pregunta | Respuesta |
|---|---|
| ¿La app recopila o comparte datos de usuario? | **No** recopila ni comparte datos de usuario con nosotros ni con terceros. |
| ¿Recopila identificadores, ubicación, contactos, etc.? | **No.** |
| Datos guardados en el dispositivo (progreso, ajustes) | Se declaran como **almacenamiento local en el dispositivo**, no "recopilación" (no salen del dispositivo). |
| ¿Se cifran los datos en tránsito? | No aplica (no se transmiten datos). |
| ¿El usuario puede pedir que se borren sus datos? | **Sí:** desinstalando la app o borrando sus datos desde ajustes. |
| ¿Cumple con la política de Familias? | **Sí.** |

> Nota: Play trata las **compras** por separado (Google gestiona el pago); no las
> declaras como recopilación de datos por tu parte.

### Público objetivo y contenido (Google Play)
- **Grupo de edad objetivo:** incluye **niños** (marca las franjas correspondientes,
  p. ej. **6-8** y/o **9-12**).
- **Anuncios:** **No**.
- **Programa "Diseñado para familias":** **Sí** (opta por él).

---

## 2. Apple — "Privacidad de la app" (App Privacy / nutrition label)

| Sección | Respuesta |
|---|---|
| ¿La app recopila datos? | **No** ("Data Not Collected"). |
| Rastreo (App Tracking Transparency) | **No** se hace tracking → no se requiere el prompt de ATT. |
| Datos vinculados al usuario | Ninguno. |
| Datos usados para seguirte | Ninguno. |

> Las **compras** las procesa Apple; no declaras recopilación de datos de pago.

### Categoría Kids (Apple)
- Publicar en la **categoría Kids**.
- **Banda de edad:** **[6-8]** (o 9-11 según decidas; ver clasificación abajo).
- Cumple los requisitos: **sin anuncios de terceros**, **sin analítica de
  terceros**, **compuerta parental** antes de compras/enlaces externos, política
  de privacidad enlazada.

---

## 3. Clasificación por edad (cuestionario de contenido)

Respuestas típicas para este juego (peleas de dibujos, sin sangre, sin texto
libre entre usuarios):

| Pregunta | Respuesta |
|---|---|
| Violencia | **Fantástica/de dibujos, leve** (esquivar y "embestir" a un jefe; sin sangre ni gore). |
| Miedo / terror | Ninguno o muy leve (un mundo "Ciudad Oscura" temático de Halloween). |
| Lenguaje soez | Ninguno. |
| Contenido sexual | Ninguno. |
| Sustancias (alcohol/drogas/tabaco) | Ninguno. |
| Juego con dinero real / apuestas | **No** (las gemas se compran a precio fijo; **sin loot boxes con dinero real**). |
| Interacción entre usuarios / chat | **No**. |
| Compartir ubicación | **No**. |
| Compras digitales | **Sí** (IAP). |

**Resultado esperado:** clasificación apta para niños (p. ej. **PEGI 3-7 / ESRB
Everyone / IARC equivalente**), con el aviso de "Compras integradas".

> El cuestionario IARC de Google genera las clasificaciones regionales
> automáticamente; en Apple, tú fijas la banda de edad.

---

## 4. Otros datos que piden ambas fichas

- **URL de política de privacidad:** [URL PÚBLICA] (usa `POLITICA-DE-PRIVACIDAD.md`).
- **URL / correo de soporte:** [CORREO DE CONTACTO] · [URL OPCIONAL].
- **Contacto del desarrollador:** [NOMBRE], [CORREO], [DIRECCIÓN si aplica].
- **Cuenta de prueba:** no aplica (no hay inicio de sesión).
- **Productos IAP:** dar de alta con los mismos IDs del catálogo
  (`lib/features/monetization/domain/entities/store_product.dart`):
  `vip_monthly`, `gems_small`, `gems_medium`, `bundle_starter` (y los que añadas).
