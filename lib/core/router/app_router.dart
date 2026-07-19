import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/character_editor/domain/entities/character.dart';
import '../../features/character_editor/domain/entities/preset_characters.dart';
import '../../features/character_editor/presentation/pages/character_editor_page.dart';
import '../../features/character_editor/presentation/pages/character_gallery_page.dart';
import '../../features/character_editor/presentation/pages/preset_gallery_page.dart';
import '../../features/economy/presentation/pages/daily_roulette_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/monetization/presentation/pages/store_page.dart';
import '../../features/ranking/presentation/pages/ranking_page.dart';
import '../../features/runner/presentation/pages/pre_run_page.dart';
import '../../features/runner/presentation/pages/runner_page.dart';
import '../../features/runner/presentation/pages/world_selection_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const HomePage(),
    redirect: (context, state) {
      // extra is ephemeral and lost on browser refresh / direct URL access
      final needsExtra = ['/pre-run', '/runner'];
      if (needsExtra.contains(state.matchedLocation) && state.extra == null) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const CharacterGalleryPage(),
      ),
      GoRoute(
        path: '/editor',
        name: 'editor-new',
        builder: (context, state) =>
            CharacterEditorPage(preset: state.extra as PresetCharacter?),
      ),
      GoRoute(
        path: '/presets',
        name: 'presets',
        builder: (context, state) => const PresetGalleryPage(),
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
        path: '/store',
        name: 'store',
        builder: (context, state) => const StorePage(),
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
            worldName: extra['worldName'] as String,
            worldEmoji: extra['worldEmoji'] as String,
            worldColor: extra['worldColor'] as Color,
            musicAsset: extra['musicAsset'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/ranking/:worldId',
        name: 'ranking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RankingPage(
            worldId: state.pathParameters['worldId']!,
            worldName: extra['worldName'] as String,
            worldEmoji: extra['worldEmoji'] as String,
            worldColor: extra['worldColor'] as Color,
          );
        },
      ),
    ],
  );
}
