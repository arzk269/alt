enum NiveauLangue { a1, a2, b1, b2, c1, c2, natif }

const Map<NiveauLangue, String> niveauLangueLabels = {
  NiveauLangue.a1: 'A1',
  NiveauLangue.a2: 'A2',
  NiveauLangue.b1: 'B1',
  NiveauLangue.b2: 'B2',
  NiveauLangue.c1: 'C1',
  NiveauLangue.c2: 'C2',
  NiveauLangue.natif: 'Natif',
};

String niveauLangueToString(NiveauLangue n) => n.name;

NiveauLangue niveauLangueFromString(String v) {
  return NiveauLangue.values.firstWhere((e) => e.name == v, orElse: () => NiveauLangue.b1);
}

class Langue {
  final String nom;
  final NiveauLangue niveau;
  final String? score;

  Langue({required this.nom, required this.niveau, this.score});

  factory Langue.fromMap(Map<String, dynamic> map) {
    return Langue(
      nom: map['nom'] as String,
      niveau: niveauLangueFromString(map['niveau'] as String? ?? 'b1'),
      score: map['score'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'nom': nom, 'niveau': niveauLangueToString(niveau), 'score': score};
  }
}
