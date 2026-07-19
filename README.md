# 🧱 Run For Win

> Creador de personajes de bloques **Brix** + Endless Runner pseudo-3D con jefes de mundo, hecho en Flutter + Flame.

> **Nota de nombres:** el nombre de producto (título de la app y UI) es **Run For Win**. **Brix** es la marca del estilo de bloques del juego (personajes, mundos). El **codename interno** del código sigue siendo **BrixRun** (clases `BrixRunApp`, `BrixRunGame`), y el paquete Dart es `lego_custom_character` (identificador interno heredado; pendiente de renombrar). En esta documentación se usa "Run For Win" para el producto y "BrixRun" cuando se hace referencia al código.

Run For Win combina dos experiencias en una sola app:

1. **Editor de personajes** — diseña una minifigura personalizable (cara, peinado/casco, torso, piernas, calzado, accesorios por ranura y música de partida). Puedes partir de **personajes precargados (presets)** y editarlos.
2. **Endless Runner** — corre con tu personaje por mundos temáticos en una vista pseudo-3D de 3 carriles al estilo Subway Surfers, esquivando obstáculos, recogiendo monedas, activando power-ups y, al final de cada mundo, enfrentándote a una **pelea contra el jefe**.

Alrededor de esos dos pilares hay una **economía de monedas** (ruleta diaria, cofres, tienda de piezas), un sistema de **misiones** y un **ranking** local por mundo.

🎮 **Demo web:** https://yesithv.github.io/lego-custom-character/

---

## Índice

- [Características](#características)
- [Stack técnico](#stack-técnico)
- [Puesta en marcha](#puesta-en-marcha)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Documentación](#documentación)
- [Flujo de trabajo Git](#flujo-de-trabajo-git)
- [Despliegue](#despliegue)

---

## Características

| Módulo | Descripción |
|--------|-------------|
| 🏠 **Home** | Pantalla de inicio enfocada en la carrera; el CTA dominante es "¡JUGAR!" y el editor queda como acción secundaria. |
| 🎨 **Editor de personajes** | Piel, ojos, boca, cejas, extras faciales, peinado/casco/sombrero, torso, guantes, piernas, calzado, capa, 8 ranuras de accesorios y pista de música. |
| 👥 **Presets** | Personajes precargados agrupados por colección (Ninjas dorados, Superhéroes…) que se cargan en el editor y se pueden modificar. |
| 🏃 **Endless Runner** | Motor Flame con perspectiva pseudo-3D, 3 carriles, salto y deslizamiento, 3 zonas de dificultad progresiva y escenografía lateral por mundo. |
| 👹 **Peleas contra jefes** | Al final de cada mundo aparece un jefe temático con 3 corazones; se le vence esquivando ataques y embistiendo. |
| 💰 **Economía** | Monedas, ruleta diaria, cofres común/VIP, desbloqueo de piezas por rareza. |
| 🎯 **Misiones** | 3 misiones activas rotativas con recompensas en monedas. |
| 🏆 **Ranking** | Tabla de puntuaciones local por mundo. |
| 🔊 **Audio** | Efectos de sonido (salto, moneda, golpe, power-up, ruleta, cofre) y **música de fondo** en bucle seleccionable por personaje. |
| 🌍 **Mundos** | 8 mundos temáticos con paletas y jefes propios (2 disponibles, resto bloqueados). |

---

## Stack técnico

- **Flutter** `>=3.0.0 <4.0.0` (Dart 3) — se recomienda Flutter 3.44+ / Dart 3.12+
- **[Flame](https://flame-engine.org/) 1.18** — motor de juego 2D
- **[flutter_bloc](https://bloclibrary.dev/) 8.x** + **equatable** — gestión de estado (patrón BLoC)
- **[Hive](https://docs.hivedb.dev/) 2.2** — persistencia local (NoSQL clave-valor)
- **[go_router](https://pub.dev/packages/go_router) 14** — navegación declarativa
- **[get_it](https://pub.dev/packages/get_it) 8** — inyección de dependencias (service locator)
- **[audioplayers](https://pub.dev/packages/audioplayers) 6** — reproducción de audio
- **uuid** — generación de identificadores

> ⚠️ Los `TypeAdapter` de Hive (`*.g.dart`) están **escritos a mano**. No se usan `hive_generator` ni `build_runner`; si añades campos persistidos, actualiza el adapter manualmente.

---

## Puesta en marcha

### Requisitos

- Flutter SDK instalado (`flutter doctor` sin errores bloqueantes)
- Un dispositivo/emulador, o Chrome para la versión web

### Comandos

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en desarrollo (elige dispositivo o usa Chrome)
flutter run
flutter run -d chrome

# Ejecutar las pruebas
flutter test

# Analizar el código (lints)
flutter analyze

# Build de producción para web (base-href = ruta del repo en GitHub Pages)
flutter build web --release --base-href "/lego-custom-character/"
```

> Los directorios de sprites bajo `assets/sprites/**` pueden estar vacíos: el juego dibuja los personajes, mundos y jefes por código (formas y colores), no con imágenes. El CI crea esos directorios vacíos antes de compilar. Los efectos de sonido viven en `assets/audio/` y las pistas de música en `assets/audio/music/`.

---

## Estructura del proyecto

El código sigue **Clean Architecture** organizada por *features*. Cada feature tiene sus tres capas (`domain`, `data`, `presentation`):

```
lib/
├── main.dart                     # Punto de entrada, MultiBlocProvider raíz
├── core/                         # Infra transversal
│   ├── di/injection.dart         # get_it: registro de dependencias y cajas Hive
│   ├── router/app_router.dart    # go_router: rutas de la app
│   ├── theme/app_theme.dart      # Tema claro/oscuro (amarillo + azul Brix)
│   ├── services/audio_service.dart
│   └── error/failures.dart
└── features/
    ├── home/                     # Pantalla de inicio (CTA de carrera)
    ├── character_editor/         # Crear/editar/guardar personajes + presets + música
    ├── economy/                  # Monedas, ruleta, cofres, tienda de piezas
    ├── missions/                 # Misiones activas y progreso
    ├── ranking/                  # Puntuaciones por mundo
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

Documentación interna detallada en la carpeta [`docs/`](docs/):

| Documento | Contenido |
|-----------|-----------|
| [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md) | Clean Architecture, capas, DI, persistencia Hive, navegación y flujo de estado. |
| [`docs/JUGABILIDAD.md`](docs/JUGABILIDAD.md) | Mecánicas del runner: perspectiva, zonas, colisiones, puntuación, power-ups, economía, ruleta, cofres y misiones. |
| [`docs/DESARROLLO.md`](docs/DESARROLLO.md) | Guía para contribuir: cómo añadir features, escribir adapters Hive a mano, convenciones y pruebas. |

---

## Flujo de trabajo Git

**Nunca se hace push directo a `main`.** Todo cambio pasa por rama feature y Pull Request:

1. Desarrollar en la rama feature.
2. `git push origin <rama-feature>`.
3. Abrir el Pull Request (base: `main`).
4. El usuario revisa y mergea — el asistente **nunca** mergea de forma autónoma.
5. Tras el merge, el CI despliega automáticamente a GitHub Pages.

Consulta [`CLAUDE.md`](CLAUDE.md) para las instrucciones de proyecto que sigue Claude Code.

---

## Despliegue

- Workflow: [`.github/workflows/deploy-web.yml`](.github/workflows/deploy-web.yml)
- El **build** corre en `main`, en ramas feature listadas y en Pull Requests.
- El **deploy** ocurre **solo** en push a `main`, usando [`peaceiris/actions-gh-pages@v4`](https://github.com/peaceiris/actions-gh-pages) → rama `gh-pages`.
- URL publicada: https://yesithv.github.io/lego-custom-character/

> **Configuración única en GitHub:** Settings → Pages → Source → **Deploy from a branch** → rama `gh-pages`, carpeta `/ (root)`.
