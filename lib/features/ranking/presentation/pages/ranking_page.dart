import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
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
      child: _RankingView(
        worldName: worldName,
        worldEmoji: worldEmoji,
        worldColor: worldColor,
      ),
    );
  }
}

class _RankingView extends StatelessWidget {
  final String worldName;
  final String worldEmoji;
  final Color worldColor;

  const _RankingView({
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [worldColor, worldColor.withValues(alpha: 0.6), Colors.black87],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      '$worldEmoji  $worldName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '🏆 Ranking',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: BlocBuilder<RankingBloc, RankingState>(
                  builder: (context, state) {
                    if (state.status == RankingStatus.loading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (state.scores.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🏁', style: TextStyle(fontSize: 64)),
                            SizedBox(height: 16),
                            Text(
                              '¡Sé el primero en correr aquí!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Podium (top 3)
                        if (state.scores.length >= 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _Podium(scores: state.scores.take(3).toList()),
                          ),
                        const SizedBox(height: 16),
                        // Ranks 4–10
                        if (state.scores.length > 3)
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: state.scores.length - 3,
                              itemBuilder: (context, i) => _ScoreRow(
                                rank: i + 4,
                                score: state.scores[i + 3],
                              ),
                            ),
                          )
                        else
                          const Spacer(),
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

class _Podium extends StatelessWidget {
  final List<Score> scores;
  const _Podium({required this.scores});

  @override
  Widget build(BuildContext context) {
    // Layout: 2nd (left) — 1st (center, taller) — 3rd (right)
    final first = scores[0];
    final second = scores.length > 1 ? scores[1] : null;
    final third = scores.length > 2 ? scores[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: second != null ? _PodiumSlot(rank: 2, score: second, height: 90) : const SizedBox()),
        Expanded(child: _PodiumSlot(rank: 1, score: first, height: 120)),
        Expanded(child: third != null ? _PodiumSlot(rank: 3, score: third, height: 70) : const SizedBox()),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final int rank;
  final Score score;
  final double height;

  const _PodiumSlot({required this.rank, required this.score, required this.height});

  static const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};
  static const _colors = {
    1: Color(0xFFFFD700),
    2: Color(0xFFB0BEC5),
    3: Color(0xFFBF8970),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[rank]!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(_medals[rank]!, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          score.characterName.isEmpty ? '—' : score.characterName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '${score.score} pts',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(top: BorderSide(color: color, width: 2)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int rank;
  final Score score;

  const _ScoreRow({required this.rank, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              score.characterName.isEmpty ? '—' : score.characterName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.score} pts',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                '${score.meters}m · 🪙${score.coins}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
