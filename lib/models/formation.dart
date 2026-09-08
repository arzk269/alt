import 'package:cloud_firestore/cloud_firestore.dart';

class Formation {
  final String id;
  final String diplome;
  final String etablissement;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final String? mention;

  Formation({
    required this.id,
    required this.diplome,
    required this.etablissement,
    required this.dateDebut,
    this.dateFin,
    this.mention,
  });

  factory Formation.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Formation(
      id: doc.id,
      diplome: data['diplome'] as String,
      etablissement: data['etablissement'] as String,
      dateDebut: (data['dateDebut'] as Timestamp).toDate(),
      dateFin: (data['dateFin'] as Timestamp?)?.toDate(),
      mention: data['mention'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'diplome': diplome,
      'etablissement': etablissement,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': dateFin != null ? Timestamp.fromDate(dateFin!) : null,
      'mention': mention,
    };
  }
}
