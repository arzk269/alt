import 'package:flutter/material.dart';
import '../models/candidature.dart';
import '../repositories/candidatures_repository.dart';
import '../theme/app_theme.dart';
import 'status_pill.dart';
import 'timeline.dart';

class _StatusOption {
  final TypeEvenement type;
  final String label;
  final IconData icon;
  const _StatusOption(this.type, this.label, this.icon);
}

const List<_StatusOption> _options = [
  _StatusOption(TypeEvenement.aPostuler, 'À postuler', Icons.schedule),
  _StatusOption(TypeEvenement.envoyee, 'Envoyée', Icons.mail_outline),
  _StatusOption(TypeEvenement.relance, 'Relance', Icons.notifications_active_outlined),
  _StatusOption(TypeEvenement.entretien, 'Entretien', Icons.check_circle_outline),
  _StatusOption(TypeEvenement.refus, 'Refus', Icons.cancel_outlined),
];

class StatusDialog extends StatefulWidget {
  final String uid;
  final Candidature candidature;
  const StatusDialog({super.key, required this.uid, required this.candidature});

  @override
  State<StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<StatusDialog> {
  final _repository = CandidaturesRepository();
  bool _loading = false;

  Future<void> _changer(TypeEvenement type) async {
    setState(() => _loading = true);
    await _repository.changerStatut(widget.uid, widget.candidature.id, type);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Candidature>>(
      stream: _repository.watchAll(widget.uid),
      builder: (context, snapshot) {
        final candidatures = snapshot.data ?? [widget.candidature];
        final current = candidatures.firstWhere(
          (c) => c.id == widget.candidature.id,
          orElse: () => widget.candidature,
        );

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(current.poste, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(current.entreprise, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('STATUT ACTUEL', style: monoStyle(size: 10.5)),
                    const SizedBox(height: 8),
                    StatusPill(statut: current.statut),
                    const SizedBox(height: 20),
                    Text('CHANGER LE STATUT', style: monoStyle(size: 10.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _options.map((opt) {
                        return OutlinedButton.icon(
                          onPressed: _loading ? null : () => _changer(opt.type),
                          icon: Icon(opt.icon, size: 14),
                          label: Text(opt.label),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Recliquer sur un statut ajoute un nouvel événement daté (utile pour une deuxième relance, par exemple).",
                      style: TextStyle(fontSize: 11, color: AppColors.inkFaint),
                    ),
                    const SizedBox(height: 22),
                    Text('HISTORIQUE', style: monoStyle(size: 10.5)),
                    const SizedBox(height: 14),
                    Timeline(events: current.historique),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
