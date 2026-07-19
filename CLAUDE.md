# Run For Win — Instrucciones de proyecto para Claude Code

## Contexto y decisiones (léelo al iniciar una sesión)

> Estado completo, arquitectura, lo construido y lo pendiente en
> **`docs/ESTADO-PROYECTO.md`**. Léelo antes de trabajar en monetización o
> economía. Resumen de decisiones **firmes**:

- **Público: niños (<13)** → COPPA / reglas Kids de las tiendas.
- **Marca:** producto **"Run For Win"**; estilo de bloques **"Brix"** (fuera de
  LEGO). Codename de código: `BrixRun`. Paquete Dart: `run_for_win`.
- **Objetivo:** publicar nativo en **iOS + Android** (la web es solo demo).
- **Monetización: solo IAP, SIN anuncios en ninguna plataforma.** Motor:
  cosméticos (IAP) + gemas + suscripción VIP. **No construir anuncios.**
- **Kids-safe:** compuerta parental antes de comprar; analítica **first-party**
  (sin SDK de terceros); sin loot boxes con dinero real; sin pay-to-win.
- **Patrón:** servicios externos detrás de interfaz + **stub** (Store, Analytics,
  Score); pasar a real = una línea en `core/di/injection.dart`.
- **Hive a mano**, `typeId` en uso 0–5, **próximo libre: 6**.

## Flujo de trabajo Git

**Siempre desarrollar en la rama feature. Nunca hacer push directo a main.**

1. Hacer todos los cambios en `claude/flutter-hello-world-6u87go`
2. Hacer `git push origin claude/flutter-hello-world-6u87go`
3. Crear el Pull Request con `mcp__github__create_pull_request` (base: `main`)
4. El usuario aprueba y mergea — Claude nunca mergea de forma autónoma
5. Tras el merge, el CI despliega automáticamente a GitHub Pages

## Rama de desarrollo activa

`claude/flutter-hello-world-6u87go` → base: `main`

## Deploy

- Deploy se activa **solo** en push a `main`
- Usa `peaceiris/actions-gh-pages@v4` → rama `gh-pages`
- URL: `https://yesithv.github.io/lego-custom-character/`

> **Configuración requerida en GitHub (una sola vez):**
> Settings → Pages → Source → **Deploy from a branch** → rama: `gh-pages`, carpeta: `/ (root)`

## Stack técnico

- Flutter 3.44+ / Dart 3.12+ con Flame 1.18.0
- BLoC pattern (`flutter_bloc ^8.x`) + Hive para persistencia local
- TypeAdapters de Hive escritos a mano — **no usar `hive_generator` ni `build_runner`**
- Audio: `audioplayers ^6.0.0`; archivos MP3 en `assets/audio/`
- Build web: `flutter build web --release --base-href "/lego-custom-character/"`
