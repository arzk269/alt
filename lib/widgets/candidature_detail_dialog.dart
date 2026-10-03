import 'package:flutter/material.dart';
import '../models/candidature.dart';
import '../models/profil.dart';
import '../models/formation.dart';
import '../repositories/profil_repository.dart';
import '../repositories/formation_repository.dart';
import '../repositories/candidatures_repository.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import 'gauge.dart';
import 'cv_preview.dart';

class CandidatureDetailDialog extends StatefulWidget {
  final String uid;
  final Candidature candidature;
  const CandidatureDetailDialog({super.key, required this.uid, required this.candidature});

  @override
  State<CandidatureDetailDialog> createState() => _CandidatureDetailDialogState();
}

class _CandidatureDetailDialogState extends State<CandidatureDetailDialog> {
  final _profilRepository = ProfilRepository();
  final _formationRepository = FormationRepository();
  final _candidaturesRepository = CandidaturesRepository();
  final _pdfService = PdfService();

  int _tab = 0;
  bool _chargement = true;
  bool _telechargementEnCours = false;
  bool _offreDepliee = false;
  Profil? _profil;
  List<Formation> _formations = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final profil = await _profilRepository.watchProfil(widget.uid).first;
    final formations = await _formationRepository.watchAll(widget.uid).first;
    if (!mounted) return;
    setState(() {
      _profil = profil;
      _formations = formations;
      _chargement = false;
    });
  }

  Future<void> _telecharger() async {
    if (_profil == null) return;
    setState(() => _telechargementEnCours = true);
    try {
      await _pdfService.genererEtTelecharger(
        candidature: widget.candidature,
        profil: _profil!,
        formations: _formations,
      );
    } finally {
      if (mounted) setState(() => _telechargementEnCours = false);
    }
  }

  Future<void> _confirmerSuppression() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette candidature ?'),
        content: const Text('Cette action est irréversible.'),
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
      await _candidaturesRepository.supprimer(widget.uid, widget.candidature.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidature;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 740),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.poste, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(c.entreprise, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: _confirmerSuppression, icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.brick)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.offreTexteBrut.isNotEmpty) _buildOffreDepliable(c.offreTexteBrut),
                    const SizedBox(height: 18),
                    Gauge(score: c.scoreMatching),
                    if (c.raisonsMatching.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text('JUSTIFICATIONS', style: monoStyle(size: 10.5)),
                      const SizedBox(height: 10),
                      ...c.raisonsMatching.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.check_circle, size: 12, color: AppColors.green)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4))),
                          ],
                        ),
                      )),
                    ],
                    const SizedBox(height: 20),
                    Row(children: [
                      _tabButton('CV', 0),
                      const SizedBox(width: 4),
                      _tabButton('Lettre de motivation', 1),
                      const Spacer(),
                      if (_tab == 0 && !_chargement)
                        OutlinedButton.icon(
                          onPressed: _telechargementEnCours ? null : _telecharger,
                          icon: _telechargementEnCours
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download, size: 15),
                          label: const Text('Télécharger en PDF'),
                        ),
                    ]),
                    const SizedBox(height: 12),
                    if (_chargement)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_tab == 0 && _profil != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CvPreview(candidature: c, profil: _profil!, formations: _formations),
                      )
                    else if (_tab == 1)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          c.lmGeneree != null && c.lmGeneree!.isNotEmpty ? c.lmGeneree! : 'Lettre non générée.',
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffreDepliable(String texte) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _offreDepliee = !_offreDepliee),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 15, color: AppColors.inkFaint),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Offre visée (texte collé)", style: monoStyle(size: 11.5, weight: FontWeight.w600))),
                  Icon(_offreDepliee ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.inkFaint),
                ],
              ),
            ),
          ),
          if (_offreDepliee)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SelectableText(texte, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.5)),
            ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tab == index;
    return TextButton(
      onPressed: () => setState(() => _tab = index),
      style: TextButton.styleFrom(
        backgroundColor: selected ? AppColors.blueSoft : Colors.transparent,
        foregroundColor: selected ? AppColors.blue : AppColors.inkFaint,
      ),
      child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
    );
  }
}
