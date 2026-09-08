class Certification {
  final String nom;
  final String? organisme;
  final String? annee;

  Certification({required this.nom, this.organisme, this.annee});

  factory Certification.fromMap(Map<String, dynamic> map) {
    return Certification(
      nom: map['nom'] as String,
      organisme: map['organisme'] as String?,
      annee: map['annee'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'nom': nom, 'organisme': organisme, 'annee': annee};
  }
}
