import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/profil.dart';
import '../../models/competence.dart';
import '../../models/experience.dart';
import '../../models/formation.dart';
import '../../models/projet.dart';
import '../../models/langue.dart';
import '../../models/certification.dart';
import '../../models/connaissance_academique.dart';
import '../../repositories/profil_repository.dart';
import '../../repositories/experience_repository.dart';
import '../../repositories/formation_repository.dart';
import '../../repositories/projet_repository.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/completion_gauge.dart';

enum _SectionStatus { vide, partiel, complet }

const _mois = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre'];

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final _profilRepository = ProfilRepository();
  final _experienceRepository = ExperienceRepository();
  final _formationRepository = FormationRepository();
  final _projetRepository = ProjetRepository();
  final _storageService = StorageService();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailCvController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _villeController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _mobiliteController = TextEditingController();

  bool _initialized = false;
  Profil? _profil;
  bool _saving = false;

  void _hydrate(Profil profil) {
    if (_initialized) return;
    _initialized = true;
    _profil = profil;
    _nomController.text = profil.nom;
    _prenomController.text = profil.prenom;
    _emailCvController.text = profil.emailCv.isNotEmpty ? profil.emailCv : profil.email;
    _telephoneController.text = profil.telephone;
    _villeController.text = profil.ville;
    _linkedinController.text = profil.linkedinUrl ?? '';
    _githubController.text = profil.githubUrl ?? '';
    _mobiliteController.text = profil.mobilite;
  }

  void _showSnackbar(String message, {required Color color, required IconData icon}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(message),
        ]),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSavedSnackbar([String message = 'Enregistré']) => _showSnackbar(message, color: AppColors.green, icon: Icons.check_circle);
  void _showDeletedSnackbar([String message = 'Supprimé']) => _showSnackbar(message, color: AppColors.brick, icon: Icons.delete);

  Future<void> _persistSilent(Profil updated) async {
    setState(() => _saving = true);
    await _profilRepository.mettreAJourProfil(updated);
    if (!mounted) return;
    setState(() {
      _profil = updated;
      _saving = false;
    });
  }

  Future<void> _persist(Profil updated) async {
    await _persistSilent(updated);
    _showSavedSnackbar();
  }

  Future<void> _persistDeleted(Profil updated, [String message = 'Supprimé']) async {
    await _persistSilent(updated);
    _showDeletedSnackbar(message);
  }

  Future<void> _save() async {
    if (_profil == null) return;
    final current = _profil!;
    final newNom = _nomController.text.trim();
    final newPrenom = _prenomController.text.trim();
    final newEmailCv = _emailCvController.text.trim();
    final newTelephone = _telephoneController.text.trim();
    final newVille = _villeController.text.trim();
    final newLinkedin = _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim();
    final newGithub = _githubController.text.trim().isEmpty ? null : _githubController.text.trim();
    final newMobilite = _mobiliteController.text.trim();

    final unchanged = newNom == current.nom &&
        newPrenom == current.prenom &&
        newEmailCv == current.emailCv &&
        newTelephone == current.telephone &&
        newVille == current.ville &&
        newLinkedin == current.linkedinUrl &&
        newGithub == current.githubUrl &&
        newMobilite == current.mobilite;

    if (unchanged) return;

    final updated = current.copyWith(
      nom: newNom,
      prenom: newPrenom,
      emailCv: newEmailCv,
      telephone: newTelephone,
      ville: newVille,
      linkedinUrl: newLinkedin,
      githubUrl: newGithub,
      mobilite: newMobilite,
    );
    await _persist(updated);
  }

  String _initials(Profil profil) => '${profil.prenom.isNotEmpty ? profil.prenom[0] : ''}${profil.nom.isNotEmpty ? profil.nom[0] : ''}';

  Future<void> _showPhotoActions(Profil profil) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Changer la photo'), onTap: () => Navigator.pop(context, 'change')),
          if (profil.photoUrl != null)
            ListTile(leading: const Icon(Icons.delete_outline, color: AppColors.brick), title: const Text('Supprimer la photo'), onTap: () => Navigator.pop(context, 'remove')),
        ]),
      ),
    );
    if (action == 'change') await _changerPhoto();
    if (action == 'remove') await _supprimerPhoto();
  }

  Future<void> _changerPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (xfile == null || _profil == null) return;
    final bytes = await xfile.readAsBytes();
    final url = await _storageService.uploaderPhotoProfil(uid, bytes);
    await _persist(_profil!.copyWith(photoUrl: url));
  }

  Future<void> _supprimerPhoto() async {
    if (_profil == null) return;
    setState(() => _saving = true);
    await _storageService.supprimerPhotoProfil(uid);
    await _profilRepository.supprimerPhoto(uid);
    if (!mounted) return;
    setState(() {
      _profil = _profil!.copyWith(clearPhoto: true);
      _saving = false;
    });
    _showDeletedSnackbar('Photo supprimée');
  }

  Future<void> _pickDateDebutSouhaitee() async {
    if (_profil == null) return;
    final picked = await showDatePicker(context: context, initialDate: _profil!.dateDebutSouhaitee ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (picked == null) return;
    var updated = _profil!.copyWith(dateDebutSouhaitee: picked);
    if (updated.dateFinSouhaitee != null && updated.dateFinSouhaitee!.isBefore(picked)) {
      updated = Profil(
        uid: updated.uid, nom: updated.nom, prenom: updated.prenom, email: updated.email, emailCv: updated.emailCv,
        telephone: updated.telephone, ville: updated.ville, linkedinUrl: updated.linkedinUrl, githubUrl: updated.githubUrl,
        typeRecherche: updated.typeRecherche, dateDebutSouhaitee: picked, dateFinSouhaitee: null,
        competences: updated.competences, langues: updated.langues, certifications: updated.certifications,
        connaissancesAcademiques: updated.connaissancesAcademiques,
        permis: updated.permis, centresInteret: updated.centresInteret, mobilite: updated.mobilite, photoUrl: updated.photoUrl,
      );
    }
    await _persist(updated);
  }

  Future<void> _pickDateFinSouhaitee() async {
    if (_profil == null || _profil!.dateDebutSouhaitee == null) return;
    final debut = _profil!.dateDebutSouhaitee!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _profil!.dateFinSouhaitee != null && !_profil!.dateFinSouhaitee!.isBefore(debut) ? _profil!.dateFinSouhaitee! : debut,
      firstDate: debut,
      lastDate: DateTime(2031),
    );
    if (picked == null) return;
    await _persist(_profil!.copyWith(dateFinSouhaitee: picked));
  }

  Future<void> _ajouterCompetence() async {
    final result = await showDialog<Competence>(context: context, builder: (_) => const _CompetenceDialog());
    if (result == null || _profil == null) return;
    await _persist(_profil!.copyWith(competences: [..._profil!.competences, result]));
  }

  Future<void> _supprimerCompetence(Competence c) async {
    if (_profil == null) return;
    await _persistDeleted(_profil!.copyWith(competences: _profil!.competences.where((x) => x.id != c.id).toList()));
  }

  Future<void> _ajouterConnaissance() async {
    final result = await showDialog<ConnaissanceAcademique>(context: context, builder: (_) => const _ConnaissanceDialog());
    if (result == null || _profil == null) return;
    await _persist(_profil!.copyWith(connaissancesAcademiques: [..._profil!.connaissancesAcademiques, result]));
  }

  Future<void> _supprimerConnaissance(ConnaissanceAcademique c) async {
    if (_profil == null) return;
    await _persistDeleted(_profil!.copyWith(connaissancesAcademiques: _profil!.connaissancesAcademiques.where((x) => x.nom != c.nom).toList()));
  }

  Future<void> _ajouterOuModifierFormation([Formation? existing]) async {
    final result = await showDialog<Formation>(context: context, builder: (_) => _FormationDialog(initial: existing));
    if (result == null) return;
    if (existing != null) {
      await _formationRepository.modifier(uid, existing.id, result);
    } else {
      await _formationRepository.ajouter(uid, result);
    }
    await _profilRepository.touchUpdatedAt(uid);
    _showSavedSnackbar();
  }

  Future<void> _supprimerFormation(String id) async {
    await _formationRepository.supprimer(uid, id);
    await _profilRepository.touchUpdatedAt(uid);
    _showDeletedSnackbar('Formation supprimée');
  }

  Future<void> _ajouterOuModifierProjet([Projet? existing]) async {
    final result = await showDialog<Projet>(context: context, builder: (_) => _ProjetDialog(initial: existing));
    if (result == null) return;
    if (existing != null) {
      await _projetRepository.modifier(uid, existing.id, result);
    } else {
      await _projetRepository.ajouter(uid, result);
    }
    await _profilRepository.touchUpdatedAt(uid);
    _showSavedSnackbar();
  }

  Future<void> _supprimerProjet(String id) async {
    await _projetRepository.supprimer(uid, id);
    await _profilRepository.touchUpdatedAt(uid);
    _showDeletedSnackbar('Projet supprimé');
  }

  Future<void> _ajouterOuModifierExperience([Experience? existing]) async {
    final result = await showDialog<Experience>(context: context, builder: (_) => _ExperienceDialog(initial: existing));
    if (result == null) return;
    if (existing != null) {
      await _experienceRepository.modifier(uid, existing.id, result);
    } else {
      await _experienceRepository.ajouter(uid, result);
    }
    await _profilRepository.touchUpdatedAt(uid);
    _showSavedSnackbar();
  }

  Future<void> _supprimerExperience(String id) async {
    await _experienceRepository.supprimer(uid, id);
    await _profilRepository.touchUpdatedAt(uid);
    _showDeletedSnackbar('Expérience supprimée');
  }

  Future<void> _ajouterLangue() async {
    final result = await showDialog<Langue>(context: context, builder: (_) => const _LangueDialog());
    if (result == null || _profil == null) return;
    await _persist(_profil!.copyWith(langues: [..._profil!.langues, result]));
  }

  Future<void> _supprimerLangue(Langue l) async {
    if (_profil == null) return;
    await _persistDeleted(_profil!.copyWith(langues: _profil!.langues.where((x) => x.nom != l.nom).toList()));
  }

  Future<void> _ajouterCertification() async {
    final result = await showDialog<Certification>(context: context, builder: (_) => const _CertificationDialog());
    if (result == null || _profil == null) return;
    await _persist(_profil!.copyWith(certifications: [..._profil!.certifications, result]));
  }

  Future<void> _supprimerCertification(Certification c) async {
    if (_profil == null) return;
    await _persistDeleted(_profil!.copyWith(certifications: _profil!.certifications.where((x) => x.nom != c.nom).toList()));
  }

  Future<void> _ajouterTag({required String titre, required String hint, required List<String> actuels, required ValueChanged<List<String>> onSave}) async {
    final result = await showDialog<String>(context: context, builder: (_) => _SimpleTagDialog(titre: titre, hint: hint));
    if (result == null || result.trim().isEmpty) return;
    onSave([...actuels, result.trim()]);
  }

  Future<void> _persistPermis(List<String> permis, {bool suppression = false}) async {
    if (_profil == null) return;
    final updated = _profil!.copyWith(permis: permis);
    if (suppression) {
      await _persistDeleted(updated);
    } else {
      await _persist(updated);
    }
  }

  Future<void> _persistCentresInteret(List<String> centres, {bool suppression = false}) async {
    if (_profil == null) return;
    final updated = _profil!.copyWith(centresInteret: centres);
    if (suppression) {
      await _persistDeleted(updated);
    } else {
      await _persist(updated);
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Non renseignée';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatDerniereModif(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    final heure = '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return "Aujourd'hui à $heure";
    if (diff == 1) return "Hier à $heure";
    return 'le ${d.day} ${_mois[d.month - 1]} ${d.year} à $heure';
  }

  int _computeCompletion({
    required Profil profil,
    required List<Formation> formations,
    required List<Experience> experiences,
    required List<Projet> projets,
  }) {
    double score = 0;
    if (profil.photoUrl != null) score += 10;
    if (profil.telephone.isNotEmpty && profil.ville.isNotEmpty) score += 10;
    if (formations.isNotEmpty) score += 15;
    if (profil.connaissancesAcademiques.isNotEmpty) score += 10;
    if (experiences.isNotEmpty || projets.isNotEmpty) score += 20;
    if (profil.competences.length >= 3) score += 15;
    if (profil.langues.isNotEmpty) score += 10;
    if (profil.mobilite.isNotEmpty || profil.permis.isNotEmpty) score += 5;
    if (profil.certifications.isNotEmpty || profil.centresInteret.isNotEmpty) score += 5;
    return score.round();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailCvController.dispose();
    _telephoneController.dispose();
    _villeController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _mobiliteController.dispose();
    super.dispose();
  }

   @override
  Widget build(BuildContext context) {
    return StreamBuilder<Profil?>(
      stream: _profilRepository.watchProfil(uid),
      builder: (context, profilSnapshot) {
        if (!profilSnapshot.hasData || profilSnapshot.data == null) {
          return const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()));
        }
        _hydrate(profilSnapshot.data!);
        final profil = profilSnapshot.data!;

        return StreamBuilder<List<Formation>>(
          stream: _formationRepository.watchAll(uid),
          builder: (context, formationSnapshot) {
            return StreamBuilder<List<Experience>>(
              stream: _experienceRepository.watchAll(uid),
              builder: (context, expSnapshot) {
                return StreamBuilder<List<Projet>>(
                  stream: _projetRepository.watchAll(uid),
                  builder: (context, projetSnapshot) {
                    final allLoaded = formationSnapshot.hasData && expSnapshot.hasData && projetSnapshot.hasData;
                    if (!allLoaded) {
                      return const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()));
                    }

                    final formations = formationSnapshot.data!;
                    final experiences = expSnapshot.data!;
                    final projets = projetSnapshot.data!;
                    final completion = _computeCompletion(profil: profil, formations: formations, experiences: experiences, projets: projets);

                    final infoCount = (profil.prenom.isNotEmpty ? 1 : 0) +
                        (profil.nom.isNotEmpty ? 1 : 0) +
                        (profil.telephone.isNotEmpty ? 1 : 0) +
                        (profil.emailCv.isNotEmpty ? 1 : 0) +
                        (profil.ville.isNotEmpty ? 1 : 0) +
                        1 +
                        (profil.linkedinUrl != null && profil.linkedinUrl!.isNotEmpty ? 1 : 0) +
                        (profil.githubUrl != null && profil.githubUrl!.isNotEmpty ? 1 : 0) +
                        (profil.dateDebutSouhaitee != null ? 1 : 0) +
                        (profil.dateFinSouhaitee != null ? 1 : 0);
                    const infoTotal = 10;
                    final infoStatus = infoCount == 0
                        ? _SectionStatus.vide
                        : (infoCount < infoTotal ? _SectionStatus.partiel : _SectionStatus.complet);

                    final mobiliteCount = profil.permis.length + (profil.mobilite.isNotEmpty ? 1 : 0);
                    final mobiliteStatus = mobiliteCount == 0 ? _SectionStatus.vide : _SectionStatus.complet;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('VOTRE ESPACE', style: monoStyle(size: 11)),
                                const SizedBox(height: 6),
                                const Text('Profil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),
                              ],
                            ),
                            if (_saving)
                              Row(children: [
                                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                const SizedBox(width: 8),
                                Text('Enregistrement…', style: monoStyle(size: 12)),
                              ])
                            else if (profil.updatedAt != null)
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('DERNIÈRE MODIFICATION', style: monoStyle(size: 10)),
                                const SizedBox(height: 2),
                                Text(_formatDerniereModif(profil.updatedAt), style: monoStyle(size: 12, weight: FontWeight.w600, color: AppColors.inkSoft)),
                              ]),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CompletionGauge(score: completion),
                        const SizedBox(height: 20),

                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => _showPhotoActions(profil),
                                      child: Stack(
                                        children: [
                                          ClipOval(
                                            child: Container(
                                              width: 72,
                                              height: 72,
                                              color: AppColors.blue,
                                              child: profil.photoUrl != null
                                                  ? Image.network(
                                                      profil.photoUrl!,
                                                      width: 72,
                                                      height: 72,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context, child, progress) {
                                                        if (progress == null) return child;
                                                        return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)));
                                                      },
                                                      errorBuilder: (context, error, stack) => Center(child: Text(_initials(profil), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18))),
                                                    )
                                                  : Center(child: Text(_initials(profil), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18))),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.line)),
                                              child: const Icon(Icons.camera_alt_outlined, size: 13, color: AppColors.inkSoft),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Photo de profil', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Text('Clique pour changer ou supprimer.', style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint)),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 36, color: AppColors.line),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(children: [
                                    Icon(Icons.badge_outlined, size: 16, color: AppColors.inkFaint),
                                    SizedBox(width: 8),
                                    Text('Informations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  ]),
                                  _sectionBadge(infoStatus, detail: '$infoCount'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(children: [
                                Expanded(child: _field('Prénom', _prenomController)),
                                const SizedBox(width: 14),
                                Expanded(child: _field('Nom', _nomController)),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(child: _field('Téléphone', _telephoneController)),
                                const SizedBox(width: 14),
                                Expanded(child: _field('Email (affiché sur le CV)', _emailCvController)),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(child: _field('Ville', _villeController)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: DropdownButtonFormField<TypeRecherche>(
                                    value: profil.typeRecherche,
                                    decoration: const InputDecoration(labelText: 'Recherche'),
                                    items: const [
                                      DropdownMenuItem(value: TypeRecherche.alternance, child: Text('Alternance')),
                                      DropdownMenuItem(value: TypeRecherche.stage, child: Text('Stage')),
                                    ],
                                    onChanged: (value) async {
                                      if (value == null) return;
                                      await _persist(profil.copyWith(typeRecherche: value));
                                    },
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(child: _field('LinkedIn (optionnel)', _linkedinController)),
                                const SizedBox(width: 14),
                                Expanded(child: _field('GitHub / portfolio (optionnel)', _githubController)),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _pickDateDebutSouhaitee,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Date de début souhaitée'),
                                      child: Text(_formatDate(profil.dateDebutSouhaitee), style: const TextStyle(fontSize: 14)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: profil.dateDebutSouhaitee == null ? null : _pickDateFinSouhaitee,
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Date de fin souhaitée',
                                        helperText: profil.dateDebutSouhaitee == null ? "Choisis d'abord la date de début" : null,
                                        helperStyle: monoStyle(size: 10.5),
                                      ),
                                      child: Text(
                                        _formatDate(profil.dateFinSouhaitee),
                                        style: TextStyle(fontSize: 14, color: profil.dateDebutSouhaitee == null ? AppColors.inkFaint : AppColors.ink),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        _sectionCard(
                          titre: 'Formations',
                          status: formations.isEmpty ? _SectionStatus.vide : _SectionStatus.complet,
                          detail: '${formations.length}',
                          onAdd: () => _ajouterOuModifierFormation(),
                          child: formations.isEmpty
                              ? _empty('Aucune formation ajoutée pour le moment.')
                              : Column(children: formations.map((f) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text('${f.diplome} — ${f.etablissement}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                                          Row(mainAxisSize: MainAxisSize.min, children: [
                                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.inkFaint), onPressed: () => _ajouterOuModifierFormation(f), splashRadius: 16),
                                            IconButton(icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.inkFaint), onPressed: () => _supprimerFormation(f.id), splashRadius: 18),
                                          ]),
                                        ],
                                      ),
                                      Text('${_formatDate(f.dateDebut)} — ${_formatDate(f.dateFin)}${f.mention != null && f.mention!.isNotEmpty ? " · ${f.mention}" : ""}', style: monoStyle(size: 11)),
                                    ],
                                  ),
                                )).toList()),
                        ),
                        const SizedBox(height: 20),

                        _sectionCard(
                          titre: 'Connaissances académiques',
                          status: profil.connaissancesAcademiques.isEmpty ? _SectionStatus.vide : _SectionStatus.complet,
                          detail: '${profil.connaissancesAcademiques.length}',
                          onAdd: _ajouterConnaissance,
                          child: profil.connaissancesAcademiques.isEmpty
                              ? _empty('Matières théoriques maîtrisées (ex. Mécanique des fluides, RDM, Thermodynamique).')
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: profil.connaissancesAcademiques.map((c) => Chip(
                                    backgroundColor: AppColors.blueSoft,
                                    side: BorderSide(color: AppColors.blue.withOpacity(0.15)),
                                    label: Text('${c.nom} · ${niveauConnaissanceLabels[c.niveau]}', style: monoStyle(size: 12, color: AppColors.blue)),
                                    deleteIcon: const Icon(Icons.close, size: 14),
                                    onDeleted: () => _supprimerConnaissance(c),
                                  )).toList(),
                                ),
                        ),
                        const SizedBox(height: 20),

                        _sectionCard(
                          titre: 'Expériences',
                          status: experiences.isEmpty ? _SectionStatus.vide : _SectionStatus.complet,
                          detail: '${experiences.length}',
                          onAdd: () => _ajouterOuModifierExperience(),
                          child: experiences.isEmpty
                              ? _empty('Aucune expérience ajoutée pour le moment.')
                              : Column(children: experiences.map((e) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text('${e.titre} — ${e.entreprise}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                                          Row(mainAxisSize: MainAxisSize.min, children: [
                                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.inkFaint), onPressed: () => _ajouterOuModifierExperience(e), splashRadius: 16),
                                            IconButton(icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.inkFaint), onPressed: () => _supprimerExperience(e.id), splashRadius: 18),
                                          ]),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text('${_formatDate(e.dateDebut)} — ${_formatDate(e.dateFin)}', style: monoStyle(size: 11)),
                                      const SizedBox(height: 6),
                                      Text(e.contexte, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                                      const SizedBox(height: 8),
                                      Wrap(spacing: 6, children: e.outilsUtilises.map((o) => Chip(
                                        label: Text(o, style: monoStyle(size: 10.5)),
                                        backgroundColor: AppColors.bg,
                                        side: const BorderSide(color: AppColors.line),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      )).toList()),
                                    ],
                                  ),
                                )).toList()),
                        ),
                        const SizedBox(height: 20),

                        _sectionCard(
                          titre: 'Projets académiques / personnels',
                          status: projets.isEmpty ? _SectionStatus.vide : _SectionStatus.complet,
                          detail: '${projets.length}',
                          onAdd: () => _ajouterOuModifierProjet(),
                          child: projets.isEmpty
                              ? _empty('Aucun projet ajouté pour le moment.')
                              : Column(children: projets.map((p) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text(p.titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                                          Row(mainAxisSize: MainAxisSize.min, children: [
                                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.inkFaint), onPressed: () => _ajouterOuModifierProjet(p), splashRadius: 16),
                                            IconButton(icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.inkFaint), onPressed: () => _supprimerProjet(p.id), splashRadius: 18),
                                          ]),
                                        ],
                                      ),
                                      if (p.dateDebut != null) Text('${_formatDate(p.dateDebut)} — ${_formatDate(p.dateFin)}', style: monoStyle(size: 11)),
                                      if (p.contexte.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(p.contexte, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                                      ],
                                      if (p.outils.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(spacing: 6, children: p.outils.map((o) => Chip(
                                          label: Text(o, style: monoStyle(size: 10.5)),
                                          backgroundColor: AppColors.bg,
                                          side: const BorderSide(color: AppColors.line),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        )).toList()),
                                      ],
                                    ],
                                  ),
                                )).toList()),
                        ),
                        const SizedBox(height: 20),

                        _sectionCard(
                          titre: 'Compétences',
                          status: profil.competences.length >= 3 ? _SectionStatus.complet : (profil.competences.isEmpty ? _SectionStatus.vide : _SectionStatus.partiel),
                          detail: '${profil.competences.length}',
                          onAdd: _ajouterCompetence,
                          child: profil.competences.isEmpty
                              ? _empty('Aucune compétence ajoutée pour le moment.')
                              : Column(children: profil.competences.map((c) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(children: [
                                              Text(c.nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                              const SizedBox(width: 6),
                                              Text('· ${c.domaine}', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                                            ]),
                                          ),
                                          IconButton(icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.inkFaint), onPressed: () => _supprimerCompetence(c), splashRadius: 18),
                                        ],
                                      ),
                                      if (c.items.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ...c.items.map((item) => Padding(
                                          padding: const EdgeInsets.only(bottom: 3),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('· ', style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint)),
                                              Expanded(child: Text(item, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft))),
                                            ],
                                          ),
                                        )),
                                      ],
                                      if (c.outils.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(spacing: 6, children: c.outils.map((o) => Chip(
                                          label: Text(o, style: monoStyle(size: 10.5)),
                                          backgroundColor: AppColors.bg,
                                          side: const BorderSide(color: AppColors.line),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        )).toList()),
                                      ],
                                    ],
                                  ),
                                )).toList()),
                        ),
                        const SizedBox(height: 20),

                        _sectionCard(
                          titre: 'Langues',
                          status: profil.langues.isEmpty ? _SectionStatus.vide : _SectionStatus.complet,
                          detail: '${profil.langues.length}',
                          onAdd: _ajouterLangue,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profil.langues.map((l) => Chip(
                              backgroundColor: AppColors.greenSoft,
                              side: BorderSide(color: AppColors.green.withOpacity(0.2)),
                              label: Text('${l.nom} · ${niveauLangueLabels[l.niveau]}${l.score != null && l.score!.isNotEmpty ? " (${l.score})" : ""}', style: monoStyle(size: 12, color: AppColors.green)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => _supprimerLangue(l),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _sectionCard(
                          titre: 'Certifications & habilitations',
                          status: profil.certifications.isEmpty ? _SectionStatus.vide : _SectionStatus.complet,
                          detail: '${profil.certifications.length}',
                          onAdd: _ajouterCertification,
                          child: profil.certifications.isEmpty
                              ? _empty('Aucune certification ajoutée. Optionnel (CACES, habilitation électrique, SST…).')
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: profil.certifications.map((c) => Chip(
                                    backgroundColor: AppColors.amberSoft,
                                    side: BorderSide(color: AppColors.amber.withOpacity(0.2)),
                                    label: Text('${c.nom}${c.annee != null && c.annee!.isNotEmpty ? " · ${c.annee}" : ""}', style: monoStyle(size: 12, color: AppColors.amber)),
                                    deleteIcon: const Icon(Icons.close, size: 14),
                                    onDeleted: () => _supprimerCertification(c),
                                  )).toList(),
                                ),
                        ),
                        const SizedBox(height: 20),

                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Mobilité & permis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  _sectionBadge(mobiliteStatus, detail: '$mobiliteCount'),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _field('Mobilité (ex. Mobile France entière, disponible immédiatement)', _mobiliteController),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Permis', style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint)),
                                  TextButton.icon(
                                    onPressed: () => _ajouterTag(titre: 'Ajouter un permis', hint: 'Ex. Permis B', actuels: profil.permis, onSave: _persistPermis),
                                    icon: const Icon(Icons.add, size: 15),
                                    label: const Text('Ajouter'),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: profil.permis.map((p) => Chip(
                                  label: Text(p, style: const TextStyle(fontSize: 12.5)),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () => _persistPermis(profil.permis.where((x) => x != p).toList(), suppression: true),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        _sectionCard(
                          titre: 'Centres d\'intérêt',
                          status: profil.centresInteret.isEmpty ? _SectionStatus.vide : _SectionStatus.complet,
                          detail: '${profil.centresInteret.length}',
                          onAdd: () => _ajouterTag(titre: 'Ajouter un centre d\'intérêt', hint: 'Ex. Course à pied', actuels: profil.centresInteret, onSave: _persistCentresInteret),
                          child: profil.centresInteret.isEmpty
                              ? _empty('Optionnel, sert surtout d\'accroche en entretien.')
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: profil.centresInteret.map((c) => Chip(
                                    label: Text(c, style: const TextStyle(fontSize: 12.5)),
                                    deleteIcon: const Icon(Icons.close, size: 14),
                                    onDeleted: () => _persistCentresInteret(profil.centresInteret.where((x) => x != c).toList(), suppression: true),
                                  )).toList(),
                                ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) _save();
      },
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        onEditingComplete: _save,
      ),
    );
  }

  Widget _empty(String text) => Text(text, style: TextStyle(color: AppColors.inkFaint, fontSize: 13));

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
      child: child,
    );
  }

  Widget _sectionCard({required String titre, required _SectionStatus status, required String detail, required VoidCallback onAdd, required Widget child}) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                _sectionBadge(status, detail: detail),
              ]),
              TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 15), label: const Text('Ajouter')),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _sectionBadge(_SectionStatus status, {String? detail}) {
    Color color;
    Color bg;
    switch (status) {
      case _SectionStatus.vide:
        color = AppColors.brick;
        bg = AppColors.brickSoft;
        break;
      case _SectionStatus.partiel:
        color = AppColors.amber;
        bg = AppColors.amberSoft;
        break;
      case _SectionStatus.complet:
        color = AppColors.green;
        bg = AppColors.greenSoft;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(detail ?? '0', style: monoStyle(size: 10.5, color: color, weight: FontWeight.w600)),
    );
  }
}

class _CompetenceDialog extends StatefulWidget {
  const _CompetenceDialog();
  @override
  State<_CompetenceDialog> createState() => _CompetenceDialogState();
}

class _CompetenceDialogState extends State<_CompetenceDialog> {
  final _nomController = TextEditingController();
  final _domaineController = TextEditingController();
  final _outilsController = TextEditingController();
  final _itemsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une compétence'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom (ex. CATIA)')),
              const SizedBox(height: 12),
              TextField(controller: _domaineController, decoration: const InputDecoration(labelText: 'Domaine (ex. Conception mécanique)')),
              const SizedBox(height: 12),
              TextField(
                controller: _itemsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ce que tu sais concrètement faire',
                  hintText: 'Modélisation 3D, Mise en plan, Réalisation d\'assemblage',
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: _outilsController, decoration: const InputDecoration(labelText: 'Outils associés (optionnel), séparés par des virgules')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_nomController.text.trim().isEmpty) return;
            Navigator.pop(context, Competence(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              nom: _nomController.text.trim(),
              domaine: _domaineController.text.trim(),
              items: _itemsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
              outils: _outilsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
            ));
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _ExperienceDialog extends StatefulWidget {
  final Experience? initial;
  const _ExperienceDialog({this.initial});
  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  late final _titreController = TextEditingController(text: widget.initial?.titre ?? '');
  late final _entrepriseController = TextEditingController(text: widget.initial?.entreprise ?? '');
  late final _contexteController = TextEditingController(text: widget.initial?.contexte ?? '');
  late final _outilsController = TextEditingController(text: widget.initial?.outilsUtilises.join(', ') ?? '');
  late final _domaineController = TextEditingController(text: widget.initial?.domaine ?? '');
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    _dateDebut = widget.initial?.dateDebut;
    _dateFin = widget.initial?.dateFin;
  }

  Future<void> _pickDateDebut() async {
    final picked = await showDatePicker(context: context, initialDate: _dateDebut ?? DateTime.now(), firstDate: DateTime(2015), lastDate: DateTime(2030));
    if (picked == null) return;
    setState(() {
      _dateDebut = picked;
      if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) _dateFin = null;
    });
  }

  Future<void> _pickDateFin() async {
    if (_dateDebut == null) return;
    final picked = await showDatePicker(context: context, initialDate: _dateFin != null && !_dateFin!.isBefore(_dateDebut!) ? _dateFin! : _dateDebut!, firstDate: _dateDebut!, lastDate: DateTime(2030));
    if (picked == null) return;
    setState(() => _dateFin = picked);
  }

  String _label(DateTime? d, String empty) => d == null ? empty : '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Modifier l\'expérience' : 'Ajouter une expérience'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _titreController, decoration: const InputDecoration(labelText: 'Titre')),
            const SizedBox(height: 12),
            TextField(controller: _entrepriseController, decoration: const InputDecoration(labelText: 'Entreprise')),
            const SizedBox(height: 12),
            TextField(controller: _domaineController, decoration: const InputDecoration(labelText: 'Domaine')),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: OutlinedButton(onPressed: _pickDateDebut, child: Text(_label(_dateDebut, 'Date début')))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                OutlinedButton(onPressed: _dateDebut == null ? null : _pickDateFin, child: Text(_label(_dateFin, 'Date fin (optionnel)'))),
                if (_dateDebut == null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text('Choisis d\'abord la date de début', style: monoStyle(size: 10.5))),
              ])),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _contexteController, maxLines: 3, decoration: const InputDecoration(labelText: 'Contexte / description')),
            const SizedBox(height: 12),
            TextField(controller: _outilsController, decoration: const InputDecoration(labelText: 'Outils utilisés, séparés par des virgules')),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_titreController.text.trim().isEmpty || _dateDebut == null) return;
            Navigator.pop(context, Experience(
              id: widget.initial?.id ?? '',
              titre: _titreController.text.trim(),
              entreprise: _entrepriseController.text.trim(),
              dateDebut: _dateDebut!,
              dateFin: _dateFin,
              contexte: _contexteController.text.trim(),
              outilsUtilises: _outilsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
              domaine: _domaineController.text.trim(),
            ));
          },
          child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
        ),
      ],
    );
  }
}

class _FormationDialog extends StatefulWidget {
  final Formation? initial;
  const _FormationDialog({this.initial});
  @override
  State<_FormationDialog> createState() => _FormationDialogState();
}

class _FormationDialogState extends State<_FormationDialog> {
  late final _diplomeController = TextEditingController(text: widget.initial?.diplome ?? '');
  late final _etablissementController = TextEditingController(text: widget.initial?.etablissement ?? '');
  late final _mentionController = TextEditingController(text: widget.initial?.mention ?? '');
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    _dateDebut = widget.initial?.dateDebut;
    _dateFin = widget.initial?.dateFin;
  }

  Future<void> _pickDateDebut() async {
    final picked = await showDatePicker(context: context, initialDate: _dateDebut ?? DateTime.now(), firstDate: DateTime(2010), lastDate: DateTime(2030));
    if (picked == null) return;
    setState(() {
      _dateDebut = picked;
      if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) _dateFin = null;
    });
  }

  Future<void> _pickDateFin() async {
    if (_dateDebut == null) return;
    final picked = await showDatePicker(context: context, initialDate: _dateFin != null && !_dateFin!.isBefore(_dateDebut!) ? _dateFin! : _dateDebut!, firstDate: _dateDebut!, lastDate: DateTime(2030));
    if (picked == null) return;
    setState(() => _dateFin = picked);
  }

  String _label(DateTime? d, String empty) => d == null ? empty : '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Modifier la formation' : 'Ajouter une formation'),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _diplomeController, decoration: const InputDecoration(labelText: 'Diplôme')),
          const SizedBox(height: 12),
          TextField(controller: _etablissementController, decoration: const InputDecoration(labelText: 'Établissement')),
          const SizedBox(height: 12),
          TextField(controller: _mentionController, decoration: const InputDecoration(labelText: 'Mention (optionnel)')),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: OutlinedButton(onPressed: _pickDateDebut, child: Text(_label(_dateDebut, 'Date début')))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OutlinedButton(onPressed: _dateDebut == null ? null : _pickDateFin, child: Text(_label(_dateFin, 'Date fin (optionnel)'))),
              if (_dateDebut == null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text('Choisis d\'abord la date de début', style: monoStyle(size: 10.5))),
            ])),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_diplomeController.text.trim().isEmpty || _dateDebut == null) return;
            Navigator.pop(context, Formation(
              id: widget.initial?.id ?? '',
              diplome: _diplomeController.text.trim(),
              etablissement: _etablissementController.text.trim(),
              dateDebut: _dateDebut!,
              dateFin: _dateFin,
              mention: _mentionController.text.trim().isEmpty ? null : _mentionController.text.trim(),
            ));
          },
          child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
        ),
      ],
    );
  }
}

class _ProjetDialog extends StatefulWidget {
  final Projet? initial;
  const _ProjetDialog({this.initial});
  @override
  State<_ProjetDialog> createState() => _ProjetDialogState();
}

class _ProjetDialogState extends State<_ProjetDialog> {
  late final _titreController = TextEditingController(text: widget.initial?.titre ?? '');
  late final _contexteController = TextEditingController(text: widget.initial?.contexte ?? '');
  late final _outilsController = TextEditingController(text: widget.initial?.outils.join(', ') ?? '');
  late final _lienController = TextEditingController(text: widget.initial?.lien ?? '');
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    _dateDebut = widget.initial?.dateDebut;
    _dateFin = widget.initial?.dateFin;
  }

  Future<void> _pickDateDebut() async {
    final picked = await showDatePicker(context: context, initialDate: _dateDebut ?? DateTime.now(), firstDate: DateTime(2015), lastDate: DateTime(2030));
    if (picked == null) return;
    setState(() {
      _dateDebut = picked;
      if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) _dateFin = null;
    });
  }

  Future<void> _pickDateFin() async {
    if (_dateDebut == null) return;
    final picked = await showDatePicker(context: context, initialDate: _dateFin != null && !_dateFin!.isBefore(_dateDebut!) ? _dateFin! : _dateDebut!, firstDate: _dateDebut!, lastDate: DateTime(2030));
    if (picked == null) return;
    setState(() => _dateFin = picked);
  }

  String _label(DateTime? d, String empty) => d == null ? empty : '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Modifier le projet' : 'Ajouter un projet'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _titreController, decoration: const InputDecoration(labelText: 'Titre du projet')),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: OutlinedButton(onPressed: _pickDateDebut, child: Text(_label(_dateDebut, 'Date début (optionnel)')))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                OutlinedButton(onPressed: _dateDebut == null ? null : _pickDateFin, child: Text(_label(_dateFin, 'Date fin (optionnel)'))),
                if (_dateDebut == null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text('Choisis d\'abord la date de début', style: monoStyle(size: 10.5))),
              ])),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _contexteController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(controller: _outilsController, decoration: const InputDecoration(labelText: 'Outils utilisés, séparés par des virgules')),
            const SizedBox(height: 12),
            TextField(controller: _lienController, decoration: const InputDecoration(labelText: 'Lien (GitHub, démo…) — optionnel')),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_titreController.text.trim().isEmpty) return;
            Navigator.pop(context, Projet(
              id: widget.initial?.id ?? '',
              titre: _titreController.text.trim(),
              contexte: _contexteController.text.trim(),
              outils: _outilsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
              lien: _lienController.text.trim().isEmpty ? null : _lienController.text.trim(),
              dateDebut: _dateDebut,
              dateFin: _dateFin,
            ));
          },
          child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
        ),
      ],
    );
  }
}

class _LangueDialog extends StatefulWidget {
  const _LangueDialog();
  @override
  State<_LangueDialog> createState() => _LangueDialogState();
}

class _LangueDialogState extends State<_LangueDialog> {
  final _nomController = TextEditingController();
  final _scoreController = TextEditingController();
  NiveauLangue _niveau = NiveauLangue.b2;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une langue'),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Langue (ex. Anglais)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<NiveauLangue>(
            value: _niveau,
            decoration: const InputDecoration(labelText: 'Niveau'),
            items: NiveauLangue.values.map((n) => DropdownMenuItem(value: n, child: Text(niveauLangueLabels[n]!))).toList(),
            onChanged: (v) => setState(() => _niveau = v ?? _niveau),
          ),
          const SizedBox(height: 12),
          TextField(controller: _scoreController, decoration: const InputDecoration(labelText: 'Score (optionnel, ex. TOEIC 895)')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_nomController.text.trim().isEmpty) return;
            Navigator.pop(context, Langue(nom: _nomController.text.trim(), niveau: _niveau, score: _scoreController.text.trim().isEmpty ? null : _scoreController.text.trim()));
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _CertificationDialog extends StatefulWidget {
  const _CertificationDialog();
  @override
  State<_CertificationDialog> createState() => _CertificationDialogState();
}

class _CertificationDialogState extends State<_CertificationDialog> {
  final _nomController = TextEditingController();
  final _organismeController = TextEditingController();
  final _anneeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une certification'),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom (ex. Habilitation électrique B0)')),
          const SizedBox(height: 12),
          TextField(controller: _organismeController, decoration: const InputDecoration(labelText: 'Organisme (optionnel)')),
          const SizedBox(height: 12),
          TextField(controller: _anneeController, decoration: const InputDecoration(labelText: 'Année (optionnel)')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_nomController.text.trim().isEmpty) return;
            Navigator.pop(context, Certification(
              nom: _nomController.text.trim(),
              organisme: _organismeController.text.trim().isEmpty ? null : _organismeController.text.trim(),
              annee: _anneeController.text.trim().isEmpty ? null : _anneeController.text.trim(),
            ));
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _ConnaissanceDialog extends StatefulWidget {
  const _ConnaissanceDialog();
  @override
  State<_ConnaissanceDialog> createState() => _ConnaissanceDialogState();
}

class _ConnaissanceDialogState extends State<_ConnaissanceDialog> {
  final _nomController = TextEditingController();
  NiveauConnaissance _niveau = NiveauConnaissance.maitrise;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une connaissance académique'),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Matière (ex. Mécanique des fluides)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<NiveauConnaissance>(
            value: _niveau,
            decoration: const InputDecoration(labelText: 'Niveau'),
            items: NiveauConnaissance.values.map((n) => DropdownMenuItem(value: n, child: Text(niveauConnaissanceLabels[n]!))).toList(),
            onChanged: (v) => setState(() => _niveau = v ?? _niveau),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_nomController.text.trim().isEmpty) return;
            Navigator.pop(context, ConnaissanceAcademique(nom: _nomController.text.trim(), niveau: _niveau));
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _SimpleTagDialog extends StatefulWidget {
  final String titre;
  final String hint;
  const _SimpleTagDialog({required this.titre, required this.hint});
  @override
  State<_SimpleTagDialog> createState() => _SimpleTagDialogState();
}

class _SimpleTagDialogState extends State<_SimpleTagDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titre),
      content: SizedBox(width: 320, child: TextField(controller: _controller, decoration: InputDecoration(labelText: widget.hint), autofocus: true)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Ajouter')),
      ],
    );
  }
}
