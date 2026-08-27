const replacements = new Map<string, string>([
  ['agarwood', 'oud'],
  ['agar wood', 'oud'],
  ['agarwood oud', 'oud'],
  ['woodsy notes', 'woody'],
  ['woody notes', 'woody'],
  ['wood notes', 'woody'],
  ['virginia cedar', 'cedar'],
  ['virginian cedar', 'cedar'],
  ['atlas cedar', 'cedar'],
  ['calabrian bergamot', 'bergamot'],
  ['calabrian bergamote', 'bergamot'],
  ['sicilian lemon', 'lemon'],
  ['sicilian orange', 'orange'],
  ['mandarin orange', 'mandarin'],
  ['madagascar vanilla', 'vanilla'],
  ['bourbon vanilla', 'vanilla'],
  ['white musk', 'musk'],
  ['black musk', 'musk'],
  ['pink berries', 'pink pepper'],
  ['guatemalan cardamom', 'cardamom'],
  ['ceylon cinnamon', 'cinnamon'],
  ['haitian vetiver', 'vetiver'],
  ['tunisian neroli', 'neroli'],
  ['moroccan jasmine', 'jasmine'],
  ['ambergris', 'amber'],
  ['amberwood', 'amber'],
  ['fresh spicy', 'fresh spicy'],
  ['warm spicy', 'warm spicy'],
]);

export function normalizeTerm(value: string): string {
  const normalized = value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[\u064B-\u065F\u0670\u06D6-\u06ED]/g, '')
    .replace(/ـ/g, '')
    .replace(/[أإآ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .toLowerCase()
    .replace(/\([^)]*\)/g, ' ')
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim()
    .replace(/\s+/g, ' ');

  return replacements.get(normalized) ?? normalized;
}

export function normalizedUnique(values: string[]): string[] {
  return [...new Set(values.map(normalizeTerm).filter(Boolean))];
}

export function normalizedName(name: string, brand = ''): string {
  return normalizeTerm(`${brand} ${name}`);
}
