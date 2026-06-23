import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/character_editor/presentation/pages/character_editor_page.dart';
import '../../features/character_editor/presentation/pages/character_gallery_page.dart';
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
    ],
  );
}
