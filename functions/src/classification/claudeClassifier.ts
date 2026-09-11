import Anthropic from '@anthropic-ai/sdk';
import { zodOutputFormat } from '@anthropic-ai/sdk/helpers/zod';
import { z } from 'zod/v4';

import { ClassificationResult, RawFeedItem } from '../types';

const ClassificationSchema = z.object({
  angleThematique: z.enum([
    'investissement',
    'exportations',
    'monnaie_aes',
    'finances_publiques',
    'secteur_prive',
    'hors_sujet',
  ]),
  resume: z.string().nullable(),
  fiabilite: z.enum(['haute', 'moyenne', 'faible']),
  langueOriginale: z.enum(['fr', 'en']),
});

const SYSTEM_PROMPT = `Tu classes des articles de presse économique concernant le Burkina Faso,
l'UEMOA/AES et l'actualité économique internationale pertinente, pour un économiste basé à
Ouagadougou. Pour chaque article, détermine :
1. L'angle thématique le plus pertinent parmi exactement ces 6 valeurs :
   - "investissement" (IDE, forums d'investissement, PPP, annonces de projets, financements de bailleurs)
   - "exportations" (filières d'export, balance commerciale, corridors logistiques, douanes)
   - "monnaie_aes" (BCEAO, UEMOA, monnaie AES, Banque de la Confédération AES, sortie CEDEAO)
   - "finances_publiques" (budget, loi de finances, dette souveraine, FMI/Banque mondiale, notation)
   - "secteur_prive" (CCI-BF, COGEF, PME, fiscalité des entreprises, climat des affaires)
   - "hors_sujet" (si l'article ne correspond à aucun des 5 angles ci-dessus)
2. Un résumé de 2 à 3 phrases en français, basé UNIQUEMENT sur le titre et l'extrait fournis
   (ne jamais inventer de détails absents du texte fourni). Si l'article est marqué comme
   payant, renvoie null pour le résumé.
3. Une fiabilité/importance parmi "haute", "moyenne", "faible", selon la pertinence pour un
   décideur économique burkinabè.
4. La langue originale de l'article ("fr" ou "en").`;

let client: Anthropic | null = null;

function getClient(): Anthropic {
  if (!client) {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      throw new Error('ANTHROPIC_API_KEY manquant — configurez le secret via `firebase functions:secrets:set`.');
    }
    client = new Anthropic({ apiKey });
  }
  return client;
}

export async function classifyArticle(item: RawFeedItem): Promise<ClassificationResult> {
  const userPrompt = `Titre : ${item.titre}
Source : ${item.sourceNom}
Article payant (résumé interdit si vrai) : ${item.accesPayant}
Extrait disponible : ${item.contenuBrut}`;

  const response = await getClient().messages.parse({
    model: 'claude-opus-5',
    max_tokens: 500,
    output_config: { effort: 'low', format: zodOutputFormat(ClassificationSchema) },
    system: SYSTEM_PROMPT,
    messages: [{ role: 'user', content: userPrompt }],
  });

  const parsed = response.parsed_output;
  if (!parsed) {
    throw new Error('Claude n\'a pas renvoyé de sortie structurée exploitable pour cet article.');
  }

  return {
    angleThematique: parsed.angleThematique,
    resume: item.accesPayant ? null : parsed.resume,
    fiabilite: parsed.fiabilite,
    langueOriginale: parsed.langueOriginale,
  };
}
