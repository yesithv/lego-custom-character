import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../../character_editor/presentation/widgets/character_preview.dart';
import '../../../missions/domain/entities/mission.dart';
import '../../../missions/presentation/bloc/mission_bloc.dart';
import '../../../missions/presentation/bloc/mission_state.dart';
import '../../domain/entities/world_music.dart';

class PreRunPage extends StatefulWidget {
  final Character character;
  final String worldId;
  final String worldName;
  final String worldEmoji;
  final Color worldColor;

  const PreRunPage({
    super.key,
    required this.character,
    required this.worldId,
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
  });

  @override
  State<PreRunPage> createState() => _PreRunPageState();
}

class _PreRunPageState extends State<PreRunPage> {
  late final List<WorldTrack> _tracks;

  /// Si el jugador quiere música de fondo en esta partida.
  bool _musicEnabled = true;

  /// Índice de la pista del mundo elegida para la partida.
  int _selectedTrack = 0;

  /// Índice de la pista que se está escuchando en la vista previa (si alguna).
  int? _previewing;

  @override
  void initState() {
    super.initState();
    _tracks = worldTracksFor(widget.worldId);
  }

  @override
  void dispose() {
    // Detiene cualquier vista previa al abandonar la pantalla previa.
    if (_previewing != null) AudioService.instance.stopMusic();
    super.dispose();
  }

  void _togglePreview(int index) {
    if (_previewing == index) {
      AudioService.instance.stopMusic();
      setState(() => _previewing = null);
    } else {
      AudioService.instance.playMusic(_tracks[index].asset);
      setState(() => _previewing = index);
    }
  }

  void _startRun() {
    final musicAsset =
        _musicEnabled && _tracks.isNotEmpty ? _tracks[_selectedTrack].asset : null;
    // Dejamos que el runner sea la única autoridad sobre la música: arrancará
    // la pista elegida (o la detendrá si no hay). Ponemos [_previewing] a null
    // para que el dispose de esta pantalla no corte la música recién iniciada.
    _previewing = null;
    context.goNamed(
      'runner',
      extra: {
        'character': widget.character,
        'worldId': widget.worldId,
        'worldName': widget.worldName,
        'worldEmoji': widget.worldEmoji,
        'worldColor': widget.worldColor,
        'musicAsset': musicAsset,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.worldColor;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(base, Colors.white, 0.12)!,
              base,
              Color.lerp(base, Colors.black, 0.5)!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar (fijo)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.horizontal, 10, AppSpacing.horizontal, 6),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed('worlds');
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(widget.worldEmoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.worldName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido desplazable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.horizontal),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Personaje con halo
                      _CharacterHero(character: widget.character),
                      const SizedBox(height: 8),
                      Text(
                        widget.character.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          shadows: [
                            Shadow(
                                color: Colors.black38,
                                blurRadius: 6,
                                offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CharacterTypeBadge(type: widget.character.type),

                      const SizedBox(height: 20),

                      // Misiones activas (en paralelo, compacto)
                      const _MissionsBanner(),

                      const SizedBox(height: 14),

                      // Música del mundo
                      _MusicPanel(
                        tracks: _tracks,
                        enabled: _musicEnabled,
                        selectedIndex: _selectedTrack,
                        previewingIndex: _previewing,
                        onToggleEnabled: (v) {
                          if (!v && _previewing != null) {
                            AudioService.instance.stopMusic();
                          }
                          setState(() {
                            _musicEnabled = v;
                            if (!v) _previewing = null;
                          });
                        },
                        onSelect: (i) => setState(() => _selectedTrack = i),
                        onPreview: _togglePreview,
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Botón correr (siempre visible)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.horizontal, 6, AppSpacing.horizontal, 16),
                child: _RunButton(onTap: _startRun),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Character hero (con halo) ────────────────────────────────────────────────

class _CharacterHero extends StatelessWidget {
  final Character character;
  const _CharacterHero({required this.character});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 175,
            height: 175,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x4DFFD700), Color(0x00FFD700)],
              ),
            ),
          ),
          CharacterPreview(appearance: character.appearance, size: 120),
        ],
      ),
    );
  }
}

// ── Missions banner (paralelo) ───────────────────────────────────────────────

class _MissionsBanner extends StatelessWidget {
  const _MissionsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯  ${context.l10n.tr('missions_active')}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<MissionBloc, MissionState>(
            builder: (context, state) {
              if (state.status == MissionStatus.loading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white54),
                    ),
                  ),
                );
              }
              if (state.missions.isEmpty) {
                return Text(
                  context.l10n.tr('no_active_missions'),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                );
              }
              // Cada misión en paralelo (columnas) para reducir la altura.
              final missions = state.missions;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < missions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _MissionMini(mission: missions[i])),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MissionMini extends StatelessWidget {
  final Mission mission;
  const _MissionMini({required this.mission});

  static String _emoji(MissionType type) => switch (type) {
        MissionType.collectCoins => '🪙',
        MissionType.runMeters => '🏃',
        MissionType.evadeObstacles => '⚡',
        MissionType.surviveSeconds => '⏱',
        MissionType.useJump => '🦘',
      };

  @override
  Widget build(BuildContext context) {
    final done = mission.isCompleted;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: done
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? Colors.green.shade400 : Colors.white12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_emoji(mission.type), style: const TextStyle(fontSize: 17)),
              if (done)
                const Icon(Icons.check_circle, color: Colors.green, size: 16)
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 2),
                    Text(
                      '${mission.rewardCoins}',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.missionTitle(mission),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: done ? Colors.green.shade300 : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: mission.progressRatio,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                done ? Colors.green : const Color(0xFFFFD700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Music panel ───────────────────────────────────────────────────────────────

class _MusicPanel extends StatelessWidget {
  final List<WorldTrack> tracks;
  final bool enabled;
  final int selectedIndex;
  final int? previewingIndex;
  final ValueChanged<bool> onToggleEnabled;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onPreview;

  const _MusicPanel({
    required this.tracks,
    required this.enabled,
    required this.selectedIndex,
    required this.previewingIndex,
    required this.onToggleEnabled,
    required this.onSelect,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🎵  ${context.l10n.tr('world_music')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: const Color(0xFFFFD700),
                onChanged: onToggleEnabled,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            ...List.generate(tracks.length, (i) {
              final track = tracks[i];
              final isSelected = i == selectedIndex;
              final isPlaying = i == previewingIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFD700).withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(track.emoji,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                track.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Control derecho: reproducir/detener; el elegido
                        // muestra un check dorado cuando no se está escuchando.
                        _TrackControl(
                          isSelected: isSelected,
                          isPlaying: isPlaying,
                          onTap: () => onPreview(i),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.tr('music_off_hint'),
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackControl extends StatelessWidget {
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;

  const _TrackControl({
    required this.isSelected,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color bg;
    final Color fg;
    if (isPlaying) {
      icon = Icons.stop_rounded;
      bg = const Color(0xFFFFD700);
      fg = const Color(0xFF3D2C00);
    } else if (isSelected) {
      icon = Icons.check_rounded;
      bg = const Color(0xFFFFD700);
      fg = const Color(0xFF3D2C00);
    } else {
      icon = Icons.play_arrow_rounded;
      bg = Colors.white24;
      fg = Colors.white;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: 22),
      ),
    );
  }
}

// ── Run button (efecto 3D) ───────────────────────────────────────────────────

class _RunButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RunButton({required this.onTap});

  @override
  State<_RunButton> createState() => _RunButtonState();
}

class _RunButtonState extends State<_RunButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final drop = _pressed ? 3.0 : 7.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: double.infinity,
        height: 64,
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE24D), Color(0xFFFFCE1F)],
          ),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFC99700),
                offset: Offset(0, drop),
                blurRadius: 0),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              offset: Offset(0, drop + 3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              context.l10n.tr('action_run'),
              style: const TextStyle(
                color: Color(0xFF3D2C00),
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 2,
              ),
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
      color: Colors.white.withValues(alpha: 0.12),
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

class _CharacterTypeBadge extends StatelessWidget {
  final CharacterType type;
  const _CharacterTypeBadge({required this.type});

  static const _labels = {
    CharacterType.hero: ('Héroe', Colors.blue),
    CharacterType.villain: ('Villano', Colors.red),
    CharacterType.neutral: ('Neutral', Colors.grey),
    CharacterType.mysterious: ('Misterioso', Colors.purple),
  };

  @override
  Widget build(BuildContext context) {
    final (_, color) = _labels[type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        context.l10n.characterType(type),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
