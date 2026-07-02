import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.playerName,
    required this.points,
    this.rank = 1,
  });

  final String playerName;
  final int points;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.lightBlue,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'النقاط: $points',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
