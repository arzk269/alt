import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/formation.dart';

class FormationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('formations');
  }

  Stream<List<Formation>> watchAll(String uid) {
    return _collection(uid)
        .orderBy('dateDebut', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Formation.fromFirestore(doc)).toList());
  }

  Future<void> ajouter(String uid, Formation formation) {
    return _collection(uid).doc().set(formation.toMap());
  }

  Future<void> modifier(String uid, String id, Formation formation) {
    return _collection(uid).doc(id).set(formation.toMap());
  }

  Future<void> supprimer(String uid, String formationId) {
    return _collection(uid).doc(formationId).delete();
  }
}
