import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/audio_service.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../../character_editor/presentation/widgets/character_preview.dart';
import '../../../missions/presentation/bloc/mission_bloc.dart';
import '../../../missions/presentation/bloc/mission_state.dart';
import '../../../missions/presentation/widgets/mission_card.dart';
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.worldColor,
              widget.worldColor.withValues(alpha: 0.7),
              Colors.black87
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar (fixed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      '${widget.worldEmoji}  ${widget.worldName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Character preview
                      CharacterPreview(
                          appearance: widget.character.appearance, size: 120),
                      const SizedBox(height: 8),
                      Text(
                        widget.character.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _CharacterTypeBadge(type: widget.character.type),

                      const SizedBox(height: 24),

                      // Missions panel
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: BlocBuilder<MissionBloc, MissionState>(
                          builder: (context, state) => Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🎯  Misiones activas',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (state.status == MissionStatus.loading)
                                  const Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  )
                                else
                                  ...state.missions.map((m) =>
                                      MissionCard(mission: m, compact: true)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Music panel
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _MusicPanel(
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
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Run button (always visible at bottom)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _startRun,
                    child: const Text(
                      '¡CORRER!',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '🎵  Música del mundo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                activeColor: const Color(0xFFFFD700),
                onChanged: onToggleEnabled,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 4),
            const Text(
              'Elige la pista que sonará mientras corres. Toca ▶ para escucharla.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 12),
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
                          ? const Color(0xFFFFD700).withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.06),
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
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.check_circle,
                                color: Color(0xFFFFD700), size: 20),
                          ),
                        GestureDetector(
                          onTap: () => onPreview(i),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isPlaying
                                  ? const Color(0xFFFFD700)
                                  : Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color:
                                  isPlaying ? Colors.black87 : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 4),
            const Text(
              'Correrás en silencio. Activa el interruptor para elegir una pista.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ],
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
    final (label, color) = _labels[type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
