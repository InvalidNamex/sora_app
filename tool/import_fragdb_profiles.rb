#!/usr/bin/env ruby
# frozen_string_literal: true

# Imports a licensed FragDB CSV bundle into perfume_reference_profiles.
# The public FragDB repository contains samples only; do not use this script
# with a full dataset unless Sora has obtained the appropriate commercial
# license.

require 'csv'
require 'json'
require 'net/http'
require 'optparse'
require 'uri'
require 'time'

options = {
  batch_size: 250,
  dry_run: false,
}

OptionParser.new do |parser|
  parser.banner = <<~USAGE
    Usage: ruby tool/import_fragdb_profiles.rb \
      --fragrances fragrances.csv --notes notes.csv --accords accords.csv
  USAGE
  parser.on('--fragrances PATH', 'FragDB fragrances.csv') { |value| options[:fragrances] = value }
  parser.on('--notes PATH', 'FragDB notes.csv') { |value| options[:notes] = value }
  parser.on('--accords PATH', 'FragDB accords.csv') { |value| options[:accords] = value }
  parser.on('--batch-size N', Integer, 'REST upsert batch size') { |value| options[:batch_size] = value }
  parser.on('--dry-run', 'Parse and validate without uploading') { options[:dry_run] = true }
end.parse!

required = %i[fragrances notes accords]
missing = required.reject { |key| options[key] && File.file?(options[key]) }
abort("Missing required CSV files: #{missing.join(', ')}") unless missing.empty?
abort('Batch size must be between 1 and 1000') unless (1..1000).cover?(options[:batch_size])

def load_lookup(path, name_column:, arabic_column:)
  CSV.foreach(
    path,
    headers: true,
    col_sep: '|',
    encoding: 'bom|utf-8',
    liberal_parsing: true,
  ).each_with_object({}) do |row, result|
    id = row['id']&.strip
    next if id.nil? || id.empty?

    result[id] = {
      en: row[name_column]&.strip.to_s,
      ar: row[arabic_column]&.strip.to_s,
    }
  end
end

notes = load_lookup(
  options[:notes],
  name_column: 'name',
  arabic_column: 'note_name_ar',
)
accords = load_lookup(
  options[:accords],
  name_column: 'name',
  arabic_column: 'name_ar',
)

def parse_accords(raw, lookup)
  values = raw.to_s.split(';').each_with_object([]) do |entry, result|
    id, percentage = entry.split(':', 2)
    metadata = lookup[id]
    next unless metadata && !metadata[:en].empty?

    result << {
      en: metadata[:en],
      ar: metadata[:ar],
      percentage: [[percentage.to_i, 0].max, 100].min,
    }
  end
  {
    en: values.map { |value| value[:en] },
    ar: values.map { |value| value[:ar] },
    percentages: values.map { |value| value[:percentage] },
  }
end

def parse_note_pyramid(raw, lookup)
  result = {
    'top' => { en: [], ar: [] },
    'middle' => { en: [], ar: [] },
    'base' => { en: [], ar: [] },
  }
  raw.to_s.scan(/(top|middle|base|notes)\(([^)]*)\)/).each do |level, content|
    target = level == 'notes' ? 'middle' : level
    content.split(';').each do |entry|
      note_id = entry.split(',', 2).first
      metadata = lookup[note_id]
      next unless metadata && !metadata[:en].empty?

      result[target][:en] << metadata[:en]
      result[target][:ar] << metadata[:ar]
    end
  end
  result
end

def upload_batch(rows)
  base_url = ENV.fetch('SUPABASE_URL')
  service_key = ENV.fetch('SUPABASE_SERVICE_ROLE_KEY')
  uri = URI.join(
    base_url.end_with?('/') ? base_url : "#{base_url}/",
    'rest/v1/perfume_reference_profiles?on_conflict=source,source_record_id',
  )
  request = Net::HTTP::Post.new(uri)
  request['apikey'] = service_key
  request['Authorization'] = "Bearer #{service_key}"
  request['Content-Type'] = 'application/json'
  request['Prefer'] = 'resolution=merge-duplicates,return=minimal'
  request.body = JSON.generate(rows)

  response = Net::HTTP.start(
    uri.host,
    uri.port,
    use_ssl: uri.scheme == 'https',
    open_timeout: 10,
    read_timeout: 60,
  ) { |http| http.request(request) }
  return if response.is_a?(Net::HTTPSuccess)

  abort("FragDB upload failed (#{response.code}): #{response.body.to_s.slice(0, 1000)}")
end

batch = []
parsed_count = 0
CSV.foreach(
  options[:fragrances],
  headers: true,
  col_sep: '|',
  encoding: 'bom|utf-8',
  liberal_parsing: true,
).each do |row|
  name = row['name']&.strip.to_s
  pid = row['pid']&.strip.to_s
  next if name.empty? || pid.empty?

  brand_name = row['brand'].to_s.split(';', 2).first.to_s.strip
  accord_profile = parse_accords(row['accords'], accords)
  pyramid = parse_note_pyramid(row['notes_pyramid'], notes)
  next if accord_profile[:en].empty? && pyramid.values.all? { |level| level[:en].empty? }

  year = row['year'].to_s.match?(/\A\d{4}\z/) ? row['year'].to_i : nil
  batch << {
    source: 'fragdb',
    source_record_id: pid,
    canonical_name: name,
    brand_name: brand_name,
    release_year: year,
    top_notes_en: pyramid['top'][:en],
    top_notes_ar: pyramid['top'][:ar],
    middle_notes_en: pyramid['middle'][:en],
    middle_notes_ar: pyramid['middle'][:ar],
    base_notes_en: pyramid['base'][:en],
    base_notes_ar: pyramid['base'][:ar],
    accords_en: accord_profile[:en],
    accords_ar: accord_profile[:ar],
    accord_percentages: accord_profile[:percentages],
    source_url: row['url']&.strip,
    source_evidence: [{ provider: 'FragDB', record_id: pid }],
    source_confidence: 0.95,
    fetched_at: Time.now.utc.iso8601,
    updated_at: Time.now.utc.iso8601,
  }
  parsed_count += 1

  next unless batch.length >= options[:batch_size]

  upload_batch(batch) unless options[:dry_run]
  warn("Processed #{parsed_count} profiles")
  batch.clear
end

upload_batch(batch) unless batch.empty? || options[:dry_run]
warn("Validated #{parsed_count} FragDB profiles#{' (dry run)' if options[:dry_run]}")
