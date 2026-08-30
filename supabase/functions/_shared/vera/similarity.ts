import { normalizeTerm, normalizedUnique } from './normalize.ts';
import type {
  CatalogPerfume,
  CatalogProperty,
  PerfumeProfile,
  VeraMatchBand,
  VeraRecommendation,
} from './types.ts';

interface ComponentScore {
  score: number;
  usable: boolean;
  shared: string[];
}

function setSimilarity(left: string[], right: string[]): ComponentScore {
  const a = normalizedUnique(left);
  const b = normalizedUnique(right);
  if (a.length === 0 || b.length === 0) {
    return { score: 0, usable: false, shared: [] };
  }

  const rightSet = new Set(b);
  const shared = a.filter((value) => rightSet.has(value));
  const union = new Set([...a, ...b]);
  return {
    score: union.size === 0 ? 0 : shared.length / union.size,
    usable: true,
    shared,
  };
}

function accordVector(profile: PerfumeProfile): Map<string, number> {
  const result = new Map<string, number>();
  profile.accords.forEach((accord, index) => {
    const name = normalizeTerm(accord);
    if (!name) return;
    const supplied = profile.accordPercentages[index];
    const inferred = Math.max(40, 100 - index * 10);
    const strength = Number.isFinite(supplied)
      ? Math.max(0, Math.min(100, supplied)) / 100
      : inferred / 100;
    result.set(name, Math.max(result.get(name) ?? 0, strength));
  });
  return result;
}

function accordSimilarity(
  left: PerfumeProfile,
  right: PerfumeProfile,
): ComponentScore {
  const a = accordVector(left);
  const b = accordVector(right);
  if (a.size === 0 || b.size === 0) {
    return { score: 0, usable: false, shared: [] };
  }

  const keys = new Set([...a.keys(), ...b.keys()]);
  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (const key of keys) {
    const av = a.get(key) ?? 0;
    const bv = b.get(key) ?? 0;
    dot += av * bv;
    normA += av * av;
    normB += bv * bv;
  }

  const denominator = Math.sqrt(normA) * Math.sqrt(normB);
  const shared = [...a.keys()].filter((key) => b.has(key));
  return {
    score: denominator === 0 ? 0 : dot / denominator,
    usable: true,
    shared,
  };
}

function bandFor(score: number): VeraMatchBand {
  if (score >= 85) return 'very_close';
  if (score >= 70) return 'similar';
  if (score >= 55) return 'shared_character';
  return 'different_direction';
}

function displayTerms(
  normalized: string[],
  en: string[],
  ar: string[],
): { en: string[]; ar: string[] } {
  const resultEn: string[] = [];
  const resultAr: string[] = [];
  for (const term of normalized) {
    const index = en.findIndex((value) => normalizeTerm(value) === term);
    if (index < 0) continue;
    resultEn.push(en[index]);
    resultAr.push(ar[index] || en[index]);
  }
  return { en: resultEn, ar: resultAr };
}

function primaryProperty(properties: CatalogProperty[]): CatalogProperty | null {
  if (properties.length === 0) return null;
  return [...properties].sort((a, b) => {
    if (a.inStock !== b.inStock) return a.inStock ? -1 : 1;
    if (a.inStock && b.inStock && (a.sizeMl === 50) !== (b.sizeMl === 50)) {
      return a.sizeMl === 50 ? -1 : 1;
    }
    if (a.isDefault !== b.isDefault) return a.isDefault ? -1 : 1;
    if (a.sizeMl !== b.sizeMl) return b.sizeMl - a.sizeMl;
    return a.id - b.id;
  })[0];
}

export function scorePerfume(
  source: PerfumeProfile,
  candidate: CatalogPerfume,
): VeraRecommendation {
  const accord = accordSimilarity(source, candidate);
  const top = setSimilarity(source.topNotes, candidate.topNotes);
  const middle = setSimilarity(source.middleNotes, candidate.middleNotes);
  const base = setSimilarity(source.baseNotes, candidate.baseNotes);
  const components = [
    { weight: 0.50, value: accord },
    { weight: 0.15, value: top },
    { weight: 0.15, value: middle },
    { weight: 0.20, value: base },
  ].filter((component) => component.value.usable);
  const usableWeight = components.reduce((sum, component) => sum + component.weight, 0);
  const raw = usableWeight === 0
    ? 0
    : components.reduce(
      (sum, component) => sum + component.value.score * component.weight,
      0,
    ) / usableWeight;
  const score = Math.round(Math.max(0, Math.min(1, raw)) * 100);

  const sharedAccords = displayTerms(
    accord.shared,
    candidate.accords,
    candidate.accordsAr,
  );
  const noteTerms = [...new Set([...top.shared, ...middle.shared, ...base.shared])];
  const candidateNotesEn = [
    ...candidate.topNotes,
    ...candidate.middleNotes,
    ...candidate.baseNotes,
  ];
  const candidateNotesAr = [
    ...candidate.topNotesAr,
    ...candidate.middleNotesAr,
    ...candidate.baseNotesAr,
  ];
  const sharedNotes = displayTerms(noteTerms, candidateNotesEn, candidateNotesAr);
  const property = primaryProperty(candidate.properties);

  return {
    itemId: candidate.id,
    nameAr: candidate.nameAr,
    nameEn: candidate.nameEn,
    brand: candidate.brand,
    score,
    band: bandFor(score),
    sharedAccordsAr: sharedAccords.ar.slice(0, 4),
    sharedAccordsEn: sharedAccords.en.slice(0, 4),
    sharedNotesAr: sharedNotes.ar.slice(0, 5),
    sharedNotesEn: sharedNotes.en.slice(0, 5),
    inStock: candidate.properties.some((value) => value.inStock),
    property,
  };
}

export function rankPerfumes(
  source: PerfumeProfile,
  catalog: CatalogPerfume[],
  limit = 5,
  excludeItemId?: number,
): VeraRecommendation[] {
  return catalog
    .filter((candidate) => candidate.id !== excludeItemId)
    .map((candidate) => scorePerfume(source, candidate))
    .sort((a, b) => b.score - a.score || Number(b.inStock) - Number(a.inStock))
    .slice(0, Math.max(1, Math.min(10, limit)));
}
