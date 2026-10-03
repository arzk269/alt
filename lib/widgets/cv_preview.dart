import 'package:flutter/material.dart';
import '../models/candidature.dart';
import '../models/profil.dart';
import '../models/formation.dart';
import '../models/langue.dart';
import '../theme/app_theme.dart';

class CvPreview extends StatelessWidget {
  final Candidature candidature;
  final Profil profil;
  final List<Formation> formations;
  const CvPreview({super.key, required this.candidature, required this.profil, required this.formations});

  @override
  Widget build(BuildContext context) {
    final competences = candidature.competencesAMettreEnAvant
        .map((nom) => profil.competences.where((c) => c.nom == nom).firstOrNull)
        .whereType<dynamic>()
        .toList();

    final connaissances = candidature.connaissancesAMettreEnAvant
        .map((nom) => profil.connaissancesAcademiques.where((c) => c.nom == nom).firstOrNull)
        .whereType<dynamic>()
        .toList();

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 620,
          constraints: const BoxConstraints(minHeight: 840),
          padding: const EdgeInsets.all(44),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Container(
                      width: 64,
                      height: 64,
                      color: AppColors.blue,
                      child: profil.photoUrl != null
                          ? Image.network(profil.photoUrl!, fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => _initialsAvatar())
                          : _initialsAvatar(),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${profil.prenom} ${profil.nom}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        const SizedBox(height: 3),
                        Text(candidature.domainePoste ?? '', style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (profil.telephone.isNotEmpty) Text(profil.telephone, style: monoStyle(size: 11)),
                            if (profil.emailCv.isNotEmpty) Text(profil.emailCv, style: monoStyle(size: 11)),
                            if (profil.ville.isNotEmpty) Text(profil.ville, style: monoStyle(size: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 36, color: AppColors.line),

              if (candidature.profilResume != null && candidature.profilResume!.isNotEmpty) ...[
                Text(candidature.profilResume!, style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.inkSoft)),
                const SizedBox(height: 24),
              ],

              if (candidature.experiencesTexte.isNotEmpty) ...[
                _sectionTitle('EXPÉRIENCES & PROJETS'),
                const SizedBox(height: 10),
                ...candidature.experiencesTexte.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (e['entreprise'] != null && e['entreprise']!.isNotEmpty)
                            ? '${e['titre']} — ${e['entreprise']}'
                            : '${e['titre']}',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(e['description'] ?? '', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.4)),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],

              if (formations.isNotEmpty) ...[
                _sectionTitle('FORMATION'),
                const SizedBox(height: 10),
                ...formations.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${f.diplome} — ${f.etablissement}', style: const TextStyle(fontSize: 13)),
                )),
                const SizedBox(height: 12),
              ],

              if (competences.isNotEmpty) ...[
                _sectionTitle('COMPÉTENCES'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: competences.map((c) => _tag('${c.nom}')).toList(),
                ),
                const SizedBox(height: 12),
              ],

              if (connaissances.isNotEmpty) ...[
                _sectionTitle('CONNAISSANCES ACADÉMIQUES'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: connaissances.map((c) => _tag('${c.nom}')).toList(),
                ),
                const SizedBox(height: 12),
              ],

              if (profil.langues.isNotEmpty) ...[
                _sectionTitle('LANGUES'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profil.langues.map((l) => _tag('${l.nom} · ${niveauLangueLabels[l.niveau]}')).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsAvatar() {
    return Center(
      child: Text(
        '${profil.prenom.isNotEmpty ? profil.prenom[0] : ''}${profil.nom.isNotEmpty ? profil.nom[0] : ''}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: monoStyle(size: 10.5, weight: FontWeight.w700, color: AppColors.inkFaint));

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: monoStyle(size: 11, color: AppColors.blue)),
  );
}
