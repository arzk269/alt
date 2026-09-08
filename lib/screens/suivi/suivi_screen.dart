import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SuiviScreen extends StatelessWidget {
  const SuiviScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUIVI', style: monoStyle(size: 11)),
        const SizedBox(height: 6),
        const Text('Mes candidatures', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 24),
        const Text('Écran à construire au Sprint 5 : feed, statistiques, statut, historique.', style: TextStyle(color: AppColors.inkSoft)),
      ],
    );
  }
}
