import { readFile, writeFile } from 'node:fs/promises';
import { basename } from 'node:path';

const [sourcePath, targetPath] = process.argv.slice(2);

if (!sourcePath || !targetPath) {
  throw new Error(
    'Usage: node tool/generate_perfume_catalog_migration.mjs <source.csv> <migration.sql>',
  );
}

const expectedHeaders = [
  'Perfume Name',
  'Producer (Brand)',
  'Top Notes - EN',
  'Middle Notes - EN',
  'Base Notes - EN',
  'Accords Names (List)',
  'Accords Percentage (List)',
  'The Note (EN)',
  'Top Notes - AR',
  'Middle Notes - AR',
  'Base Notes - AR',
  'Accords AR (List)',
  'The Note - AR',
];

function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;

  for (let index = 0; index < text.length; index += 1) {
    const character = text[index];

    if (quoted) {
      if (character === '"' && text[index + 1] === '"') {
        field += '"';
        index += 1;
      } else if (character === '"') {
        quoted = false;
      } else {
        field += character;
      }
      continue;
    }

    if (character === '"') {
      quoted = true;
    } else if (character === ',') {
      row.push(field);
      field = '';
    } else if (character === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else if (character !== '\r') {
      field += character;
    }
  }

  if (quoted) throw new Error('The CSV contains an unterminated quoted field.');
  if (field.length > 0 || row.length > 0) {
    row.push(field);
    rows.push(row);
  }

  if (rows.length > 0 && rows[0].length > 0) {
    rows[0][0] = rows[0][0].replace(/^\uFEFF/, '');
  }
  return rows;
}

function splitTerms(value) {
  return value
    .split(/[,،]/)
    .map((term) => term.trim())
    .filter(Boolean);
}

function uniqueTerms(terms) {
  const seen = new Set();
  return terms.filter((term) => {
    const key = term.toLocaleLowerCase();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function inferGender(description, perfumeName) {
  const normalized = description.toLocaleLowerCase();
  if (
    normalized.includes('for women and men') ||
    normalized.includes('for men and women') ||
    normalized.includes('unisex')
  ) {
    return 0;
  }
  if (normalized.includes('for women')) return 2;
  if (normalized.includes('for men')) return 1;

  // The source description omits a gender phrase for this fragrance.
  if (perfumeName === 'Yum Boujee Marshmallow') return 2;
  throw new Error(`Could not infer gender for "${perfumeName}".`);
}

function arabicName(record) {
  if (record['Perfume Name'] === 'BMW M 2025') {
    return 'بي إم دبليو إم 2025';
  }

  const name = record['The Note - AR'].split(' من ')[0].trim();
  if (record['Perfume Name'] === 'Dior Homme Intense') {
    return name.replace(/\s+2011$/, '');
  }
  return name;
}

const csvText = await readFile(sourcePath, 'utf8');
const rows = parseCsv(csvText);
const headers = rows.shift();

if (JSON.stringify(headers) !== JSON.stringify(expectedHeaders)) {
  throw new Error(
    `Unexpected CSV headers.\nExpected: ${expectedHeaders.join(' | ')}\nReceived: ${headers.join(' | ')}`,
  );
}

const records = rows
  .filter((row) => row.some((value) => value.trim().length > 0))
  .map((row, rowIndex) => {
    if (row.length !== expectedHeaders.length) {
      throw new Error(
        `CSV row ${rowIndex + 2} has ${row.length} columns; expected ${expectedHeaders.length}.`,
      );
    }
    return Object.fromEntries(
      expectedHeaders.map((header, columnIndex) => [
        header,
        row[columnIndex].trim(),
      ]),
    );
  });

if (records.length !== 32) {
  throw new Error(`Expected 32 perfume rows; received ${records.length}.`);
}

for (const [index, record] of records.entries()) {
  for (const header of expectedHeaders) {
    if (!record[header]) {
      throw new Error(`CSV row ${index + 2} has an empty "${header}" field.`);
    }
  }
}

const normalizedNames = records.map((record) =>
  record['Perfume Name'].toLocaleLowerCase(),
);
if (new Set(normalizedNames).size !== normalizedNames.length) {
  throw new Error('The CSV contains duplicate perfume names.');
}

const catalog = records.map((record) => {
  const perfumeName = record['Perfume Name'];
  return {
    match_name_en:
      perfumeName === 'Khamra Qahwa' ? 'Khamrah Qahwa' : perfumeName,
    item_name_en: perfumeName,
    item_name_ar: arabicName(record),
    brand_name: record['Producer (Brand)'],
    description_en: record['The Note (EN)'],
    description_ar: record['The Note - AR'],
    gender: inferGender(record['The Note (EN)'], perfumeName),
    notes_en: uniqueTerms([
      ...splitTerms(record['Top Notes - EN']),
      ...splitTerms(record['Middle Notes - EN']),
      ...splitTerms(record['Base Notes - EN']),
    ]),
    notes_ar: uniqueTerms([
      ...splitTerms(record['Top Notes - AR']),
      ...splitTerms(record['Middle Notes - AR']),
      ...splitTerms(record['Base Notes - AR']),
    ]),
    accords_en: uniqueTerms(splitTerms(record['Accords Names (List)'])),
    accords_ar: uniqueTerms(splitTerms(record['Accords AR (List)'])),
  };
});

const payload = JSON.stringify(catalog);
const dollarQuote = '$perfume_catalog$';
if (payload.includes(dollarQuote)) {
  throw new Error(`Generated JSON unexpectedly contains ${dollarQuote}.`);
}

const sql = `-- Generated from ${basename(sourcePath)}.
-- Re-run tool/generate_perfume_catalog_migration.mjs to regenerate this file.

create temporary table perfume_import (
  match_name_en text not null,
  item_name_en text not null,
  item_name_ar text not null,
  brand_name text not null,
  description_en text not null,
  description_ar text not null,
  gender integer not null,
  notes_en text[] not null,
  notes_ar text[] not null,
  accords_en text[] not null,
  accords_ar text[] not null
);

insert into perfume_import (
  match_name_en,
  item_name_en,
  item_name_ar,
  brand_name,
  description_en,
  description_ar,
  gender,
  notes_en,
  notes_ar,
  accords_en,
  accords_ar
)
select
  source.match_name_en,
  source.item_name_en,
  source.item_name_ar,
  source.brand_name,
  source.description_en,
  source.description_ar,
  source.gender,
  array(select jsonb_array_elements_text(source.notes_en)),
  array(select jsonb_array_elements_text(source.notes_ar)),
  array(select jsonb_array_elements_text(source.accords_en)),
  array(select jsonb_array_elements_text(source.accords_ar))
from jsonb_to_recordset(${dollarQuote}${payload}${dollarQuote}::jsonb) as source (
  match_name_en text,
  item_name_en text,
  item_name_ar text,
  brand_name text,
  description_en text,
  description_ar text,
  gender integer,
  notes_en jsonb,
  notes_ar jsonb,
  accords_en jsonb,
  accords_ar jsonb
);

update public.items as item
set
  "categoryID" = 1,
  "subCategoryID" = null,
  gender = source.gender,
  "itemName" = source.item_name_ar,
  "itemNameEN" = source.item_name_en,
  "brandName" = source.brand_name,
  "itemDescription" = source.description_ar,
  "itemDescriptionEN" = source.description_en,
  notes = source.notes_ar,
  "notesEN" = source.notes_en,
  accords = source.accords_ar,
  "accordsEN" = source.accords_en
from perfume_import as source
where lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en));

with missing_items as (
  select
    source.*,
    row_number() over (order by source.item_name_en) as row_number
  from perfume_import as source
  where not exists (
    select 1
    from public.items as item
    where lower(trim(item."itemNameEN")) = lower(trim(source.item_name_en))
  )
),
next_item_id as (
  select coalesce(max(id), 0)::bigint as maximum_id
  from public.items
)
insert into public.items (
  id,
  "categoryID",
  "subCategoryID",
  gender,
  "itemName",
  "itemNameEN",
  "brandName",
  "itemDescription",
  "itemDescriptionEN",
  notes,
  "notesEN",
  accords,
  "accordsEN",
  "isFeatured"
)
select
  next_item_id.maximum_id + missing_items.row_number,
  1,
  null,
  missing_items.gender,
  missing_items.item_name_ar,
  missing_items.item_name_en,
  missing_items.brand_name,
  missing_items.description_ar,
  missing_items.description_en,
  missing_items.notes_ar,
  missing_items.notes_en,
  missing_items.accords_ar,
  missing_items.accords_en,
  false
from missing_items
cross join next_item_id;

update public.item_properties as property
set
  price = case property.size
    when 10 then 80
    when 30 then 200
    when 50 then 450
    when 100 then 800
  end,
  "inStock" = true,
  "isDefault" = property.size = 10,
  "PropertyDescription" =
    source.item_name_ar || ' - ' || property.size || ' مل',
  "propertyDescriptionEN" =
    source.item_name_en || ' - ' || property.size || ' ml'
from public.items as item
join perfume_import as source
  on lower(trim(item."itemNameEN")) = lower(trim(source.item_name_en))
where property."itemID" = item.id
  and property.size in (10, 30, 50, 100);

with desired_properties (size, price) as (
  values
    (10, 80::double precision),
    (30, 200::double precision),
    (50, 450::double precision),
    (100, 800::double precision)
),
missing_properties as (
  select
    item.id as item_id,
    source.item_name_ar,
    source.item_name_en,
    desired.size,
    desired.price,
    row_number() over (order by item.id, desired.size) as row_number
  from public.items as item
  join perfume_import as source
    on lower(trim(item."itemNameEN")) = lower(trim(source.item_name_en))
  cross join desired_properties as desired
  where not exists (
    select 1
    from public.item_properties as property
    where property."itemID" = item.id
      and property.size = desired.size
  )
),
next_property_id as (
  select coalesce(max(id), 0)::bigint as maximum_id
  from public.item_properties
)
insert into public.item_properties (
  id,
  "itemID",
  size,
  image,
  price,
  "inStock",
  "PropertyDescription",
  "isDefault",
  "propertyDescriptionEN"
)
select
  next_property_id.maximum_id + missing_properties.row_number,
  missing_properties.item_id,
  missing_properties.size,
  '',
  missing_properties.price,
  true,
  missing_properties.item_name_ar || ' - ' || missing_properties.size || ' مل',
  missing_properties.size = 10,
  missing_properties.item_name_en || ' - ' || missing_properties.size || ' ml'
from missing_properties
cross join next_property_id;

do $verification$
begin
  if (
    select count(*)
    from public.items as item
    join perfume_import as source
      on lower(trim(item."itemNameEN")) = lower(trim(source.item_name_en))
  ) <> 32 then
    raise exception 'Perfume import did not produce exactly 32 matching items.';
  end if;

  if exists (
    select 1
    from public.items as item
    join perfume_import as source
      on lower(trim(item."itemNameEN")) = lower(trim(source.item_name_en))
    cross join (values (10), (30), (50), (100)) as desired(size)
    where not exists (
      select 1
      from public.item_properties as property
      where property."itemID" = item.id
        and property.size = desired.size
        and property.price = case desired.size
          when 10 then 80
          when 30 then 200
          when 50 then 450
          when 100 then 800
        end
    )
  ) then
    raise exception 'One or more perfume sizes or prices failed validation.';
  end if;
end
$verification$;

drop table perfume_import;
`;

await writeFile(targetPath, sql, 'utf8');
console.log(`Generated ${targetPath} with ${catalog.length} perfumes.`);
