import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../../character_editor/presentation/widgets/character_preview.dart';
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
    return BlocProvider(
      create: (_) => sl<RankingBloc>()..add(LoadRanking(worldId)),
      child: _RankingView(worldId: worldId),
    );
  }
}

// Periodo del ranking (filtra por fecha de la puntuación).
enum _Period { semana, mes, global }

String _periodLabel(BuildContext context, _Period p) => switch (p) {
      _Period.semana => context.l10n.tr('period_week'),
      _Period.mes => context.l10n.tr('period_month'),
      _Period.global => context.l10n.tr('period_global'),
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
                    Text(
                      context.l10n.tr('ranking'),
                      style: const TextStyle(
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
                  worldName: context.l10n.worldName(_world.id),
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

                    return Column(
                      children: [
                        // Podio con cajitas, medallas y los personajes reales
                        // (1º, 2º y 3º) de este mundo.
                        _Podium(
                          scores: scores,
                          appearancesByName: state.appearancesByName,
                        ),
                        // Lista completa debajo del podio.
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.horizontal, 4, AppSpacing.horizontal,
                                20),
                            itemCount: scores.length,
                            itemBuilder: (context, i) {
                              final score = scores[i];
                              final rank = i + 1;
                              return _ScoreRow(
                                rank: rank,
                                score: score,
                              );
                            },
                          ),
                        ),
                      ],
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
                Text(
                  context.l10n.tr('world_label'),
                  style: const TextStyle(
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
                  _periodLabel(context, p),
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
              _periodLabel(context, period),
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
                context.l10n.worldName(world.id),
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

// ── Podio (top 3 con cajitas, medallas y personajes) ─────────────────────────

class _Podium extends StatelessWidget {
  final List<Score> scores;
  final Map<String, CharacterAppearance> appearancesByName;

  const _Podium({required this.scores, required this.appearancesByName});

  // Tamaño idéntico del personaje en los tres puestos (requisito): la jerarquía
  // la dan las cajitas, no la figura.
  static const double _figureSize = 74;

  @override
  Widget build(BuildContext context) {
    // scores[0..2] = 1º, 2º, 3º. El montaje visual es 2 · 1 · 3.
    final first = scores.isNotEmpty ? scores[0] : null;
    final second = scores.length > 1 ? scores[1] : null;
    final third = scores.length > 2 ? scores[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.horizontal, 0, AppSpacing.horizontal, 4),
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSpot(
              rank: 2,
              score: second,
              appearance:
                  second == null ? null : appearancesByName[second.characterName],
              figureSize: _figureSize,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PodiumSpot(
              rank: 1,
              score: first,
              appearance:
                  first == null ? null : appearancesByName[first.characterName],
              figureSize: _figureSize,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PodiumSpot(
              rank: 3,
              score: third,
              appearance:
                  third == null ? null : appearancesByName[third.characterName],
              figureSize: _figureSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  final int rank; // 1, 2 o 3
  final Score? score; // null → puesto vacío (aún no hay 2º/3º)
  final CharacterAppearance? appearance; // null → fallback de color
  final double figureSize;

  const _PodiumSpot({
    required this.rank,
    required this.score,
    required this.appearance,
    required this.figureSize,
  });

  static const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};

  // Altura de la cajita por puesto: 1º la más alta.
  static const _boxHeights = {1: 76.0, 2: 56.0, 3: 44.0};

  // Degradado de la cajita estilo podio (oro / plata / bronce).
  static const _boxGradients = {
    1: [Color(0xFFFFE24D), Color(0xFFE0A800)],
    2: [Color(0xFFE8EEF3), Color(0xFFAEB9C4)],
    3: [Color(0xFFF0B27A), Color(0xFFC77B3B)],
  };

  // Color del número sobre la cajita.
  static const _numberColors = {
    1: Color(0xFF7A5A00),
    2: Color(0xFF54626F),
    3: Color(0xFF7A461F),
  };

  // Fallback cuando no hay apariencia (personaje borrado/renombrado).
  static const _fallbackColors = {
    1: Color(0xFFFFD54F),
    2: Color(0xFF90A4AE),
    3: Color(0xFFC77B3B),
  };

  @override
  Widget build(BuildContext context) {
    final boxHeight = _boxHeights[rank]!;

    // Puesto vacío: solo la cajita, sin personaje ni nombre.
    if (score == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: figureSize * 1.6),
          _box(boxHeight),
        ],
      );
    }

    final name = score!.characterName.isEmpty
        ? context.l10n.tr('default_runner')
        : score!.characterName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nombre del personaje.
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: rank == 1 ? 13 : 12,
          ),
        ),
        const SizedBox(height: 2),
        // Medalla.
        Text(_medals[rank]!, style: const TextStyle(fontSize: 18)),
        // Personaje (mismo tamaño en los tres) apoyado sobre la cajita.
        RepaintBoundary(
          child: appearance != null
              ? CharacterPreview(appearance: appearance!, size: figureSize)
              : _fallbackFigure(),
        ),
        // Cajita numerada.
        _box(boxHeight),
      ],
    );
  }

  Widget _box(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _boxGradients[rank]!,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: _boxGradients[rank]![1].withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: _numberColors[rank]!,
            fontWeight: FontWeight.w900,
            fontSize: rank == 1 ? 34 : 28,
            shadows: const [
              Shadow(color: Colors.white54, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }

  // Silueta de respaldo: círculo de color con la inicial, con la misma altura
  // que ocuparía la figura para no descuadrar la fila.
  Widget _fallbackFigure() {
    final initial = (score!.characterName.isEmpty ? '?' : score!.characterName)
        .characters
        .first
        .toUpperCase();
    final color = _fallbackColors[rank]!;
    return SizedBox(
      height: figureSize * 1.6,
      child: Center(
        child: Container(
          width: figureSize * 0.66,
          height: figureSize * 0.66,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
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

  const _ScoreRow({
    required this.rank,
    required this.score,
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
    final highlighted = isChampion;
    final avatarColor = _avatarColors[(rank - 1) % _avatarColors.length];
    final name = score.characterName.isEmpty
        ? context.l10n.tr('default_runner')
        : score.characterName;

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
          // Nombre real del personaje
          Expanded(
            child: Text(
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
                  ? context.l10n.tr('ranking_empty_global')
                  : context.l10n.tr('ranking_empty_period'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.tr('ranking_empty_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
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
