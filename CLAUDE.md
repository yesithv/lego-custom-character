# BrixRun — Instrucciones de proyecto para Claude Code

## Flujo de trabajo Git

**Desarrollar y hacer push directamente en `main`.**

- No usar ramas de feature ni Pull Requests.
- Hacer commit y `git push origin main` después de cada cambio significativo.
- El deploy a GitHub Pages se dispara automáticamente en cada push a `main`.

## Rama de desarrollo activa

`main`

## Stack técnico

- Flutter 3.44+ / Dart 3.12+ con Flame 1.18.0
- BLoC pattern (`flutter_bloc ^8.x`) + Hive para persistencia local
- TypeAdapters de Hive escritos a mano — **no usar `hive_generator` ni `build_runner`**
- GitHub Pages vía GitHub Actions (`subosito/flutter-action@v2`)
- Build web: `flutter build web --release --base-href "/lego-custom-character/"`
- Audio: `audioplayers ^6.0.0`; archivos MP3 en `assets/audio/`
