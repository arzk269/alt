import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../models/candidature.dart';
import '../models/profil.dart';
import '../models/formation.dart';
import '../models/langue.dart';

class PdfService {
  Future<void> genererEtTelecharger({
    required Candidature candidature,
    required Profil profil,
    required List<Formation> formations,
  }) async {
    final doc = pw.Document();

    pw.MemoryImage? photo;
    if (profil.photoUrl != null) {
      try {
        final resp = await http.get(Uri.parse(profil.photoUrl!));
        if (resp.statusCode == 200) {
          photo = pw.MemoryImage(resp.bodyBytes);
        }
      } catch (_) {
        // Pas de photo si le téléchargement échoue — le CV reste généré sans elle.
      }
    }

    final competences = candidature.competencesAMettreEnAvant
        .map((nom) => profil.competences.where((c) => c.nom == nom).firstOrNull)
        .whereType<dynamic>()
        .toList();
    final connaissances = candidature.connaissancesAMettreEnAvant
        .map((nom) => profil.connaissancesAcademiques.where((c) => c.nom == nom).firstOrNull)
        .whereType<dynamic>()
        .toList();

    final inkColor = PdfColor.fromInt(0xFF0F172A);
    final softColor = PdfColor.fromInt(0xFF475569);
    final faintColor = PdfColor.fromInt(0xFF94A3B8);
    final blueColor = PdfColor.fromInt(0xFF1E40AF);
    final blueSoft = PdfColor.fromInt(0xFFEFF6FF);
    final lineColor = PdfColor.fromInt(0xFFE2E8F0);

    pw.Widget tag(String text) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: pw.BoxDecoration(color: blueSoft, borderRadius: pw.BorderRadius.circular(3)),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: blueColor)),
    );

    pw.Widget sectionTitle(String text) => pw.Text(
      text,
      style: pw.TextStyle(fontSize: 9, color: faintColor, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (photo != null)
                    pw.ClipOval(child: pw.Image(photo, width: 56, height: 56, fit: pw.BoxFit.cover)),
                  if (photo != null) pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('${profil.prenom} ${profil.nom}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: inkColor)),
                        pw.SizedBox(height: 3),
                        pw.Text(candidature.domainePoste ?? '', style: pw.TextStyle(fontSize: 11, color: softColor)),
                        pw.SizedBox(height: 5),
                        pw.Row(children: [
                          if (profil.telephone.isNotEmpty) pw.Text(profil.telephone, style: pw.TextStyle(fontSize: 9, color: softColor)),
                          if (profil.telephone.isNotEmpty) pw.SizedBox(width: 10),
                          if (profil.emailCv.isNotEmpty) pw.Text(profil.emailCv, style: pw.TextStyle(fontSize: 9, color: softColor)),
                          if (profil.emailCv.isNotEmpty) pw.SizedBox(width: 10),
                          if (profil.ville.isNotEmpty) pw.Text(profil.ville, style: pw.TextStyle(fontSize: 9, color: softColor)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Divider(color: lineColor),
              pw.SizedBox(height: 14),

              if (candidature.profilResume != null && candidature.profilResume!.isNotEmpty) ...[
                pw.Text(candidature.profilResume!, style: pw.TextStyle(fontSize: 10, color: softColor, lineSpacing: 3)),
                pw.SizedBox(height: 18),
              ],

              if (candidature.experiencesTexte.isNotEmpty) ...[
                sectionTitle('EXPÉRIENCES & PROJETS'),
                pw.SizedBox(height: 8),
                ...candidature.experiencesTexte.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 9),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        (e['entreprise'] != null && e['entreprise']!.isNotEmpty)
                            ? '${e['titre']} — ${e['entreprise']}'
                            : '${e['titre']}',
                        style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: inkColor),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(e['description'] ?? '', style: pw.TextStyle(fontSize: 9.5, color: softColor, lineSpacing: 2)),
                    ],
                  ),
                )),
                pw.SizedBox(height: 8),
              ],

              if (formations.isNotEmpty) ...[
                sectionTitle('FORMATION'),
                pw.SizedBox(height: 8),
                ...formations.map((f) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text('${f.diplome} — ${f.etablissement}', style: pw.TextStyle(fontSize: 10, color: inkColor)),
                )),
                pw.SizedBox(height: 8),
              ],

              if (competences.isNotEmpty) ...[
                sectionTitle('COMPÉTENCES'),
                pw.SizedBox(height: 8),
                pw.Wrap(spacing: 6, runSpacing: 6, children: competences.map((c) => tag('${c.nom}')).toList()),
                pw.SizedBox(height: 8),
              ],

              if (connaissances.isNotEmpty) ...[
                sectionTitle('CONNAISSANCES ACADÉMIQUES'),
                pw.SizedBox(height: 8),
                pw.Wrap(spacing: 6, runSpacing: 6, children: connaissances.map((c) => tag('${c.nom}')).toList()),
                pw.SizedBox(height: 8),
              ],

              if (profil.langues.isNotEmpty) ...[
                sectionTitle('LANGUES'),
                pw.SizedBox(height: 8),
                pw.Wrap(spacing: 6, runSpacing: 6, children: profil.langues.map((l) => tag('${l.nom} · ${niveauLangueLabels[l.niveau]}')).toList()),
              ],
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await doc.save();
    final nomFichier = 'CV_${profil.prenom}_${profil.nom}_${candidature.entreprise}.pdf'.replaceAll(' ', '_');
    await Printing.sharePdf(bytes: bytes, filename: nomFichier);
  }
}
