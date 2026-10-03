import 'package:flutter/material.dart';
import '../models/candidature.dart';
import '../theme/app_theme.dart';

class StatusMeta {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const StatusMeta(this.label, this.icon, this.color, this.bg);
}

const Map<StatutCandidature, StatusMeta> statusMetaMap = {
  StatutCandidature.aPostuler: StatusMeta('À postuler', Icons.schedule, AppColors.blue, AppColors.blueSoft),
  StatutCandidature.envoyee: StatusMeta('Envoyée', Icons.mail_outline, AppColors.inkSoft, AppColors.bg),
  StatutCandidature.relance: StatusMeta('Relance', Icons.notifications_active_outlined, AppColors.amber, AppColors.amberSoft),
  StatutCandidature.entretien: StatusMeta('Entretien', Icons.check_circle_outline, AppColors.green, AppColors.greenSoft),
  StatutCandidature.refus: StatusMeta('Refus', Icons.cancel_outlined, AppColors.brick, AppColors.brickSoft),
};

class StatusPill extends StatelessWidget {
  final StatutCandidature statut;
  const StatusPill({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    final meta = statusMetaMap[statut]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: meta.bg, borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(meta.icon, size: 12, color: meta.color),
        const SizedBox(width: 5),
        Text(meta.label, style: monoStyle(size: 11.5, color: meta.color, weight: FontWeight.w600)),
      ]),
    );
  }
}
