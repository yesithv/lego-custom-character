import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../../character_editor/presentation/bloc/character_editor_bloc.dart';
import '../../../character_editor/presentation/bloc/character_editor_event.dart';
import '../../../character_editor/presentation/bloc/character_editor_state.dart';
import '../../../character_editor/presentation/widgets/character_preview.dart';
import '../../../economy/presentation/bloc/wallet_bloc.dart';
import '../../../economy/presentation/bloc/wallet_state.dart';
import '../../../economy/presentation/widgets/coin_balance_chip.dart';

/// Pantalla principal enfocada en la carrera: el CTA dominante es "¡JUGAR!",
/// y el editor de personajes queda como acción secundaria.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CharacterEditorBloc>()..add(const LoadCharacters()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0055A5), Color(0xFF002B55), Colors.black87],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Barra superior: monedas + ruleta diaria
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const CoinBalanceChip(),
                      const Spacer(),
                      _RouletteButton(),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                // Título
                const Text('🏁', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                const Text(
                  'Run For Win',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 44,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '¡Corre, esquiva y llega más lejos!',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const Spacer(flex: 2),

                // Corredor activo
                const _ActiveCharacterCard(),
                const Spacer(flex: 3),

                // CTA principal: correr
                SizedBox(
                  width: double.infinity,
                  height: 68,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black87,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => context.goNamed('worlds'),
                    icon: const Icon(Icons.play_arrow_rounded, size: 34),
                    label: const Text(
                      '¡JUGAR!',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Acción secundaria: gestionar personajes
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => context.goNamed('gallery'),
                    icon: const Icon(Icons.face_retouching_natural, size: 20),
                    label: const Text(
                      'Mis personajes',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouletteButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) => Stack(
        alignment: Alignment.topRight,
        children: [
          IconButton(
            icon: const Icon(Icons.casino_rounded, color: Colors.white),
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
    );
  }
}

class _ActiveCharacterCard extends StatelessWidget {
  const _ActiveCharacterCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharacterEditorBloc, CharacterEditorState>(
      builder: (context, state) {
        if (state.status == EditorStatus.loading) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          );
        }

        if (state.characters.isEmpty) {
          return _CardShell(
            onTap: () => context.goNamed('editor-new'),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🧱', style: TextStyle(fontSize: 40)),
                SizedBox(height: 8),
                Text(
                  'Crea tu corredor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Necesitas un personaje para correr',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final Character character = state.characters.first;
        return _CardShell(
          onTap: () => context.goNamed('gallery'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CharacterPreview(appearance: character.appearance, size: 90),
              const SizedBox(height: 6),
              Text(
                character.name.isEmpty ? 'Sin nombre' : character.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Toca para ver tus personajes',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _CardShell({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: child,
      ),
    );
  }
}
