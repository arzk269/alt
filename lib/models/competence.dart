class Competence {
  final String id;
  final String nom;
  final String domaine;
  final List<String> outils;

  Competence({
    required this.id,
    required this.nom,
    required this.domaine,
    this.outils = const [],
  });

  factory Competence.fromMap(Map<String, dynamic> map) {
    return Competence(
      id: map['id'] as String,
      nom: map['nom'] as String,
      domaine: map['domaine'] as String,
      outils: List<String>.from(map['outils'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'domaine': domaine,
      'outils': outils,
    };
  }
}
