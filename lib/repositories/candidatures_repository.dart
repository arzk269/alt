import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/candidature.dart';

class CandidaturesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('candidatures');
  }

  Stream<List<Candidature>> watchAll(String uid) {
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Candidature.fromFirestore(doc)).toList());
  }

  Future<String> ajouterCandidature(String uid, Candidature candidature) async {
    final docRef = candidature.id.isEmpty ? _collection(uid).doc() : _collection(uid).doc(candidature.id);
    await docRef.set(candidature.toMap());
    return docRef.id;
  }

  Future<void> changerStatut(String uid, String candidatureId, TypeEvenement nouvelEvenement) async {
    final docRef = _collection(uid).doc(candidatureId);
    final nouveauStatut = statutFromString(evenementToString(nouvelEvenement));
    final evenement = EvenementHistorique(type: nouvelEvenement, date: DateTime.now());

    await docRef.update({
      'statut': statutToString(nouveauStatut),
      'historique': FieldValue.arrayUnion([evenement.toMap()]),
    });
  }

  Future<void> supprimer(String uid, String candidatureId) {
    return _collection(uid).doc(candidatureId).delete();
  }
}
