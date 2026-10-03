import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import Anthropic from "@anthropic-ai/sdk";

admin.initializeApp();
const db = admin.firestore();

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

interface MatchingResult {
  poste: string;
  entreprise: string;
  domainePoste: string;
  scoreMatching: number;
  competencesMatchees: string[];
  competencesManquantes: string[];
  raisonsMatching: string[];
}

interface GenerationResult {
  profilResume: string;
  experiencesTexte: { titre: string; entreprise: string; description: string }[];
  competencesAMettreEnAvant: string[];
  connaissancesAMettreEnAvant: string[];
  lettreMotivation: string;
}

async function chargerProfilComplet(uid: string) {
  const profilDoc = await db.collection("users").doc(uid).get();
  if (!profilDoc.exists) {
    throw new HttpsError("not-found", "Profil introuvable.");
  }
  const profil = profilDoc.data()!;

  const [experiencesSnap, formationsSnap, projetsSnap] = await Promise.all([
    db.collection("users").doc(uid).collection("experiences").get(),
    db.collection("users").doc(uid).collection("formations").get(),
    db.collection("users").doc(uid).collection("projets").get(),
  ]);

  return {
    profil,
    experiences: experiencesSnap.docs.map((d) => d.data()),
    formations: formationsSnap.docs.map((d) => d.data()),
    projets: projetsSnap.docs.map((d) => d.data()),
  };
}

function formaterProfilPourPrompt(
  data: Awaited<ReturnType<typeof chargerProfilComplet>>
): string {
  const { profil, experiences, formations, projets } = data;

  const competencesTxt =
    (profil.competences || [])
      .map((c: any) => `- ${c.nom} (${c.domaine}), outils: ${(c.outils || []).join(", ")}`)
      .join("\n") || "Aucune";

  const connaissancesTxt =
    (profil.connaissancesAcademiques || [])
      .map((c: any) => `- ${c.nom} (${c.niveau})`)
      .join("\n") || "Aucune";

  const experiencesTxt =
    experiences
      .map(
        (e: any) =>
          `- ${e.titre} chez ${e.entreprise} : ${e.contexte} [outils: ${(e.outilsUtilises || []).join(", ")}]`
      )
      .join("\n") || "Aucune";

  const formationsTxt =
    formations.map((f: any) => `- ${f.diplome} — ${f.etablissement}`).join("\n") || "Aucune";

  const projetsTxt =
    projets
      .map((p: any) => `- ${p.titre} : ${p.contexte} [outils: ${(p.outils || []).join(", ")}]`)
      .join("\n") || "Aucun";

  return `
Formations:
${formationsTxt}

Expériences:
${experiencesTxt}

Projets:
${projetsTxt}

Compétences (outils/techniques):
${competencesTxt}

Connaissances académiques (matières théoriques):
${connaissancesTxt}
`.trim();
}

export const matcherOffre = onCall({ secrets: [anthropicApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const offreTexteBrut = (request.data?.offreTexteBrut || "").toString().trim();
  if (!offreTexteBrut) {
    throw new HttpsError("invalid-argument", "Le texte de l'offre est vide.");
  }

  const data = await chargerProfilComplet(uid);
  const profilTxt = formaterProfilPourPrompt(data);

  const client = new Anthropic({ apiKey: anthropicApiKey.value() });

  const response = await client.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 1024,
    tools: [
      {
        name: "renvoyer_matching",
        description:
          "Renvoie le résultat structuré de l'analyse de correspondance entre le profil et l'offre, forces ET faiblesses.",
        input_schema: {
          type: "object",
          properties: {
            poste: {
              type: "string",
              description: "Intitulé du poste tel qu'indiqué dans l'offre, court",
            },
            entreprise: {
              type: "string",
              description: "Nom de l'entreprise qui recrute, tel qu'indiqué dans l'offre. Si introuvable, renvoyer une chaîne vide.",
            },
            domainePoste: {
              type: "string",
              description: "Type de poste détecté, court, ex: 'Bureau d'études · mécanique'",
            },
            scoreMatching: {
              type: "integer",
              description: "Score de correspondance entre 0 et 100",
            },
            competencesMatchees: {
              type: "array",
              items: { type: "string" },
              description: "Noms exacts des compétences du profil qui correspondent à l'offre (max 5)",
            },
            competencesManquantes: {
              type: "array",
              items: { type: "string" },
              description:
                "Compétences, outils ou exigences EXPLICITEMENT mentionnés dans le texte de l'offre, que le profil ne possède PAS (absents de sa liste de compétences, connaissances académiques ou expériences). Reste court et factuel (max 5), base-toi uniquement sur ce que l'offre demande littéralement, n'invente rien. Si tout ce que demande l'offre est couvert par le profil, renvoyer un tableau vide.",
            },
            raisonsMatching: {
              type: "array",
              items: { type: "string" },
              description:
                "2 à 3 phrases courtes justifiant le score, en français, chacune citant un élément précis du profil",
            },
          },
          required: [
            "poste",
            "entreprise",
            "domainePoste",
            "scoreMatching",
            "competencesMatchees",
            "competencesManquantes",
            "raisonsMatching",
          ],
        },
      },
    ],
    tool_choice: { type: "tool", name: "renvoyer_matching" },
    messages: [
      {
        role: "user",
        content: `Tu es un assistant qui évalue la correspondance entre le profil d'un étudiant ingénieur et une offre d'alternance/stage.

Profil du candidat:
${profilTxt}

Offre visée:
${offreTexteBrut}

Analyse la correspondance dans les deux sens : ce que le profil possède et qui correspond à l'offre (forces), ET ce que l'offre demande explicitement que le profil ne possède pas (faiblesses/manques). Appelle l'outil renvoyer_matching avec ton évaluation. Sois précis et concret, cite des éléments réels du profil et du texte de l'offre.`,
      },
    ],
  });

  const toolUse = response.content.find((b) => b.type === "tool_use");
  if (!toolUse || toolUse.type !== "tool_use") {
    throw new HttpsError("internal", "Réponse inattendue du modèle.");
  }

  return toolUse.input as MatchingResult;
});

export const genererCandidature = onCall({ secrets: [anthropicApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const offreTexteBrut = (request.data?.offreTexteBrut || "").toString().trim();
  const entreprise = (request.data?.entreprise || "").toString().trim();
  const poste = (request.data?.poste || "").toString().trim();
  const matching = request.data?.matching as MatchingResult | undefined;

  if (!offreTexteBrut || !matching) {
    throw new HttpsError("invalid-argument", "Données manquantes pour la génération.");
  }

  const data = await chargerProfilComplet(uid);
  const profilTxt = formaterProfilPourPrompt(data);
  const nomComplet = `${data.profil.prenom || ""} ${data.profil.nom || ""}`.trim();

  const competencesDisponibles = (data.profil.competences || []).map((c: any) => c.nom);
  const connaissancesDisponibles = (data.profil.connaissancesAcademiques || []).map((c: any) => c.nom);

  const client = new Anthropic({ apiKey: anthropicApiKey.value() });

  const response = await client.messages.create({
    model: "claude-sonnet-5",
    max_tokens: 2048,
    tools: [
      {
        name: "renvoyer_generation",
        description: "Renvoie le contenu généré et la sélection d'éléments à mettre en avant pour le CV et la lettre de motivation.",
        input_schema: {
          type: "object",
          properties: {
            profilResume: {
              type: "string",
              description:
                "Résumé de profil pour le CV, 2-3 phrases, adapté à l'offre, en français, ton professionnel et sobre",
            },
            experiencesTexte: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  titre: { type: "string" },
                  entreprise: {
                    type: "string",
                    description: "Nom de l'entreprise si c'est une expérience professionnelle. Laisser vide si c'est un projet académique/personnel.",
                  },
                  description: {
                    type: "string",
                    description:
                      "1-2 phrases reformulées pour mettre en avant la pertinence par rapport à l'offre",
                  },
                },
                required: ["titre", "entreprise", "description"],
              },
              description:
                "Les 3 à 4 expériences ET projets les plus pertinents (piochés dans les deux listes fournies), reformulés, dans l'ordre de pertinence pour cette offre précise",
            },
            competencesAMettreEnAvant: {
              type: "array",
              items: { type: "string" },
              description:
                `Sous-ensemble ORDONNÉ (le plus pertinent en premier) des noms EXACTS de compétences à afficher sur le CV pour cette offre précise, choisis strictement parmi cette liste réelle: [${competencesDisponibles.join(", ")}]. Exclus celles hors-sujet même si elles existent dans le profil (ex: des compétences dev web pour un poste mécanique). N'invente jamais un nom qui n'est pas dans la liste.`,
            },
            connaissancesAMettreEnAvant: {
              type: "array",
              items: { type: "string" },
              description:
                `Sous-ensemble ORDONNÉ (le plus pertinent en premier) des noms EXACTS de connaissances académiques à afficher pour cette offre précise, choisis strictement parmi cette liste réelle: [${connaissancesDisponibles.join(", ")}]. N'invente jamais un nom qui n'est pas dans la liste.`,
            },
            lettreMotivation: {
              type: "string",
              description:
                "Lettre de motivation complète en français, 150-250 mots, sans formule générique creuse, qui cite des éléments concrets du profil et de l'offre",
            },
          },
          required: [
            "profilResume",
            "experiencesTexte",
            "competencesAMettreEnAvant",
            "connaissancesAMettreEnAvant",
            "lettreMotivation",
          ],
        },
      },
    ],
    tool_choice: { type: "tool", name: "renvoyer_generation" },
    messages: [
      {
        role: "user",
        content: `Tu prépares un CV et une lettre de motivation optimisés pour ${nomComplet}, étudiant ingénieur, qui postule pour: ${poste} chez ${entreprise}.

Profil complet du candidat (toutes les données réelles disponibles):
${profilTxt}

Offre visée:
${offreTexteBrut}

Éléments de correspondance déjà identifiés:
- Domaine: ${matching.domainePoste}
- Compétences pertinentes détectées: ${matching.competencesMatchees.join(", ")}
- Raisons: ${matching.raisonsMatching.join(" / ")}

Ton rôle n'est PAS d'inventer de nouvelles informations — le candidat a déjà toutes ses données réelles ci-dessus. Ton rôle est de choisir et d'agencer intelligemment ce qui compte pour CETTE offre précise, et d'écarter ce qui n'apporte rien, même si ça existe dans le profil. Un CV optimisé pour cette offre ne doit jamais ressembler à un CV générique qui liste tout sans discernement.

Rédige un contenu précis, sans formules génériques d'IA, qui donne l'impression d'avoir été écrit par le candidat lui-même. Appelle l'outil renvoyer_generation.`,
      },
    ],
  });

  const toolUse = response.content.find((b) => b.type === "tool_use");
  if (!toolUse || toolUse.type !== "tool_use") {
    throw new HttpsError("internal", "Réponse inattendue du modèle.");
  }

  return toolUse.input as GenerationResult;
});
