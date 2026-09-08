enum NiveauConnaissance { notions, maitrise, approfondi }

const Map<NiveauConnaissance, String> niveauConnaissanceLabels = {
  NiveauConnaissance.notions: 'Notions',
  NiveauConnaissance.maitrise: 'Maîtrisé',
  NiveauConnaissance.approfondi: 'Approfondi',
};

String niveauConnaissanceToString(NiveauConnaissance n) => n.name;

NiveauConnaissance niveauConnaissanceFromString(String v) {
  return NiveauConnaissance.values.firstWhere((e) => e.name == v, orElse: () => NiveauConnaissance.maitrise);
}

class ConnaissanceAcademique {
  final String nom;
  final NiveauConnaissance niveau;

  ConnaissanceAcademique({required this.nom, required this.niveau});

  factory ConnaissanceAcademique.fromMap(Map<String, dynamic> map) {
    return ConnaissanceAcademique(
      nom: map['nom'] as String,
      niveau: niveauConnaissanceFromString(map['niveau'] as String? ?? 'maitrise'),
    );
  }

  Map<String, dynamic> toMap() {
    return {'nom': nom, 'niveau': niveauConnaissanceToString(niveau)};
  }
}
