import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experience.dart';

class ExperienceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('experiences');
  }

  Stream<List<Experience>> watchAll(String uid) {
    return _collection(uid)
        .orderBy('dateDebut', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Experience.fromFirestore(doc)).toList());
  }

  Future<void> ajouter(String uid, Experience experience) {
    return _collection(uid).doc().set(experience.toMap());
  }

  Future<void> modifier(String uid, String id, Experience experience) {
    return _collection(uid).doc(id).set(experience.toMap());
  }

  Future<void> supprimer(String uid, String experienceId) {
    return _collection(uid).doc(experienceId).delete();
  }
}
