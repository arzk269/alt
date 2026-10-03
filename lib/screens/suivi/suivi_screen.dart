import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/candidature.dart';
import '../../repositories/candidatures_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/status_dialog.dart';
import '../../widgets/candidature_detail_dialog.dart';

class SuiviScreen extends StatefulWidget {
  const SuiviScreen({super.key});

  @override
  State<SuiviScreen> createState() => _SuiviScreenState();
}

class _SuiviScreenState extends State<SuiviScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final _repository = CandidaturesRepository();
  String _filtre = 'toutes';
  String _recherche = '';

  Future<void> _confirmerSuppression(Candidature c) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette candidature ?'),
        content: Text('${c.poste} — ${c.entreprise}. Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brick),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme == true) {
      await _repository.supprimer(uid, c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Candidature>>(
      stream: _repository.watchAll(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()));
        }
        final candidatures = snapshot.data!;

        final aPostuler = candidatures.where((c) => c.statut == StatutCandidature.aPostuler).length;
        final enAttente = candidatures.where((c) => c.statut == StatutCandidature.envoyee || c.statut == StatutCandidature.relance).length;
        final entretiens = candidatures.where((c) => c.statut == StatutCandidature.entretien).length;
        final refus = candidatures.where((c) => c.statut == StatutCandidature.refus).length;

        final filtrees = candidatures.where((c) {
          final matchFiltre = _filtre == 'toutes' || statutToString(c.statut) == _filtre;
          final matchRecherche = _recherche.isEmpty || (c.poste + c.entreprise).toLowerCase().contains(_recherche.toLowerCase());
          return matchFiltre && matchRecherche;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SUIVI', style: monoStyle(size: 11)),
            const SizedBox(height: 6),
            const Text('Mes candidatures', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _statCard('À postuler', aPostuler, Icons.schedule, AppColors.blue, AppColors.blueSoft)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('En attente', enAttente, Icons.mail_outline, AppColors.amber, AppColors.amberSoft)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Entretiens', entretiens, Icons.check_circle_outline, AppColors.green, AppColors.greenSoft)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Refus', refus, Icons.cancel_outlined, AppColors.brick, AppColors.brickSoft)),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Rechercher un poste, une entreprise…', prefixIcon: Icon(Icons.search, size: 18)),
                  onChanged: (v) => setState(() => _recherche = v),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(spacing: 6, children: [
                _filtreChip('toutes', 'Toutes'),
                _filtreChip('a_postuler', 'À postuler'),
                _filtreChip('envoyee', 'Envoyée'),
                _filtreChip('relance', 'Relance'),
                _filtreChip('entretien', 'Entretien'),
                _filtreChip('refus', 'Refus'),
              ]),
            ]),
            const SizedBox(height: 20),
            if (filtrees.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    candidatures.isEmpty
                        ? "Aucune candidature pour l'instant — analyse une offre pour commencer."
                        : "Aucune candidature ne correspond à cette recherche.",
                    style: TextStyle(color: AppColors.inkFaint, fontSize: 13),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
                child: Column(children: filtrees.map((c) => _candidatureRow(c)).toList()),
              ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 10),
          Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkFaint)),
        ],
      ),
    );
  }

  Widget _filtreChip(String value, String label) {
    final selected = _filtre == value;
    return ChoiceChip(
      label: Text(label, style: monoStyle(size: 11.5, color: selected ? Colors.white : AppColors.inkSoft)),
      selected: selected,
      onSelected: (_) => setState(() => _filtre = value),
      selectedColor: AppColors.ink,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.line),
    );
  }

  Widget _candidatureRow(Candidature c) {
    return InkWell(
      onTap: () => showDialog(context: context, builder: (_) => CandidatureDetailDialog(uid: uid, candidature: c)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.bg, width: 1))),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.poste, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(c.entreprise, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text('${c.scoreMatching}', style: monoStyle(size: 13, weight: FontWeight.w600, color: AppColors.inkSoft)),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () => showDialog(context: context, builder: (_) => StatusDialog(uid: uid, candidature: c)),
                  child: StatusPill(statut: c.statut),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.inkFaint),
              onPressed: () => _confirmerSuppression(c),
              splashRadius: 18,
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
