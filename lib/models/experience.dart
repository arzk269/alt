import 'package:cloud_firestore/cloud_firestore.dart';

class Experience {
  final String id;
  final String titre;
  final String entreprise;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final String contexte;
  final List<String> outilsUtilises;
  final String? resultatChiffre;
  final String domaine;

  Experience({
    required this.id,
    required this.titre,
    required this.entreprise,
    required this.dateDebut,
    this.dateFin,
    required this.contexte,
    this.outilsUtilises = const [],
    this.resultatChiffre,
    required this.domaine,
  });

  factory Experience.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Experience(
      id: doc.id,
      titre: data['titre'] as String,
      entreprise: data['entreprise'] as String,
      dateDebut: (data['dateDebut'] as Timestamp).toDate(),
      dateFin: (data['dateFin'] as Timestamp?)?.toDate(),
      contexte: data['contexte'] as String,
      outilsUtilises: List<String>.from(data['outilsUtilises'] ?? []),
      resultatChiffre: data['resultatChiffre'] as String?,
      domaine: data['domaine'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'entreprise': entreprise,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': dateFin != null ? Timestamp.fromDate(dateFin!) : null,
      'contexte': contexte,
      'outilsUtilises': outilsUtilises,
      'resultatChiffre': resultatChiffre,
      'domaine': domaine,
    };
  }
}
