import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/preset_characters.dart';
import '../widgets/character_preview.dart';

/// Gallery of preconfigured ("precargados") characters grouped by collection.
/// Tapping one opens the editor pre-filled with that character's full
/// configuration, ready to be tweaked and saved.
class PresetGalleryPage extends StatelessWidget {
  const PresetGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        leading: BackButton(
          color: Colors.black87,
          onPressed: () => context.goNamed('gallery'),
        ),
        title: Text(
          context.l10n.tr('preset_characters'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.horizontal, 8, AppSpacing.horizontal, 4),
            child: Text(
              context.l10n.tr('preset_intro'),
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          for (final collection in presetCollections)
            _CollectionSection(collection: collection),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CollectionSection extends StatelessWidget {
  final String collection;
  const _CollectionSection({required this.collection});

  String _collectionLabel(BuildContext context) {
    switch (collection) {
      case 'Ninjas dorados':
        return context.l10n.tr('collection_golden_ninjas');
      case 'Superhéroes':
        return context.l10n.tr('collection_superheroes');
      default:
        return collection;
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = presetsForCollection(collection);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.horizontal, 16, AppSpacing.horizontal, 8),
          child: Text(
            _collectionLabel(context),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.horizontalOnly,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.62,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: presets.length,
          itemBuilder: (context, i) => _PresetCard(preset: presets[i]),
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  final PresetCharacter preset;
  const _PresetCard({required this.preset});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed('editor-new', extra: preset),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CharacterPreview(
                  appearance: preset.appearance,
                  size: 70,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Text(
                preset.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
