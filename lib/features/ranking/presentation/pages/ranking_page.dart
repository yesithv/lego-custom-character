import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../character_editor/presentation/bloc/character_editor_bloc.dart';
import '../../../character_editor/presentation/bloc/character_editor_event.dart';
import '../../../runner/presentation/pages/world_selection_page.dart' show worlds, WorldData;
import '../../domain/entities/score.dart';
import '../bloc/ranking_bloc.dart';
import '../bloc/ranking_event.dart';
import '../bloc/ranking_state.dart';

class RankingPage extends StatelessWidget {
  final String worldId;
  final String worldName;
  final String worldEmoji;
  final Color worldColor;

  const RankingPage({
    super.key,
    required this.worldId,
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<RankingBloc>()..add(LoadRanking(worldId))),
        // Para identificar "Tú": el primer personaje es el corredor activo.
        BlocProvider(
          create: (_) => sl<CharacterEditorBloc>()..add(const LoadCharacters()),
        ),
      ],
      child: _RankingView(worldId: worldId),
    );
  }
}

// Periodo del ranking (filtra por fecha de la puntuación).
enum _Period { semana, mes, global }

String _periodLabel(_Period p) => switch (p) {
      _Period.semana => 'Semana',
      _Period.mes => 'Mes',
      _Period.global => 'Global',
    };

class _RankingView extends StatefulWidget {
  final String worldId;

  const _RankingView({required this.worldId});

  @override
  State<_RankingView> createState() => _RankingViewState();
}

class _RankingViewState extends State<_RankingView> {
  _Period _period = _Period.semana;
  late String _selectedWorldId;

  @override
  void initState() {
    super.initState();
    _selectedWorldId = widget.worldId;
  }

  WorldData get _world => worlds.firstWhere(
        (w) => w.id == _selectedWorldId,
        orElse: () => worlds.first,
      );

  void _selectWorld(BuildContext context, String worldId) {
    if (worldId == _selectedWorldId) return;
    setState(() => _selectedWorldId = worldId);
    context.read<RankingBloc>().add(LoadRanking(worldId));
  }

  List<Score> _applyPeriod(List<Score> scores) {
    if (_period == _Period.global) return scores;
    final days = _period == _Period.semana ? 7 : 30;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return scores.where((s) => s.createdAt.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Nombre del personaje activo del jugador → fila "Tú".
    final editorState = context.watch<CharacterEditorBloc>().state;
    final activeName = editorState.characters.isNotEmpty
        ? editorState.characters.first.name
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121A2E), Color(0xFF0A0E1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.horizontal, 12, AppSpacing.horizontal, 8),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.goNamed('home'),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Ranking',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),

              // Banner del mundo + selector de periodo
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.horizontal, 4, AppSpacing.horizontal, 12),
                child: _WorldBanner(
                  worldName: _world.name,
                  worldEmoji: _world.emoji,
                  worldColor: _world.color,
                  period: _period,
                  onPeriodChanged: (p) => setState(() => _period = p),
                ),
              ),

              // Chips para cambiar de mundo (evita una pantalla extra)
              _WorldChips(
                selectedId: _selectedWorldId,
                onSelect: (id) => _selectWorld(context, id),
              ),
              const SizedBox(height: 12),

              // Lista
              Expanded(
                child: BlocBuilder<RankingBloc, RankingState>(
                  builder: (context, state) {
                    if (state.status == RankingStatus.loading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final scores = _applyPeriod(state.scores);

                    if (scores.isEmpty) {
                      return _EmptyState(period: _period);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.horizontal, 0, AppSpacing.horizontal, 20),
                      itemCount: scores.length,
                      itemBuilder: (context, i) {
                        final score = scores[i];
                        final rank = i + 1;
                        final isYou = activeName != null &&
                            activeName.isNotEmpty &&
                            score.characterName == activeName;
                        return _ScoreRow(
                          rank: rank,
                          score: score,
                          isYou: isYou,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── World banner ─────────────────────────────────────────────────────────────

class _WorldBanner extends StatelessWidget {
  final String worldName;
  final String worldEmoji;
  final Color worldColor;
  final _Period period;
  final ValueChanged<_Period> onPeriodChanged;

  const _WorldBanner({
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lighter = Color.lerp(worldColor, Colors.white, 0.18)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lighter, worldColor],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: worldColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono del mundo
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(worldEmoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MUNDO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  worldName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PeriodDropdown(period: period, onChanged: onPeriodChanged),
        ],
      ),
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onChanged;

  const _PeriodDropdown({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Period>(
      onSelected: onChanged,
      color: const Color(0xFF1A2236),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => _Period.values
          .map((p) => PopupMenuItem<_Period>(
                value: p,
                child: Text(
                  _periodLabel(p),
                  style: TextStyle(
                    color: p == period ? const Color(0xFFFFD700) : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _periodLabel(period),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── World chips ──────────────────────────────────────────────────────────────

class _WorldChips extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _WorldChips({required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontal),
        itemCount: worlds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final world = worlds[i];
          final selected = world.id == selectedId;
          return _WorldChip(
            world: world,
            selected: selected,
            onTap: () => onSelect(world.id),
          );
        },
      ),
    );
  }
}

class _WorldChip extends StatelessWidget {
  final WorldData world;
  final bool selected;
  final VoidCallback onTap;

  const _WorldChip({
    required this.world,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFFFD700)
          : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFFC99700) : Colors.white24,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(world.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                world.name,
                style: TextStyle(
                  color: selected ? const Color(0xFF3D2C00) : Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score row ────────────────────────────────────────────────────────────────

class _ScoreRow extends StatelessWidget {
  final int rank;
  final Score score;
  final bool isYou;

  const _ScoreRow({
    required this.rank,
    required this.score,
    required this.isYou,
  });

  static const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};

  static const _avatarColors = [
    Color(0xFF9C27B0), // morado
    Color(0xFF2196F3), // azul
    Color(0xFF43A047), // verde
    Color(0xFFFB8C00), // naranja
    Color(0xFFE53935), // rojo
    Color(0xFF90A4AE), // gris
    Color(0xFF26A69A), // teal
  ];

  @override
  Widget build(BuildContext context) {
    final isChampion = rank == 1;
    final highlighted = isChampion || isYou;
    final avatarColor = _avatarColors[(rank - 1) % _avatarColors.length];
    final name = score.characterName.isEmpty ? 'Corredor' : score.characterName;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFFFD700).withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFFFD700)
              : Colors.white.withValues(alpha: 0.08),
          width: highlighted ? 2 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rango (medalla o número)
          SizedBox(
            width: 30,
            child: _medals.containsKey(rank)
                ? Text(_medals[rank]!, style: const TextStyle(fontSize: 22))
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // Avatar de color
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Nombre (o "Tú (nombre)")
          Expanded(
            child: isYou
                ? RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Tú ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: '($name)',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          // Puntaje
          Text(
            _formatNumber(score.score),
            style: TextStyle(
              color: isChampion ? const Color(0xFFFFD700) : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Period period;
  const _EmptyState({required this.period});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.horizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              period == _Period.global
                  ? '¡Sé el primero en correr aquí!'
                  : 'Sin marcas en este periodo',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Corre en este mundo para entrar al ranking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared bits ──────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Formatea un entero con separador de miles (24580 → "24,580").
String _formatNumber(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
