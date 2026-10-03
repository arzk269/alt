import 'package:cloud_functions/cloud_functions.dart';

class MatchingResultDto {
  final String poste;
  final String entreprise;
  final String domainePoste;
  final int scoreMatching;
  final List<String> competencesMatchees;
  final List<String> competencesManquantes;
  final List<String> raisonsMatching;

  MatchingResultDto({
    required this.poste,
    required this.entreprise,
    required this.domainePoste,
    required this.scoreMatching,
    required this.competencesMatchees,
    required this.competencesManquantes,
    required this.raisonsMatching,
  });

  factory MatchingResultDto.fromMap(Map<String, dynamic> map) {
    return MatchingResultDto(
      poste: map['poste'] as String? ?? '',
      entreprise: map['entreprise'] as String? ?? '',
      domainePoste: map['domainePoste'] as String? ?? '',
      scoreMatching: (map['scoreMatching'] as num?)?.toInt() ?? 0,
      competencesMatchees: List<String>.from(map['competencesMatchees'] ?? []),
      competencesManquantes: List<String>.from(map['competencesManquantes'] ?? []),
      raisonsMatching: List<String>.from(map['raisonsMatching'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'domainePoste': domainePoste,
      'scoreMatching': scoreMatching,
      'competencesMatchees': competencesMatchees,
      'competencesManquantes': competencesManquantes,
      'raisonsMatching': raisonsMatching,
    };
  }
}

class GenerationResultDto {
  final String profilResume;
  final List<Map<String, String>> experiencesTexte;
  final List<String> competencesAMettreEnAvant;
  final List<String> connaissancesAMettreEnAvant;
  final String lettreMotivation;

  GenerationResultDto({
    required this.profilResume,
    required this.experiencesTexte,
    required this.competencesAMettreEnAvant,
    required this.connaissancesAMettreEnAvant,
    required this.lettreMotivation,
  });

  factory GenerationResultDto.fromMap(Map<String, dynamic> map) {
    return GenerationResultDto(
      profilResume: map['profilResume'] as String? ?? '',
      experiencesTexte: List<Map<String, String>>.from(
        (map['experiencesTexte'] as List? ?? []).map((e) => Map<String, String>.from(e)),
      ),
      competencesAMettreEnAvant: List<String>.from(map['competencesAMettreEnAvant'] ?? []),
      connaissancesAMettreEnAvant: List<String>.from(map['connaissancesAMettreEnAvant'] ?? []),
      lettreMotivation: map['lettreMotivation'] as String? ?? '',
    );
  }
}

class MatchingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<MatchingResultDto> matcherOffre(String offreTexteBrut) async {
    final callable = _functions.httpsCallable('matcherOffre');
    final result = await callable.call({'offreTexteBrut': offreTexteBrut});
    return MatchingResultDto.fromMap(Map<String, dynamic>.from(result.data));
  }

  Future<GenerationResultDto> genererCandidature({
    required String offreTexteBrut,
    required String poste,
    required String entreprise,
    required MatchingResultDto matching,
  }) async {
    final callable = _functions.httpsCallable('genererCandidature');
    final result = await callable.call({
      'offreTexteBrut': offreTexteBrut,
      'poste': poste,
      'entreprise': entreprise,
      'matching': matching.toMap(),
    });
    return GenerationResultDto.fromMap(Map<String, dynamic>.from(result.data));
  }
}
