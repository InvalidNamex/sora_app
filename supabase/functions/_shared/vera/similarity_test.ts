import { assert, assertEquals } from 'jsr:@std/assert@1';
import { rankPerfumes, scorePerfume } from './similarity.ts';
import type { CatalogPerfume, PerfumeProfile } from './types.ts';

const source: PerfumeProfile = {
  name: 'Source',
  brand: 'Test',
  topNotes: ['Calabrian Bergamot', 'Pepper'],
  middleNotes: ['Lavender', 'Patchouli'],
  baseNotes: ['Cedar', 'Ambroxan'],
  accords: ['Fresh Spicy', 'Citrus', 'Woody'],
  accordPercentages: [100, 80, 60],
};

function candidate(overrides: Partial<CatalogPerfume> = {}): CatalogPerfume {
  return {
    id: 1,
    name: 'Candidate',
    nameAr: 'مرشح',
    nameEn: 'Candidate',
    brand: 'Test',
    topNotes: ['Bergamot', 'Pepper'],
    topNotesAr: ['برغموت', 'فلفل'],
    middleNotes: ['Lavender', 'Patchouli'],
    middleNotesAr: ['لافندر', 'باتشولي'],
    baseNotes: ['Cedar', 'Ambroxan'],
    baseNotesAr: ['أرز', 'أمبروكسان'],
    accords: ['Fresh Spicy', 'Citrus', 'Woody'],
    accordsAr: ['حار منعش', 'حمضي', 'خشبي'],
    accordPercentages: [100, 80, 60],
    properties: [],
    ...overrides,
  };
}

Deno.test('canonical note aliases produce an exact profile match', () => {
  assertEquals(scorePerfume(source, candidate()).score, 100);
});

Deno.test('an unrelated profile scores far below a matching profile', () => {
  const unrelated = candidate({
    id: 2,
    topNotes: ['Caramel'],
    middleNotes: ['Honey'],
    baseNotes: ['Vanilla'],
    accords: ['Sweet', 'Vanilla', 'Gourmand'],
    accordPercentages: [100, 90, 80],
  });
  const score = scorePerfume(source, unrelated).score;
  assert(score < 20);
});

Deno.test('ranking excludes the source item and respects the requested limit', () => {
  const ranked = rankPerfumes(
    source,
    [candidate({ id: 1 }), candidate({ id: 2 }), candidate({ id: 3 })],
    1,
    1,
  );
  assertEquals(ranked.length, 1);
  assertEquals(ranked[0].itemId, 2);
});

Deno.test('recommendations prefer an in-stock 50 ml property', () => {
  const result = scorePerfume(source, candidate({
    properties: [
      {
        id: 10,
        itemId: 1,
        sizeMl: 100,
        image: '',
        price: 800,
        inStock: true,
        isDefault: true,
        descriptionAr: '',
        descriptionEn: '',
      },
      {
        id: 11,
        itemId: 1,
        sizeMl: 50,
        image: '',
        price: 450,
        inStock: true,
        isDefault: false,
        descriptionAr: '',
        descriptionEn: '',
      },
    ],
  }));

  assertEquals(result.property?.sizeMl, 50);
});

Deno.test('recommendations use 50 ml as the default property even when out of stock', () => {
  const result = scorePerfume(source, candidate({
    properties: [
      {
        id: 10,
        itemId: 1,
        sizeMl: 100,
        image: '',
        price: 800,
        inStock: true,
        isDefault: false,
        descriptionAr: '',
        descriptionEn: '',
      },
      {
        id: 11,
        itemId: 1,
        sizeMl: 50,
        image: '',
        price: 450,
        inStock: false,
        isDefault: true,
        descriptionAr: '',
        descriptionEn: '',
      },
    ],
  }));

  assertEquals(result.property?.sizeMl, 50);
});
