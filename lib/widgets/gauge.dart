import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Gauge extends StatelessWidget {
  final int score;
  const Gauge({super.key, required this.score});

  static const int seuil = 75;

  @override
  Widget build(BuildContext context) {
    final enDessous = score < seuil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(text: '$score', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.ink)),
                TextSpan(text: '/100', style: TextStyle(fontSize: 16, color: AppColors.inkFaint, fontWeight: FontWeight.w500)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(100)),
              child: Text('seuil $seuil', style: monoStyle(size: 11, color: AppColors.amber)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 16,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 4,
                    child: Container(width: width, height: 8, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
                  ),
                  Positioned(
                    top: 4,
                    child: Container(
                      width: width * (score.clamp(0, 100) / 100),
                      height: 8,
                      decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Positioned(
                    left: (width * (seuil / 100) - 1).clamp(0, width),
                    top: 0,
                    child: Container(width: 2, height: 16, color: AppColors.amber),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('0', style: TextStyle(fontSize: 10)),
            Text('25', style: TextStyle(fontSize: 10)),
            Text('50', style: TextStyle(fontSize: 10)),
            Text('75', style: TextStyle(fontSize: 10)),
            Text('100', style: TextStyle(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          enDessous
              ? "Sous le seuil de $seuil : le profil et l'offre partagent peu de points communs, la candidature reste possible mais moins ciblée."
              : "Au-dessus du seuil de $seuil : les compétences et expériences détectées correspondent bien aux exigences de l'offre.",
          style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.4),
        ),
      ],
    );
  }
}
