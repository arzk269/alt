import 'package:flutter/material.dart';
import '../models/candidature.dart';
import '../theme/app_theme.dart';

class EventMeta {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const EventMeta(this.label, this.icon, this.color, this.bg);
}

const Map<TypeEvenement, EventMeta> eventMetaMap = {
  TypeEvenement.ajoutee: EventMeta('Candidature ajoutée', Icons.add, AppColors.inkSoft, AppColors.bg),
  TypeEvenement.aPostuler: EventMeta('Remise à "à postuler"', Icons.schedule, AppColors.blue, AppColors.blueSoft),
  TypeEvenement.envoyee: EventMeta('Candidature envoyée', Icons.mail_outline, AppColors.inkSoft, AppColors.bg),
  TypeEvenement.relance: EventMeta('Relance envoyée', Icons.notifications_active_outlined, AppColors.amber, AppColors.amberSoft),
  TypeEvenement.entretien: EventMeta('Entretien', Icons.check_circle_outline, AppColors.green, AppColors.greenSoft),
  TypeEvenement.refus: EventMeta('Réponse négative', Icons.cancel_outlined, AppColors.brick, AppColors.brickSoft),
};

const _mois = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre'];

String formatDateEvenement(DateTime d) => '${d.day} ${_mois[d.month - 1]} ${d.year}';

class Timeline extends StatelessWidget {
  final List<EvenementHistorique> events;
  const Timeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (i) {
        final ev = events[i];
        final meta = eventMetaMap[ev.type]!;
        final isLast = i == events.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: meta.bg, shape: BoxShape.circle),
                child: Icon(meta.icon, size: 13, color: meta.color),
              ),
              if (!isLast) Container(width: 1.5, height: 32, color: AppColors.line),
            ]),
            const SizedBox(width: 12),
            Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meta.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(formatDateEvenement(ev.date), style: monoStyle(size: 11)),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
