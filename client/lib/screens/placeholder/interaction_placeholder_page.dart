import 'package:flutter/material.dart';

import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';

class InteractionPlaceholderCard extends StatelessWidget {
  const InteractionPlaceholderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GlowUpColors.lavender.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.favorite_outlined, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '“学生微光关怀”模块即将上线',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '预计推出：\n• 情绪热力图与心情签到\n• 两星一愿点评生成器\n• 家校沟通话术与提醒\n\n当前版本聚焦课堂演示，欢迎将体验反馈告诉我们。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: GlowUpColors.dusk.withValues(alpha: 0.75),
                ),
          ),
        ],
      ),
    );
  }
}
