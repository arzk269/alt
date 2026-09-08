import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/projet.dart';

class ProjetRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('projets');
  }

  Stream<List<Projet>> watchAll(String uid) {
    return _collection(uid).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Projet.fromFirestore(doc)).toList());
  }

  Future<void> ajouter(String uid, Projet projet) {
    return _collection(uid).doc().set(projet.toMap());
  }

  Future<void> modifier(String uid, String id, Projet projet) {
    return _collection(uid).doc(id).set(projet.toMap());
  }

  Future<void> supprimer(String uid, String projetId) {
    return _collection(uid).doc(projetId).delete();
  }
}
