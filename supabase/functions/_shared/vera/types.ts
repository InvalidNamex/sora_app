export type VeraLanguage = 'ar' | 'en';

export interface PerfumeProfile {
  name: string;
  brand: string;
  concentration?: string;
  topNotes: string[];
  middleNotes: string[];
  baseNotes: string[];
  accords: string[];
  accordPercentages: number[];
  source?: string;
  sourceUrl?: string;
  sourceConfidence?: number;
  fetchedAt?: string;
}

export interface CatalogProperty {
  id: number;
  itemId: number;
  sizeMl: number;
  image: string;
  price: number;
  discountPercentage?: number;
  inStock: boolean;
  isDefault: boolean;
  descriptionAr: string;
  descriptionEn: string;
}

export interface CatalogPerfume extends PerfumeProfile {
  id: number;
  nameAr: string;
  nameEn: string;
  accordsAr: string[];
  topNotesAr: string[];
  middleNotesAr: string[];
  baseNotesAr: string[];
  properties: CatalogProperty[];
}

export type VeraMatchBand =
  | 'very_close'
  | 'similar'
  | 'shared_character'
  | 'different_direction';

export interface VeraRecommendation {
  itemId: number;
  nameAr: string;
  nameEn: string;
  brand: string;
  score: number;
  band: VeraMatchBand;
  sharedAccordsAr: string[];
  sharedAccordsEn: string[];
  sharedNotesAr: string[];
  sharedNotesEn: string[];
  inStock: boolean;
  property: CatalogProperty | null;
}

export interface VeraIntent {
  intent:
    | 'find_similar'
    | 'compare_catalog'
    | 'refine_preferences'
    | 'perfume_question'
    | 'unsupported';
  response_language: VeraLanguage;
  perfume_name: string;
  brand: string;
  concentration: string;
  requested_notes: string[];
  requested_accords: string[];
  needs_clarification: boolean;
  clarification_question: string;
}
