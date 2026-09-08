import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CompletionGauge extends StatelessWidget {
  final int score;
  const CompletionGauge({super.key, required this.score});

  Color get _color {
    if (score >= 80) return AppColors.green;
    if (score >= 50) return AppColors.amber;
    return AppColors.brick;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 5,
                    backgroundColor: AppColors.line,
                    valueColor: AlwaysStoppedAnimation(_color),
                  ),
                ),
                Text('$score%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _color)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Complétude du profil', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  score >= 80
                      ? 'Ton profil est prêt à être utilisé pour matcher des offres.'
                      : 'Complète les sections ci-dessous pour un meilleur matching.',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
