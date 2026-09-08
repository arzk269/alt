import 'package:cloud_firestore/cloud_firestore.dart';
import 'competence.dart';
import 'langue.dart';
import 'certification.dart';
import 'connaissance_academique.dart';

enum TypeRecherche { alternance, stage }

class Profil {
  final String uid;
  final String nom;
  final String prenom;
  final String email;
  final String emailCv;
  final String telephone;
  final String ville;
  final String? linkedinUrl;
  final String? githubUrl;
  final TypeRecherche typeRecherche;
  final DateTime? dateDebutSouhaitee;
  final DateTime? dateFinSouhaitee;
  final List<Competence> competences;
  final List<Langue> langues;
  final List<Certification> certifications;
  final List<ConnaissanceAcademique> connaissancesAcademiques;
  final List<String> permis;
  final List<String> centresInteret;
  final String mobilite;
  final String? photoUrl;
  final DateTime? updatedAt;

  Profil({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.email,
    this.emailCv = '',
    this.telephone = '',
    this.ville = '',
    this.linkedinUrl,
    this.githubUrl,
    required this.typeRecherche,
    this.dateDebutSouhaitee,
    this.dateFinSouhaitee,
    this.competences = const [],
    this.langues = const [],
    this.certifications = const [],
    this.connaissancesAcademiques = const [],
    this.permis = const [],
    this.centresInteret = const [],
    this.mobilite = '',
    this.photoUrl,
    this.updatedAt,
  });

  factory Profil.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final disponibilite = data['disponibilite'] as Map<String, dynamic>? ?? {};
    return Profil(
      uid: doc.id,
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      email: data['email'] as String? ?? '',
      emailCv: data['emailCv'] as String? ?? '',
      telephone: data['telephone'] as String? ?? '',
      ville: data['ville'] as String? ?? '',
      linkedinUrl: data['linkedinUrl'] as String?,
      githubUrl: data['githubUrl'] as String?,
      typeRecherche: disponibilite['type'] == 'stage' ? TypeRecherche.stage : TypeRecherche.alternance,
      dateDebutSouhaitee: (disponibilite['dateDebutSouhaitee'] as Timestamp?)?.toDate(),
      dateFinSouhaitee: (disponibilite['dateFinSouhaitee'] as Timestamp?)?.toDate(),
      competences: List<Competence>.from(
        (data['competences'] as List? ?? []).map((c) => Competence.fromMap(Map<String, dynamic>.from(c))),
      ),
      langues: List<Langue>.from(
        (data['langues'] as List? ?? []).map((l) => Langue.fromMap(Map<String, dynamic>.from(l))),
      ),
      certifications: List<Certification>.from(
        (data['certifications'] as List? ?? []).map((c) => Certification.fromMap(Map<String, dynamic>.from(c))),
      ),
      connaissancesAcademiques: List<ConnaissanceAcademique>.from(
        (data['connaissancesAcademiques'] as List? ?? []).map((c) => ConnaissanceAcademique.fromMap(Map<String, dynamic>.from(c))),
      ),
      permis: List<String>.from(data['permis'] ?? []),
      centresInteret: List<String>.from(data['centresInteret'] ?? []),
      mobilite: data['mobilite'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'emailCv': emailCv,
      'telephone': telephone,
      'ville': ville,
      'linkedinUrl': linkedinUrl,
      'githubUrl': githubUrl,
      'disponibilite': {
        'type': typeRecherche == TypeRecherche.stage ? 'stage' : 'alternance',
        'dateDebutSouhaitee': dateDebutSouhaitee != null ? Timestamp.fromDate(dateDebutSouhaitee!) : null,
        'dateFinSouhaitee': dateFinSouhaitee != null ? Timestamp.fromDate(dateFinSouhaitee!) : null,
      },
      'competences': competences.map((c) => c.toMap()).toList(),
      'langues': langues.map((l) => l.toMap()).toList(),
      'certifications': certifications.map((c) => c.toMap()).toList(),
      'connaissancesAcademiques': connaissancesAcademiques.map((c) => c.toMap()).toList(),
      'permis': permis,
      'centresInteret': centresInteret,
      'mobilite': mobilite,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Profil copyWith({
    String? nom,
    String? prenom,
    String? emailCv,
    String? telephone,
    String? ville,
    String? linkedinUrl,
    String? githubUrl,
    TypeRecherche? typeRecherche,
    DateTime? dateDebutSouhaitee,
    DateTime? dateFinSouhaitee,
    List<Competence>? competences,
    List<Langue>? langues,
    List<Certification>? certifications,
    List<ConnaissanceAcademique>? connaissancesAcademiques,
    List<String>? permis,
    List<String>? centresInteret,
    String? mobilite,
    String? photoUrl,
    bool clearPhoto = false,
  }) {
    return Profil(
      uid: uid,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email,
      emailCv: emailCv ?? this.emailCv,
      telephone: telephone ?? this.telephone,
      ville: ville ?? this.ville,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      typeRecherche: typeRecherche ?? this.typeRecherche,
      dateDebutSouhaitee: dateDebutSouhaitee ?? this.dateDebutSouhaitee,
      dateFinSouhaitee: dateFinSouhaitee ?? this.dateFinSouhaitee,
      competences: competences ?? this.competences,
      langues: langues ?? this.langues,
      certifications: certifications ?? this.certifications,
      connaissancesAcademiques: connaissancesAcademiques ?? this.connaissancesAcademiques,
      permis: permis ?? this.permis,
      centresInteret: centresInteret ?? this.centresInteret,
      mobilite: mobilite ?? this.mobilite,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      updatedAt: updatedAt,
    );
  }
}
