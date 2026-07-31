require 'csv'
require 'json'
require 'pathname'

source_path, target_path = ARGV

unless source_path && target_path
  abort(
    'Usage: ruby tool/generate_perfume_metadata_migration.rb ' \
    '<source.csv> <migration.sql>',
  )
end

expected_headers = [
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
].freeze

def split_terms(value)
  value.to_s
       .split(/[,،]/)
       .map(&:strip)
       .reject(&:empty?)
end

def parse_percentages(value, perfume_name)
  value.to_s.split(',').map do |percentage|
    parsed = Integer(percentage.strip.delete_suffix('%'), exception: false)
    unless parsed&.between?(0, 100)
      raise "Invalid accord percentage for #{perfume_name}: #{percentage}"
    end
    parsed
  end
end

rows = CSV.read(source_path, headers: true, encoding: 'bom|utf-8')
unless rows.headers == expected_headers
  abort(
    "Unexpected CSV headers.\n" \
    "Expected: #{expected_headers.join(' | ')}\n" \
    "Received: #{rows.headers.join(' | ')}",
  )
end

records = rows.map.with_index(2) do |row, line_number|
  missing_headers = expected_headers.select { |header| row[header].to_s.strip.empty? }
  unless missing_headers.empty?
    raise "CSV row #{line_number} has empty fields: #{missing_headers.join(', ')}"
  end

  perfume_name = row['Perfume Name'].strip
  accords_en = split_terms(row['Accords Names (List)'])
  accords_ar = split_terms(row['Accords AR (List)'])
  accord_percentages = parse_percentages(
    row['Accords Percentage (List)'],
    perfume_name,
  )

  unless accords_en.length == accords_ar.length &&
         accords_en.length == accord_percentages.length
    raise(
      "Accord list mismatch for #{perfume_name}: " \
      "EN=#{accords_en.length}, AR=#{accords_ar.length}, " \
      "percentages=#{accord_percentages.length}",
    )
  end

  {
    match_name_en: perfume_name == 'Yum Boujee Marshmallow' ?
      'Kayali Marshmallow' : perfume_name,
    top_notes_en: split_terms(row['Top Notes - EN']),
    top_notes_ar: split_terms(row['Top Notes - AR']),
    middle_notes_en: split_terms(row['Middle Notes - EN']),
    middle_notes_ar: split_terms(row['Middle Notes - AR']),
    base_notes_en: split_terms(row['Base Notes - EN']),
    base_notes_ar: split_terms(row['Base Notes - AR']),
    accords_en: accords_en,
    accords_ar: accords_ar,
    accord_percentages: accord_percentages,
  }
end

unless records.length == 32
  abort("Expected 32 perfume rows; received #{records.length}.")
end

normalized_names = records.map { |record| record[:match_name_en].downcase }
unless normalized_names.uniq.length == normalized_names.length
  abort('The generated item match names are not unique.')
end

payload = JSON.generate(records)
dollar_quote = '$perfume_metadata$'
if payload.include?(dollar_quote)
  abort("Generated JSON unexpectedly contains #{dollar_quote}.")
end

sql = <<~SQL
  -- Generated from #{Pathname(source_path).basename}.
  -- Re-run tool/generate_perfume_metadata_migration.rb to regenerate this file.

  alter table public.items
    add column "topNotes" text[] not null default '{}'::text[],
    add column "topNotesEN" text[] not null default '{}'::text[],
    add column "middleNotes" text[] not null default '{}'::text[],
    add column "middleNotesEN" text[] not null default '{}'::text[],
    add column "baseNotes" text[] not null default '{}'::text[],
    add column "baseNotesEN" text[] not null default '{}'::text[],
    add column "accordPercentages" smallint[] not null default '{}'::smallint[];

  comment on column public.items."topNotes" is
    'Ordered Arabic top-note names.';
  comment on column public.items."topNotesEN" is
    'Ordered English top-note names.';
  comment on column public.items."middleNotes" is
    'Ordered Arabic middle-note names.';
  comment on column public.items."middleNotesEN" is
    'Ordered English middle-note names.';
  comment on column public.items."baseNotes" is
    'Ordered Arabic base-note names.';
  comment on column public.items."baseNotesEN" is
    'Ordered English base-note names.';
  comment on column public.items."accordPercentages" is
    'Accord intensity percentages aligned by position with accords and accordsEN.';

  create temporary table perfume_metadata_import (
    match_name_en text primary key,
    top_notes_en text[] not null,
    top_notes_ar text[] not null,
    middle_notes_en text[] not null,
    middle_notes_ar text[] not null,
    base_notes_en text[] not null,
    base_notes_ar text[] not null,
    accords_en text[] not null,
    accords_ar text[] not null,
    accord_percentages smallint[] not null
  ) on commit drop;

  insert into perfume_metadata_import (
    match_name_en,
    top_notes_en,
    top_notes_ar,
    middle_notes_en,
    middle_notes_ar,
    base_notes_en,
    base_notes_ar,
    accords_en,
    accords_ar,
    accord_percentages
  )
  select
    source.match_name_en,
    array(select jsonb_array_elements_text(source.top_notes_en)),
    array(select jsonb_array_elements_text(source.top_notes_ar)),
    array(select jsonb_array_elements_text(source.middle_notes_en)),
    array(select jsonb_array_elements_text(source.middle_notes_ar)),
    array(select jsonb_array_elements_text(source.base_notes_en)),
    array(select jsonb_array_elements_text(source.base_notes_ar)),
    array(select jsonb_array_elements_text(source.accords_en)),
    array(select jsonb_array_elements_text(source.accords_ar)),
    array(
      select jsonb_array_elements_text(source.accord_percentages)::smallint
    )
  from jsonb_to_recordset(
    #{dollar_quote}#{payload}#{dollar_quote}::jsonb
  ) as source (
    match_name_en text,
    top_notes_en jsonb,
    top_notes_ar jsonb,
    middle_notes_en jsonb,
    middle_notes_ar jsonb,
    base_notes_en jsonb,
    base_notes_ar jsonb,
    accords_en jsonb,
    accords_ar jsonb,
    accord_percentages jsonb
  );

  do $verification$
  begin
    if exists (
      select 1
      from perfume_metadata_import as source
      left join public.items as item
        on lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en))
      group by source.match_name_en
      having count(item.id) <> 1
    ) then
      raise exception
        'Every CSV perfume must match exactly one existing item.';
    end if;
  end
  $verification$;

  update public.items as item
  set
    "topNotes" = source.top_notes_ar,
    "topNotesEN" = source.top_notes_en,
    "middleNotes" = source.middle_notes_ar,
    "middleNotesEN" = source.middle_notes_en,
    "baseNotes" = source.base_notes_ar,
    "baseNotesEN" = source.base_notes_en,
    notes = source.top_notes_ar ||
      source.middle_notes_ar ||
      source.base_notes_ar,
    "notesEN" = source.top_notes_en ||
      source.middle_notes_en ||
      source.base_notes_en,
    accords = source.accords_ar,
    "accordsEN" = source.accords_en,
    "accordPercentages" = source.accord_percentages
  from perfume_metadata_import as source
  where lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en));

  alter table public.items
    add constraint items_accord_percentages_range
      check (
        0 <= all ("accordPercentages")
        and 100 >= all ("accordPercentages")
      ),
    add constraint items_accord_metadata_lengths
      check (
        cardinality(accords) = cardinality("accordsEN")
        and cardinality(accords) = cardinality("accordPercentages")
      );

  do $verification$
  begin
    if (
      select count(*)
      from public.items as item
      join perfume_metadata_import as source
        on lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en))
      where
        item."topNotes" = source.top_notes_ar
        and item."topNotesEN" = source.top_notes_en
        and item."middleNotes" = source.middle_notes_ar
        and item."middleNotesEN" = source.middle_notes_en
        and item."baseNotes" = source.base_notes_ar
        and item."baseNotesEN" = source.base_notes_en
        and item.accords = source.accords_ar
        and item."accordsEN" = source.accords_en
        and item."accordPercentages" = source.accord_percentages
    ) <> 32 then
      raise exception 'Perfume metadata backfill failed verification.';
    end if;
  end
  $verification$;
SQL

File.write(target_path, sql, mode: 'w', encoding: 'utf-8')
puts "Generated #{target_path} with #{records.length} perfumes."
