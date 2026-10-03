import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutCandidature { aPostuler, envoyee, relance, entretien, refus }

enum TypeEvenement { ajoutee, aPostuler, envoyee, relance, entretien, refus }

StatutCandidature statutFromString(String value) {
  switch (value) {
    case 'envoyee': return StatutCandidature.envoyee;
    case 'relance': return StatutCandidature.relance;
    case 'entretien': return StatutCandidature.entretien;
    case 'refus': return StatutCandidature.refus;
    default: return StatutCandidature.aPostuler;
  }
}

String statutToString(StatutCandidature statut) {
  switch (statut) {
    case StatutCandidature.envoyee: return 'envoyee';
    case StatutCandidature.relance: return 'relance';
    case StatutCandidature.entretien: return 'entretien';
    case StatutCandidature.refus: return 'refus';
    case StatutCandidature.aPostuler: return 'a_postuler';
  }
}

TypeEvenement evenementFromString(String value) {
  switch (value) {
    case 'a_postuler': return TypeEvenement.aPostuler;
    case 'envoyee': return TypeEvenement.envoyee;
    case 'relance': return TypeEvenement.relance;
    case 'entretien': return TypeEvenement.entretien;
    case 'refus': return TypeEvenement.refus;
    default: return TypeEvenement.ajoutee;
  }
}

String evenementToString(TypeEvenement type) {
  switch (type) {
    case TypeEvenement.aPostuler: return 'a_postuler';
    case TypeEvenement.envoyee: return 'envoyee';
    case TypeEvenement.relance: return 'relance';
    case TypeEvenement.entretien: return 'entretien';
    case TypeEvenement.refus: return 'refus';
    case TypeEvenement.ajoutee: return 'ajoutee';
  }
}

class EvenementHistorique {
  final TypeEvenement type;
  final DateTime date;

  EvenementHistorique({required this.type, required this.date});

  factory EvenementHistorique.fromMap(Map<String, dynamic> map) {
    return EvenementHistorique(
      type: evenementFromString(map['type'] as String),
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': evenementToString(type),
      'date': Timestamp.fromDate(date),
    };
  }
}

class Candidature {
  final String id;
  final String poste;
  final String entreprise;
  final String offreTexteBrut;
  final String? offreUrl;
  final String? domainePoste;
  final List<String> competencesMatchees;
  final int scoreMatching;
  final List<String> raisonsMatching;
  final String? profilResume;
  final List<Map<String, String>> experiencesTexte;
  final List<String> competencesAMettreEnAvant;
  final List<String> connaissancesAMettreEnAvant;
  final String? cvGenereUrl;
  final String? lmGeneree;
  final StatutCandidature statut;
  final List<EvenementHistorique> historique;
  final DateTime createdAt;

  Candidature({
    required this.id,
    required this.poste,
    required this.entreprise,
    required this.offreTexteBrut,
    this.offreUrl,
    this.domainePoste,
    this.competencesMatchees = const [],
    required this.scoreMatching,
    this.raisonsMatching = const [],
    this.profilResume,
    this.experiencesTexte = const [],
    this.competencesAMettreEnAvant = const [],
    this.connaissancesAMettreEnAvant = const [],
    this.cvGenereUrl,
    this.lmGeneree,
    this.statut = StatutCandidature.aPostuler,
    this.historique = const [],
    required this.createdAt,
  });

  factory Candidature.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Candidature(
      id: doc.id,
      poste: data['poste'] as String,
      entreprise: data['entreprise'] as String,
      offreTexteBrut: data['offreTexteBrut'] as String? ?? '',
      offreUrl: data['offreUrl'] as String?,
      domainePoste: data['domainePoste'] as String?,
      competencesMatchees: List<String>.from(data['competencesMatchees'] ?? []),
      scoreMatching: (data['scoreMatching'] as num?)?.toInt() ?? 0,
      raisonsMatching: List<String>.from(data['raisonsMatching'] ?? []),
      profilResume: data['profilResume'] as String?,
      experiencesTexte: List<Map<String, String>>.from(
        (data['experiencesTexte'] as List? ?? []).map((e) => Map<String, String>.from(e)),
      ),
      competencesAMettreEnAvant: List<String>.from(data['competencesAMettreEnAvant'] ?? []),
      connaissancesAMettreEnAvant: List<String>.from(data['connaissancesAMettreEnAvant'] ?? []),
      cvGenereUrl: data['cvGenereUrl'] as String?,
      lmGeneree: data['lmGeneree'] as String?,
      statut: statutFromString(data['statut'] as String? ?? 'a_postuler'),
      historique: List<EvenementHistorique>.from(
        (data['historique'] as List? ?? []).map((e) => EvenementHistorique.fromMap(Map<String, dynamic>.from(e))),
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'poste': poste,
      'entreprise': entreprise,
      'offreTexteBrut': offreTexteBrut,
      'offreUrl': offreUrl,
      'domainePoste': domainePoste,
      'competencesMatchees': competencesMatchees,
      'scoreMatching': scoreMatching,
      'raisonsMatching': raisonsMatching,
      'profilResume': profilResume,
      'experiencesTexte': experiencesTexte,
      'competencesAMettreEnAvant': competencesAMettreEnAvant,
      'connaissancesAMettreEnAvant': connaissancesAMettreEnAvant,
      'cvGenereUrl': cvGenereUrl,
      'lmGeneree': lmGeneree,
      'statut': statutToString(statut),
      'historique': historique.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Candidature copyWith({
    StatutCandidature? statut,
    List<EvenementHistorique>? historique,
    String? cvGenereUrl,
    String? lmGeneree,
  }) {
    return Candidature(
      id: id,
      poste: poste,
      entreprise: entreprise,
      offreTexteBrut: offreTexteBrut,
      offreUrl: offreUrl,
      domainePoste: domainePoste,
      competencesMatchees: competencesMatchees,
      scoreMatching: scoreMatching,
      raisonsMatching: raisonsMatching,
      profilResume: profilResume,
      experiencesTexte: experiencesTexte,
      competencesAMettreEnAvant: competencesAMettreEnAvant,
      connaissancesAMettreEnAvant: connaissancesAMettreEnAvant,
      cvGenereUrl: cvGenereUrl ?? this.cvGenereUrl,
      lmGeneree: lmGeneree ?? this.lmGeneree,
      statut: statut ?? this.statut,
      historique: historique ?? this.historique,
      createdAt: createdAt,
    );
  }
}
