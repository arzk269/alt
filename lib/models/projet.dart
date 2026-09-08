import 'package:cloud_firestore/cloud_firestore.dart';

class Projet {
  final String id;
  final String titre;
  final String contexte;
  final List<String> outils;
  final String? resultat;
  final String? lien;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  Projet({
    required this.id,
    required this.titre,
    required this.contexte,
    this.outils = const [],
    this.resultat,
    this.lien,
    this.dateDebut,
    this.dateFin,
  });

  factory Projet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Projet(
      id: doc.id,
      titre: data['titre'] as String,
      contexte: data['contexte'] as String? ?? '',
      outils: List<String>.from(data['outils'] ?? []),
      resultat: data['resultat'] as String?,
      lien: data['lien'] as String?,
      dateDebut: (data['dateDebut'] as Timestamp?)?.toDate(),
      dateFin: (data['dateFin'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'contexte': contexte,
      'outils': outils,
      'resultat': resultat,
      'lien': lien,
      'dateDebut': dateDebut != null ? Timestamp.fromDate(dateDebut!) : null,
      'dateFin': dateFin != null ? Timestamp.fromDate(dateFin!) : null,
    };
  }
}
