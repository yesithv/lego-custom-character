# 🧱 Run For Win

> Creador de personajes de bloques **Brix** + Endless Runner pseudo-3D con jefes de mundo, hecho en Flutter + Flame.

**Versión actual: MVP v1 — app autónoma para Google Play.**
La app funciona **entera sin internet** y **cobra con Google Play Billing**. No
hay servidor propio, ni API, ni cuentas de usuario: todo el progreso vive en el
dispositivo. Ver [Alcance del MVP v1](#alcance-del-mvp-v1).

> **Nota de nombres:** el nombre de producto (título de la app y UI) es **Run For Win**. **Brix** es la marca del estilo de bloques del juego (personajes, mundos). El **codename interno** del código sigue siendo **BrixRun** (clases `BrixRunApp`, `BrixRunGame`), y el paquete Dart es `run_for_win`.

Run For Win combina dos experiencias en una sola app:

1. **Editor de personajes** — diseña una minifigura personalizable (cara, peinado/casco, torso, piernas, calzado, accesorios por ranura). Puedes partir de **personajes precargados (presets)** y editarlos.
2. **Endless Runner** — corre con tu personaje por mundos temáticos en una vista pseudo-3D de 3 carriles, esquivando obstáculos, recogiendo monedas, activando power-ups y, al final de cada mundo, enfrentándote a una **pelea contra el jefe**.

Alrededor de esos dos pilares hay una **economía de monedas** (ruleta diaria, cofres, tienda de piezas), un sistema de **misiones** y un **ranking** local por mundo.

🎮 **Demo web (secundaria, sin cobros):** https://yesithv.github.io/lego-custom-character/

---

## Índice

- [Alcance del MVP v1](#alcance-del-mvp-v1)
- [Características](#características)
- [Stack técnico](#stack-técnico)
- [Puesta en marcha](#puesta-en-marcha)
- [Compilar para Google Play](#compilar-para-google-play)
- [Monetización (IAP)](#monetización-iap)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Documentación](#documentación)
- [Flujo de trabajo Git](#flujo-de-trabajo-git)
- [Despliegue de la demo web](#despliegue-de-la-demo-web)

---

## Alcance del MVP v1

El objetivo de esta versión es **publicar en Google Play una app jugable y
descargable, aislada, con pagos reales**. La integración con un API/backend
propio **queda fuera del alcance**.

### Qué significa "aislada"

| Área | Cómo funciona en el MVP v1 |
|------|----------------------------|
| **Red** | La app **no hace ninguna petición de red**. No hay `http`, ni Firebase, ni SDKs de terceros en las dependencias. |
| **Progreso** | Personajes, monedas, misiones, entitlements y ranking en **Hive local**. |
| **Cuentas** | No hay registro ni login. Nada de identificadores de usuario. |
| **Ranking** | Tabla **por dispositivo** (`ScoreLocalRepository`). No es global. |
| **Analítica** | **First-party y local** (`LocalAnalyticsService`): los eventos se guardan en Hive para QA y **nunca salen del dispositivo**. Por eso en Google Play se declara "no se recopilan ni comparten datos". |
| **Pagos** | **Reales** vía Google Play Billing (`in_app_purchase`). Es lo único que sale del dispositivo, y lo gestiona la propia tienda de Google. |
| **Anuncios** | **Ninguno**, en ninguna plataforma (decisión de producto: público infantil). |

### Limitaciones asumidas a cambio de no tener servidor

Son conscientes y aceptables para un juego de cosméticos; están documentadas en
el código (`in_app_purchase_store_repository.dart`):

- **Sin validación de recibos en servidor.** El beneficio se concede en el
  cliente cuando Google confirma la compra. Un dispositivo manipulado podría
  autoconcederse gemas; como no hay ranking en línea, no perjudica a nadie más.
- **La suscripción VIP no controla el vencimiento.** Se activa al comprar o
  restaurar; si el usuario cancela, el VIP sigue activo en ese dispositivo.
  Rastrear la caducidad exige la Play Developer API → post-MVP.
- **El progreso no se sincroniza entre dispositivos** ni sobrevive a un borrado
  de datos. Las compras no consumibles se recuperan con **"Restaurar compras"**;
  las gemas ya gastadas, no.

### Qué haría falta el día que se quiera un backend

Nada de esto está construido ni empezado, y **no hace falta para lanzar**. El
diseño está guardado en [`docs/BACKEND-PAGOS.md`](docs/BACKEND-PAGOS.md)
(marcado como post-MVP): validación de recibos server-to-server, entitlements
como fuente de verdad, webhooks de reembolso, ranking global y analítica
agregada. La arquitectura ya lo permite sin tocar la UI: cada servicio externo
está detrás de una interfaz y se cambia en `core/di/injection.dart`.

---

## Características

| Módulo | Descripción |
|--------|-------------|
| 🏠 **Home** | Pantalla de inicio enfocada en la carrera; el CTA dominante es "¡JUGAR!" y el editor queda como acción secundaria. |
| 🎨 **Editor de personajes** | Piel, ojos, boca, cejas, extras faciales, peinado/casco/sombrero, torso, guantes, piernas, calzado, capa y 8 ranuras de accesorios. |
| 👥 **Presets** | Personajes precargados agrupados por colección (Ninjas dorados, Superhéroes, Heroínas) que se cargan en el editor y se pueden modificar. |
| 🏃 **Endless Runner** | Motor Flame con perspectiva pseudo-3D, 3 carriles, salto y deslizamiento, 3 zonas de dificultad progresiva y escenografía lateral por mundo. |
| 👹 **Peleas contra jefes** | Al final de cada mundo aparece un jefe temático con 3 corazones; se le vence esquivando ataques y embistiendo. |
| 💰 **Economía** | Monedas, ruleta diaria, cofres común/VIP, desbloqueo de piezas por rareza y **billetera** (resumen ganado/gastado/saldo, al tocar las monedas). |
| 🎯 **Misiones** | 3 misiones activas rotativas; al completarse pagan monedas y regalan una gema. |
| 🏆 **Ranking** | Tabla de puntuaciones local por mundo. |
| 🔊 **Audio** | Efectos de sonido (salto, moneda, golpe, power-up, ruleta, cofre) y **música de fondo** en bucle seleccionable por personaje. |
| 🌍 **Mundos** | 8 mundos temáticos con paletas y jefes propios (2 disponibles, resto bloqueados). |
| 💎 **Monetización** | Compras opcionales con dinero real: gemas (consumible), pack cosmético (no consumible) y suscripción **Club VIP**. Sin anuncios, sin cajas de botín y sin azar: precios deterministas y compuerta parental antes de comprar. Ver [`docs/COMPRAS_REALES.md`](docs/COMPRAS_REALES.md). |
| 📈 **Analítica** | *First-party* y **local** (Hive): sesiones, días activos, retención D1/D7 y eventos. Sin SDK de terceros y sin salir del dispositivo, por el requisito de iOS Kids. |

> **Nota sobre el cobro real:** en web la tienda es **simulada** (`StubStoreRepository`),
> así que en la demo nadie paga nada. El cobro real (`InAppPurchaseStoreRepository`)
> se activa solo en Android e iOS, y requiere proyecto nativo y los productos dados
> de alta en las consolas.

---

## Stack técnico

- **Flutter** `>=3.0.0 <4.0.0` (Dart 3) — verificado con **Flutter 3.44.8 / Dart 3.12.2**
- **[Flame](https://flame-engine.org/) 1.18** — motor de juego 2D
- **[flutter_bloc](https://bloclibrary.dev/) 8.x** + **equatable** — gestión de estado (patrón BLoC)
- **[Hive](https://docs.hivedb.dev/) 2.2** — persistencia local (NoSQL clave-valor)
- **[go_router](https://pub.dev/packages/go_router) 14** — navegación declarativa
- **[get_it](https://pub.dev/packages/get_it) 8** — inyección de dependencias (service locator)
- **[audioplayers](https://pub.dev/packages/audioplayers) 6** — reproducción de audio
- **[in_app_purchase](https://pub.dev/packages/in_app_purchase) 3.2** — Google Play Billing / StoreKit
- **uuid** — generación de identificadores

> Sin dependencias de red: no hay cliente HTTP ni SDKs de analítica/publicidad.

> ⚠️ Los `TypeAdapter` de Hive (`*.g.dart`) están **escritos a mano**. No se usan `hive_generator` ni `build_runner`; si añades campos persistidos, actualiza el adapter manualmente. Los valores nuevos de un `enum` persistido se **añaden al final** (Hive guarda el índice).

---

## Puesta en marcha

### Requisitos

- Flutter SDK instalado (`flutter doctor` sin errores bloqueantes)
- Para Android: **Android SDK** (compileSdk 36) y **JDK 17+**
- Un dispositivo/emulador, o Chrome para la demo web

### Comandos

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en desarrollo
flutter run                 # dispositivo/emulador Android
flutter run -d chrome       # demo web (compras simuladas)

# Pruebas y lints
flutter test
flutter analyze

# Build de la demo web (base-href = ruta del repo en GitHub Pages)
flutter build web --release --base-href "/lego-custom-character/"
```

> Los directorios de sprites bajo `assets/sprites/**` pueden estar vacíos: el juego dibuja personajes, mundos y jefes por código (formas y colores), no con imágenes. El CI crea esos directorios vacíos antes de compilar. Los efectos de sonido viven en `assets/audio/` y la música en `assets/audio/music/`.

---

## Compilar para Google Play

La carpeta `android/` ya está en el repositorio y configurada:

| Ajuste | Valor |
|--------|-------|
| **applicationId** | `com.iron_coding.runforwin` — **no se puede cambiar** una vez publicada la app |
| **Nombre visible** | Run For Win |
| **Orientación** | Vertical fija (el runner está diseñado en vertical) |
| **compileSdk / targetSdk** | 36 (por defecto de Flutter) · **minSdk** 24 |
| **Icono** | Icono clásico + **adaptativo** (Android 8+) y splash azul Brix. Se generan por código: `flutter test tool/gen_icon.dart` |
| **versionName / versionCode** | Salen de `version:` en `pubspec.yaml` (`1.0.0+1` → `1.0.0` / `1`). **Sube el número tras el `+` en cada envío.** |

### Firma de release (una sola vez)

```bash
# 1. Genera el almacén de claves y guárdalo FUERA del repo, con copia de seguridad.
#    Si lo pierdes, no podrás volver a actualizar la app en Play.
keytool -genkey -v -keystore ~/run-for-win-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Copia la plantilla y rellena las credenciales
cp android/key.properties.example android/key.properties
```

`android/key.properties` y cualquier `*.jks` están en `.gitignore`: **nunca se
suben al repositorio**. Si el archivo no existe, la build de release se firma con
las claves de depuración para poder probar en local — ese artefacto **no sirve
para Play**.

### Generar el artefacto

```bash
# App Bundle firmado (lo que se sube a Play Console)
flutter build appbundle --release

# APK para probar en un dispositivo real
flutter build apk --release
```

#### Modo de prueba y builds de release

El **modo de prueba** (`core/test_mode/test_mode.dart`) desbloquea todo el
contenido de pago gratis, así que en release queda **inerte por defecto**: el
AAB que se sube a Play **no** permite activarlo (un usuario real no debe saltarse
las compras). Sigue funcionando en debug/profile. Para probarlo en un **release
firmado en tu dispositivo**, recompila pasando el flag:

```bash
flutter build apk --release --dart-define=BRIX_TESTMODE=true
```

⚠️ **Nunca** pases ese flag en la build que subes a Play Console.

### Pendiente antes de enviar a revisión

Lo que falta **no es código de la app**; está detallado en
[`docs/publicacion/CHECKLIST-PUBLICACION.md`](docs/publicacion/CHECKLIST-PUBLICACION.md):

1. **Dar de alta los productos IAP** en Play Console con los IDs exactos del
   catálogo (ver más abajo).
2. **Política de privacidad en una URL pública** + formulario de **Data Safety**
   (borradores en `docs/publicacion/`).
3. **Diseñado para familias** y clasificación por edad (IARC).
4. **Rediseño del _trade dress_** (aspecto de la minifigura) — es el riesgo de
   propiedad intelectual señalado en las docs.

---

## Monetización (IAP)

- **Solo compras integradas, sin anuncios.** Público infantil: compuerta
  parental (`ParentalGate`) antes de cada pago, sin cajas de botín con dinero
  real y sin pago-para-ganar.
- **En móvil** se registra `InAppPurchaseStoreRepository` (Google Play Billing).
  **En la demo web**, `StubStoreRepository` (simulada). Ese cambio es
  automático por plataforma en `core/di/injection.dart`.
- Los IDs del catálogo (`features/monetization/domain/entities/store_product.dart`)
  **deben existir igual** en Play Console:

| ID | Tipo | Qué entrega |
|----|------|-------------|
| `bundle_starter` | No consumible | Pack de bienvenida: skin exclusivo + 150 💎 + 1000 🪙 |
| `vip_monthly` | Suscripción | Club VIP: 25 💎/día + monedas ×1.5 |
| `vip_yearly` | Suscripción | Club VIP anual (~50% de ahorro) |
| `gems_small` | Consumible | 200 gemas |
| `gems_medium` | Consumible | 550 gemas |
| `gems_large` | Consumible | 1200 gemas |

Si un ID no existe en la consola, la compra devuelve "producto no encontrado"
en lugar de romper la app. Detalles de la economía en
[`docs/MONETIZACION.md`](docs/MONETIZACION.md).

---

## Estructura del proyecto

El código sigue **Clean Architecture** organizada por *features*. Cada feature tiene sus tres capas (`domain`, `data`, `presentation`):

```
lib/
├── main.dart                     # Punto de entrada, MultiBlocProvider raíz
├── core/                         # Infra transversal
│   ├── di/injection.dart         # get_it: dependencias, cajas Hive, stub vs IAP real
│   ├── router/app_router.dart    # go_router: rutas de la app
│   ├── l10n/                     # Traducciones (6 idiomas)
│   ├── theme/app_theme.dart      # Tema claro/oscuro (amarillo + azul Brix)
│   ├── services/audio_service.dart
│   └── error/failures.dart
└── features/
    ├── home/                     # Pantalla de inicio (CTA de carrera)
    ├── character_editor/         # Crear/editar/guardar personajes + presets
    ├── economy/                  # Monedas, ruleta, cofres, tienda de piezas
    ├── missions/                 # Misiones activas y progreso
    ├── monetization/             # Tienda IAP, gemas, VIP, compuerta parental
    ├── analytics/                # Analítica first-party local
    ├── ranking/                  # Puntuaciones por mundo (local)
    └── runner/                   # El juego (motor Flame + jefes + páginas)
```

Detalle de las capas en cada feature:

```
feature/
├── domain/            # Reglas de negocio puras (sin Flutter/Hive)
│   ├── entities/      # Modelos de dominio (Equatable)
│   ├── repositories/  # Contratos (interfaces abstractas)
│   └── usecases/      # Casos de uso de una sola responsabilidad
├── data/              # Implementaciones concretas
│   ├── models/        # Modelos Hive (*.dart) + adapters a mano (*.g.dart)
│   ├── datasources/   # Acceso a cajas Hive
│   └── repositories/  # Implementan los contratos de domain
└── presentation/      # UI
    ├── bloc/          # BLoC/Cubit (event/state)
    ├── pages/         # Pantallas
    ├── widgets/       # Widgets reutilizables
    └── game/          # (solo runner) componentes Flame
```

---

## Documentación

| Documento | Contenido |
|-----------|-----------|
| [`docs/ESTADO-PROYECTO.md`](docs/ESTADO-PROYECTO.md) | Estado, decisiones firmes y pendientes. **Leer al empezar una sesión.** |
| [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md) | Clean Architecture, capas, DI, persistencia Hive, navegación y flujo de estado. |
| [`docs/JUGABILIDAD.md`](docs/JUGABILIDAD.md) | Mecánicas del runner: perspectiva, zonas, colisiones, puntuación, power-ups, economía, ruleta, cofres y misiones. |
| [`docs/MONETIZACION.md`](docs/MONETIZACION.md) | Economía, gemas, VIP y desbloqueo de mundos. |
| [`docs/DESARROLLO.md`](docs/DESARROLLO.md) | Guía para contribuir: cómo añadir features, adapters Hive a mano, convenciones y pruebas. |
| [`docs/publicacion/`](docs/publicacion/) | Checklist de publicación, ficha de tienda, política de privacidad, términos, respuestas a los formularios y el **icono 512²** para Play. |
| [`docs/BACKEND-PAGOS.md`](docs/BACKEND-PAGOS.md) | **Post-MVP.** Diseño de un backend de validación de recibos. No aplica a esta versión. |

---

## Flujo de trabajo Git

**Nunca se hace push directo a `main`.** Todo cambio pasa por rama feature y Pull Request:

1. Desarrollar en la rama feature.
2. `git push origin <rama-feature>`.
3. Abrir el Pull Request (base: `main`).
4. El usuario revisa y mergea — el asistente **nunca** mergea de forma autónoma.
5. Tras el merge, el CI despliega automáticamente la demo web a GitHub Pages.

Consulta [`CLAUDE.md`](CLAUDE.md) para las instrucciones de proyecto que sigue Claude Code.

---

## Despliegue de la demo web

La web es un **escaparate**, no el producto: sirve para mostrar el juego sin
instalar nada, y ahí las compras son simuladas.

- Workflow: [`.github/workflows/deploy-web.yml`](.github/workflows/deploy-web.yml)
- El **build** corre en `main`, en ramas feature listadas y en Pull Requests.
- El **deploy** ocurre **solo** en push a `main`, usando [`peaceiris/actions-gh-pages@v4`](https://github.com/peaceiris/actions-gh-pages) → rama `gh-pages`.
- URL publicada: https://yesithv.github.io/lego-custom-character/

> **Configuración única en GitHub:** Settings → Pages → Source → **Deploy from a branch** → rama `gh-pages`, carpeta `/ (root)`.
