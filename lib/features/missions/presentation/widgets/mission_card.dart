import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/mission.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final bool compact;

  const MissionCard({super.key, required this.mission, this.compact = false});

  String get _icon {
    if (mission.type == MissionType.collectCoins) return '🪙';
    if (mission.type == MissionType.runMeters) return '🏃';
    if (mission.type == MissionType.evadeObstacles) return '⚡';
    if (mission.type == MissionType.surviveSeconds) return '⏱';
    return '🦘';
  }

  @override
  Widget build(BuildContext context) {
    final done = mission.isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: done
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? Colors.green.shade400 : Colors.white24,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.missionTitle(mission),
                  style: TextStyle(
                    color: done ? Colors.green.shade300 : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
              ),
              if (done)
                const Icon(Icons.check_circle, color: Colors.green, size: 16)
              else
                Text(
                  '🪙 ${mission.rewardCoins}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.missionDescription(mission),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
          const SizedBox(height: 6),
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
          if (!compact) ...[
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${mission.progress.clamp(0, mission.target)} / ${mission.target}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
