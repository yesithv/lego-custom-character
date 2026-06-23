# BrixRun — Instrucciones de proyecto para Claude Code

## Flujo de trabajo Git

**Después de cada `git push` a una rama de feature, crear automáticamente un Pull Request.**

- Usar las herramientas GitHub MCP (`mcp__github__create_pull_request`) para abrir el PR.
- El PR apunta siempre a `main` como base.
- El usuario se encarga del merge; Claude no hace merge nunca de forma autónoma.
- Incluir en el cuerpo del PR un resumen de los cambios y un checklist de pruebas.

## Rama de desarrollo activa

`claude/flutter-hello-world-6u87go` → base: `main`

## Stack técnico

- Flutter 3.44+ / Dart 3.12+ con Flame 1.18.0
- BLoC pattern (`flutter_bloc ^8.x`) + Hive para persistencia local
- TypeAdapters de Hive escritos a mano — **no usar `hive_generator` ni `build_runner`**
- GitHub Pages vía GitHub Actions (`subosito/flutter-action@v2`)
- Build web: `flutter build web --release --base-href "/lego-custom-character/"`
