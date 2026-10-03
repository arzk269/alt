import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/candidature.dart';
import '../../models/profil.dart';
import '../../models/formation.dart';
import '../../repositories/candidatures_repository.dart';
import '../../repositories/profil_repository.dart';
import '../../repositories/formation_repository.dart';
import '../../services/matching_service.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gauge.dart';
import '../../widgets/cv_preview.dart';

enum _Stage { input, loadingMatch, result, loadingGeneration, generated, erreur }

class NouvelleCandidatureScreen extends StatefulWidget {
  final VoidCallback? onCandidatureAjoutee;
  const NouvelleCandidatureScreen({super.key, this.onCandidatureAjoutee});

  @override
  State<NouvelleCandidatureScreen> createState() => _NouvelleCandidatureScreenState();
}

class _NouvelleCandidatureScreenState extends State<NouvelleCandidatureScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final _matchingService = MatchingService();
  final _candidaturesRepository = CandidaturesRepository();
  final _profilRepository = ProfilRepository();
  final _formationRepository = FormationRepository();
  final _pdfService = PdfService();
  final _offreController = TextEditingController();

  _Stage _stage = _Stage.input;
  MatchingResultDto? _matching;
  Candidature? _candidatureCreee;
  Profil? _profilComplet;
  List<Formation> _formationsCompletes = [];
  String? _erreur;
  int _tab = 0;
  bool _telechargementEnCours = false;

  Future<void> _analyser() async {
    final texte = _offreController.text.trim();
    if (texte.isEmpty) return;
    setState(() {
      _stage = _Stage.loadingMatch;
      _erreur = null;
    });
    try {
      final result = await _matchingService.matcherOffre(texte);
      if (!mounted) return;
      setState(() {
        _matching = result;
        _stage = _Stage.result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = "L'analyse a échoué. Vérifie ta connexion et réessaie.";
        _stage = _Stage.erreur;
      });
    }
  }

  Future<void> _genererEtEnregistrer() async {
    if (_matching == null) return;
    setState(() => _stage = _Stage.loadingGeneration);
    try {
      final generation = await _matchingService.genererCandidature(
        offreTexteBrut: _offreController.text.trim(),
        poste: _matching!.poste,
        entreprise: _matching!.entreprise,
        matching: _matching!,
      );

      final profil = await _profilRepository.watchProfil(uid).first;
      final formations = await _formationRepository.watchAll(uid).first;

      final brouillon = Candidature(
        id: '',
        poste: _matching!.poste.isNotEmpty ? _matching!.poste : 'Poste non précisé',
        entreprise: _matching!.entreprise.isNotEmpty ? _matching!.entreprise : 'Entreprise non précisée',
        offreTexteBrut: _offreController.text.trim(),
        domainePoste: _matching!.domainePoste,
        competencesMatchees: _matching!.competencesMatchees,
        scoreMatching: _matching!.scoreMatching,
        raisonsMatching: _matching!.raisonsMatching,
        profilResume: generation.profilResume,
        experiencesTexte: generation.experiencesTexte,
        competencesAMettreEnAvant: generation.competencesAMettreEnAvant,
        connaissancesAMettreEnAvant: generation.connaissancesAMettreEnAvant,
        lmGeneree: generation.lettreMotivation,
        statut: StatutCandidature.aPostuler,
        historique: [EvenementHistorique(type: TypeEvenement.ajoutee, date: DateTime.now())],
        createdAt: DateTime.now(),
      );
      final id = await _candidaturesRepository.ajouterCandidature(uid, brouillon);

      if (!mounted) return;
      setState(() {
        _candidatureCreee = Candidature(
          id: id,
          poste: brouillon.poste,
          entreprise: brouillon.entreprise,
          offreTexteBrut: brouillon.offreTexteBrut,
          domainePoste: brouillon.domainePoste,
          competencesMatchees: brouillon.competencesMatchees,
          scoreMatching: brouillon.scoreMatching,
          raisonsMatching: brouillon.raisonsMatching,
          profilResume: brouillon.profilResume,
          experiencesTexte: brouillon.experiencesTexte,
          competencesAMettreEnAvant: brouillon.competencesAMettreEnAvant,
          connaissancesAMettreEnAvant: brouillon.connaissancesAMettreEnAvant,
          lmGeneree: brouillon.lmGeneree,
          statut: brouillon.statut,
          historique: brouillon.historique,
          createdAt: brouillon.createdAt,
        );
        _profilComplet = profil;
        _formationsCompletes = formations;
        _stage = _Stage.generated;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = "La génération a échoué. Réessaie dans un instant.";
        _stage = _Stage.erreur;
      });
    }
  }

  Future<void> _telechargerPdf() async {
    if (_candidatureCreee == null || _profilComplet == null) return;
    setState(() => _telechargementEnCours = true);
    try {
      await _pdfService.genererEtTelecharger(
        candidature: _candidatureCreee!,
        profil: _profilComplet!,
        formations: _formationsCompletes,
      );
    } finally {
      if (mounted) setState(() => _telechargementEnCours = false);
    }
  }

  void _recommencer() {
    setState(() {
      _stage = _Stage.input;
      _offreController.clear();
      _matching = null;
      _candidatureCreee = null;
      _profilComplet = null;
      _formationsCompletes = [];
      _erreur = null;
      _tab = 0;
    });
  }

  @override
  void dispose() {
    _offreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOUVELLE CANDIDATURE', style: monoStyle(size: 11)),
        const SizedBox(height: 6),
        const Text('Analyser une offre', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 24),
        if (_stage == _Stage.input) _buildInput(),
        if (_stage == _Stage.loadingMatch) _buildLoading("Analyse de l'offre en cours…"),
        if (_stage == _Stage.result) _buildResult(),
        if (_stage == _Stage.loadingGeneration) _buildLoading('Génération du CV et de la lettre…'),
        if (_stage == _Stage.generated) _buildGenerated(),
        if (_stage == _Stage.erreur) _buildErreur(),
      ],
    );
  }

  Widget _buildInput() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.link, size: 15, color: AppColors.inkFaint),
            SizedBox(width: 8),
            Text("Coller le lien ou le texte de l'offre", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _offreController,
            maxLines: 8,
            decoration: const InputDecoration(hintText: "https://... ou le texte complet de l'offre"),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _analyser,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text("Analyser l'offre"),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(String texte) {
    return _card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(texte, style: monoStyle(size: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final matching = _matching!;
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    matching.poste.isNotEmpty ? matching.poste : 'Poste non précisé',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
              if (matching.entreprise.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(matching.entreprise, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(100)),
                child: Text(matching.domainePoste, style: monoStyle(size: 12, color: AppColors.blue)),
              ),
              const SizedBox(height: 20),
              Gauge(score: matching.scoreMatching),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Éléments du profil qui matchent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Compétences détectées comme pertinentes pour cette offre.', style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: matching.competencesMatchees.map((c) => Chip(
                  backgroundColor: AppColors.blueSoft,
                  side: BorderSide(color: AppColors.blue.withOpacity(0.15)),
                  label: Text(c, style: monoStyle(size: 12, color: AppColors.blue)),
                )).toList(),
              ),
              const SizedBox(height: 18),
              ...matching.raisonsMatching.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle, size: 13, color: AppColors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4))),
                  ],
                ),
              )),
            ],
          ),
        ),
        if (matching.competencesManquantes.isNotEmpty) ...[
          const SizedBox(height: 20),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ce qui manque pour cette offre', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Exigences de l\'offre non couvertes par ton profil actuel.', style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: matching.competencesManquantes.map((c) => Chip(
                    backgroundColor: AppColors.brickSoft,
                    side: BorderSide(color: AppColors.brick.withOpacity(0.2)),
                    label: Text(c, style: monoStyle(size: 12, color: AppColors.brick)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(children: [
          ElevatedButton.icon(
            onPressed: _genererEtEnregistrer,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Générer le CV et la lettre'),
          ),
          const SizedBox(width: 10),
          OutlinedButton(onPressed: _recommencer, child: const Text('Analyser une autre offre')),
        ]),
      ],
    );
  }

  Widget _buildGenerated() {
    final candidature = _candidatureCreee!;
    final profil = _profilComplet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Icon(Icons.check_circle, size: 16, color: AppColors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Ajoutée au suivi — statut "À postuler"', style: TextStyle(fontSize: 13, color: AppColors.green))),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _tabButton('CV', 0),
          const SizedBox(width: 4),
          _tabButton('Lettre de motivation', 1),
          const Spacer(),
          if (_tab == 0)
            OutlinedButton.icon(
              onPressed: _telechargementEnCours ? null : _telechargerPdf,
              icon: _telechargementEnCours
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download, size: 15),
              label: const Text('Télécharger en PDF'),
            ),
        ]),
        const SizedBox(height: 12),
        if (_tab == 0 && profil != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CvPreview(candidature: candidature, profil: profil, formations: _formationsCompletes),
          )
        else if (_tab == 1)
          _card(
            child: Text(candidature.lmGeneree ?? '', style: const TextStyle(fontSize: 14, height: 1.6)),
          ),
        const SizedBox(height: 20),
        OutlinedButton(onPressed: _recommencer, child: const Text('Analyser une autre offre')),
      ],
    );
  }

  Widget _buildErreur() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.error_outline, size: 18, color: AppColors.brick),
            const SizedBox(width: 8),
            Expanded(child: Text(_erreur ?? 'Une erreur est survenue.', style: const TextStyle(color: AppColors.brick))),
          ]),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => setState(() => _stage = _matching == null ? _Stage.input : _Stage.result), child: const Text('Réessayer')),
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
      child: child,
    );
  }
}
