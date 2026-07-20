# Documentación para publicar en las tiendas

Paquete de **borradores** de la documentación exigida para publicar **Run For
Win** (juego infantil, IAP, sin anuncios) en **Google Play** y **App Store**.

## ⚠️ Léelo antes de usar

- **No es asesoría legal.** Son borradores fieles a lo que la app hace **hoy**.
  Revísalos —idealmente con un profesional legal— antes de publicar. **COPPA**
  (datos de menores) tiene sanciones reales.
- Rellena todos los **marcadores** `[ENTRE CORCHETES]` (nombre/empresa, correo
  de contacto, jurisdicción, fechas, URLs).
- **Si cambian las prácticas de datos, actualiza la política de privacidad.** En
  concreto: si añades un **backend**, **analítica remota**, **cuentas de
  usuario** o cualquier **SDK de terceros**, las declaraciones dejan de ser
  válidas.

## Contenido

| Documento | Para qué |
|---|---|
| [`POLITICA-DE-PRIVACIDAD.md`](POLITICA-DE-PRIVACIDAD.md) | Política de privacidad pública (URL obligatoria en ambas tiendas). |
| [`TERMINOS-DE-USO.md`](TERMINOS-DE-USO.md) | Términos de uso / EULA. |
| [`FICHA-DE-TIENDA.md`](FICHA-DE-TIENDA.md) | Textos de la ficha (título, descripciones, keywords) en ES y EN. |
| [`FORMULARIOS-TIENDAS.md`](FORMULARIOS-TIENDAS.md) | Respuestas para Data Safety (Google), App Privacy (Apple), clasificación por edad y categoría Kids. |
| [`CHECKLIST-PUBLICACION.md`](CHECKLIST-PUBLICACION.md) | Lista maestra de todo lo necesario para lanzar. |

## Perfil de datos de la app (base de todos los documentos)

Fiel al código actual:

- **Sin anuncios** (decisión de producto).
- **Sin SDKs de terceros** (ni publicidad ni analítica de terceros).
- **Sin cuentas ni inicio de sesión.** No se pide nombre, correo, ubicación,
  contactos ni identificadores publicitarios.
- **Todo se guarda en el dispositivo** (Hive local): progreso, personajes,
  monedas/gemas, desbloqueos y **eventos de analítica propios**. **No se
  transmite a servidores nuestros** (no hay backend).
- **Compras dentro de la app** procesadas por **Apple/Google**; la app **no**
  recibe datos de pago. **Compuerta parental** antes de cada compra.
