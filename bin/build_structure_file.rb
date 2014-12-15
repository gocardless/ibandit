#!/usr/bin/env ruby

# Script for parsing the IBAN registry (IBAN_Registry.txt) and IBAN structures
# (IBANSTRUCTURE.xml) files from SWIFT.
#
require 'csv'
require 'yaml'
require 'sax-machine'

class Country
  include SAXMachine
  element 'iban_country_code', as: :country_code
  element 'bank_identifier_position', as: :bank_code_position
  element 'bank_identifier_length', as: :bank_code_length
  element 'branch_identifier_position', as: :branch_code_position
  element 'branch_identifier_length', as: :branch_code_length
  element 'account_number_position', as: :account_number_position
  element 'account_number_length', as: :account_number_length
  element 'iban_total_length', as: :total_length
  element 'iban_national_id_length', as: :iban_national_id_length
end

class Report
  include SAXMachine
  elements 'ibanstructure', as: :countries, class: Country
end

def get_iban_structures(iban_structures_file, iban_registry_file)
  bban_formats = iban_registry_file.each_with_object({}) do |line, hash|
    bban_structure = line['BBAN structure '].strip
    country_code = line['Country code as defined in ISO 3166'].strip
    hash[country_code] = convert_swift_convention(bban_structure)
  end

  report = Report.parse(iban_structures_file)
  report.countries.each_with_object({}) do |country, hash|
    hash[country.country_code] = {
      bank_code_position: country.bank_code_position.to_i,
      bank_code_length: country.bank_code_length.to_i,
      branch_code_position: country.branch_code_position.to_i,
      branch_code_length: country.branch_code_length.to_i,
      account_number_position: country.account_number_position.to_i,
      account_number_length: country.account_number_length.to_i,
      total_length: country.total_length.to_i,
      iban_national_id_length: country.iban_national_id_length.to_i,
      bban_format: bban_formats[country.country_code]
    }
  end
end

def convert_swift_convention(swift_string)
  swift_string.gsub(/(\d+)!([nac])/, '\2{\1}').
    gsub('n', '\d').
    gsub('a', '[A-Z]').
    gsub('c', '[A-Z0-9]')
end

def merge_structures(structures, additions)
  additions.each_pair do |key, value|
    structures[key].merge!(value) if structures.include?(key)
  end

  structures
end

# Only parse the files if this file is run as an executable (not required in,
# as it is in the specs)
if __FILE__ == $PROGRAM_NAME
  iban_registry_file = CSV.read(
    File.expand_path('../../data/IBAN_Registry.txt', __FILE__),
    col_sep: "\t",
    headers: true
  )

  iban_structures_file = File.read(
    File.expand_path('../../data/IBANSTRUCTURE.xml', __FILE__)
  )

  iban_structures = get_iban_structures(
    iban_structures_file,
    iban_registry_file
  )

  structure_additions = YAML.load_file(
    File.expand_path('../../data/structure_additions.yml', __FILE__)
  )

  complete_structures = merge_structures(iban_structures, structure_additions)
  output_file_path = File.expand_path(
    '../../lib/ibandit/structures.yml',
    __FILE__
  )

  File.open(output_file_path, 'w') do |f|
    f.write(complete_structures.to_yaml)
  end
end
