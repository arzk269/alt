import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profil.dart';

class ProfilRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _db.collection('users');

  Stream<Profil?> watchProfil(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Profil.fromFirestore(doc);
    });
  }

  Future<void> creerProfil(Profil profil) {
    return _collection.doc(profil.uid).set(profil.toMap());
  }

  Future<void> mettreAJourProfil(Profil profil) {
    return _collection.doc(profil.uid).update(profil.toMap());
  }

  Future<void> supprimerPhoto(String uid) {
    return _collection.doc(uid).update({'photoUrl': FieldValue.delete()});
  }

  /// Met à jour uniquement l'horodatage — utilisé quand une sous-collection
  /// (formations, expériences, projets) change, pour que "dernière modification"
  /// reflète tout changement du profil, pas seulement ses champs directs.
  Future<void> touchUpdatedAt(String uid) {
    return _collection.doc(uid).update({'updatedAt': FieldValue.serverTimestamp()});
  }
}
