import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../economy/presentation/bloc/wallet_bloc.dart';
import '../../../economy/presentation/bloc/wallet_state.dart';
import '../../../economy/presentation/widgets/coin_balance_chip.dart';
import '../bloc/character_editor_bloc.dart';
import '../bloc/character_editor_event.dart';
import '../bloc/character_editor_state.dart';
import '../widgets/character_preview.dart';

class CharacterGalleryPage extends StatelessWidget {
  const CharacterGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CharacterEditorBloc>()..add(const LoadCharacters()),
      child: const _GalleryView(),
    );
  }
}

class _GalleryView extends StatelessWidget {
  const _GalleryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        title: const Text(
          'BrixRun',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            color: Colors.black87,
          ),
        ),
        actions: [
          // Coin balance
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Center(child: CoinBalanceChip()),
          ),
          // Ruleta diaria
          BlocBuilder<WalletBloc, WalletState>(
            builder: (context, walletState) => Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.casino_rounded, color: Colors.black87),
                  tooltip: 'Ruleta diaria',
                  onPressed: () => context.goNamed('roulette'),
                ),
                if (walletState.wallet.canClaimRoulette)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sports_score_rounded, color: Colors.black87),
            tooltip: 'Mundos',
            onPressed: () => context.goNamed('worlds'),
          ),
        ],
      ),
      body: BlocBuilder<CharacterEditorBloc, CharacterEditorState>(
        builder: (context, state) {
          if (state.status == EditorStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.characters.isEmpty) {
            return _EmptyState(
              onCreateTap: () => _openNewEditor(context),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: state.characters.length,
            itemBuilder: (context, i) {
              final character = state.characters[i];
              return _CharacterCard(
                character: character,
                onTap: () => context.goNamed(
                  'editor-edit',
                  pathParameters: {'id': character.id},
                ),
                onDelete: () => context.read<CharacterEditorBloc>()
                    .add(DeleteCharacterById(character.id)),
                onDuplicate: () => context.read<CharacterEditorBloc>()
                    .add(DuplicateCharacter(character.id)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewEditor(context),
        backgroundColor: const Color(0xFFFFD700),
        icon: const Icon(Icons.add, color: Colors.black87),
        label: const Text(
          'Nuevo',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _openNewEditor(BuildContext context) {
    context.read<CharacterEditorBloc>().add(const StartNewCharacter());
    context.goNamed('editor-new');
  }
}

class _CharacterCard extends StatelessWidget {
  final dynamic character;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _CharacterCard({
    required this.character,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                padding: const EdgeInsets.all(8),
                child: CharacterPreview(
                  appearance: character.appearance,
                  size: 100,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                character.name.isEmpty ? 'Sin nombre' : character.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: onDuplicate,
                  tooltip: 'Duplicar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            '¡Crea tu primer personaje!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Diseña tu minifigura y úsala en el runner.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add),
            label: const Text('Crear personaje'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black87,
              minimumSize: const Size(180, 52),
            ),
          ),
        ],
      ),
    );
  }
}
