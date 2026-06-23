import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/character_editor/domain/entities/character.dart';
import '../../features/character_editor/presentation/pages/character_editor_page.dart';
import '../../features/character_editor/presentation/pages/character_gallery_page.dart';
import '../../features/economy/presentation/pages/daily_roulette_page.dart';
import '../../features/runner/presentation/pages/pre_run_page.dart';
import '../../features/runner/presentation/pages/runner_page.dart';
import '../../features/runner/presentation/pages/world_selection_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/gallery',
    routes: [
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const CharacterGalleryPage(),
      ),
      GoRoute(
        path: '/editor',
        name: 'editor-new',
        builder: (context, state) => const CharacterEditorPage(),
      ),
      GoRoute(
        path: '/editor/:id',
        name: 'editor-edit',
        builder: (context, state) =>
            CharacterEditorPage(characterId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/worlds',
        name: 'worlds',
        builder: (context, state) => const WorldSelectionPage(),
      ),
      GoRoute(
        path: '/roulette',
        name: 'roulette',
        builder: (context, state) => const DailyRoulettePage(),
      ),
      GoRoute(
        path: '/pre-run',
        name: 'pre-run',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PreRunPage(
            character: extra['character'] as Character,
            worldId: extra['worldId'] as String,
            worldName: extra['worldName'] as String,
            worldEmoji: extra['worldEmoji'] as String,
            worldColor: extra['worldColor'] as Color,
          );
        },
      ),
      GoRoute(
        path: '/runner',
        name: 'runner',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RunnerPage(
            character: extra['character'] as Character,
            worldId: extra['worldId'] as String,
          );
        },
      ),
    ],
  );
}
