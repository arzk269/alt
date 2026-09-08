import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploaderPhotoProfil(String uid, Uint8List bytes) async {
    final ref = _storage.ref().child('profils/$uid/photo.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> supprimerPhotoProfil(String uid) async {
    final ref = _storage.ref().child('profils/$uid/photo.jpg');
    try {
      await ref.delete();
    } catch (_) {
      // Le fichier n'existe déjà plus, rien à faire.
    }
  }
}
