#!/usr/bin/env ruby
# frozen_string_literal: true

# Script for parsing the IBAN registry (IBAN_Registry.txt) and IBAN structures
# (IBANSTRUCTURE.xml) files from SWIFT.
require "csv"
require "yaml"
require "sax-machine"

class Country
  include SAXMachine
  element "iban_country_code", as: :country_code
  element "bank_identifier_position", as: :bank_code_position
  element "bank_identifier_length", as: :bank_code_length
  element "branch_identifier_position", as: :branch_code_position
  element "branch_identifier_length", as: :branch_code_length
  element "account_number_position", as: :account_number_position
  element "account_number_length", as: :account_number_length
  element "iban_total_length", as: :total_length
  element "iban_national_id_length", as: :national_id_length
end

class Report
  include SAXMachine
  elements "ibanstructure", as: :countries, class: Country
end

# rubocop:disable Metrics/AbcSize
def get_iban_structures(iban_structures_file, iban_registry_file)
  bban_formats = get_bban_formats(iban_registry_file)

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
      national_id_length: country.national_id_length.to_i,
    }.merge(bban_formats[country.country_code])
  end
end
# rubocop:enable Metrics/AbcSize

FILE_ELEMENTS = [
  # 0 Data element
  # 1 Name of country
  # 2 IBAN prefix country code (ISO 3166)
  COUNTRY_CODE = 2,
  # 3 Country code includes other countries/territories
  # 4 SEPA country
  # 5 SEPA country also includes
  # 6 Domestic account number example
  # 7 BBAN
  # 8 BBAN structure
  BBAN_STRUCTURE = 8,
  # 9 BBAN length
  # 10 Bank identifier position within the BBAN
  # 11 Bank identifier pattern
  BANK_IDENTIFIER_PATTERN = 11,
  # 12 Branch identifier position within the BBAN
  # 13 Branch identifier pattern
  BRANCH_IDENTIFIER_PATTERN = 13,
  # 14 Bank identifier example
  # 15 Branch identifier example
  # 16 BBAN example
  # 17 IBAN
  # 18 IBAN structure
  # 19 IBAN length
  # 20 Effective date
  # 21 IBAN electronic format example
].freeze

def get_bban_formats(iban_registry_file)
  iban_registry_file.each_with_object({}) do |line, hash|
    bban_structure = line[BBAN_STRUCTURE].strip

    bank_code_structure = line[BANK_IDENTIFIER_PATTERN].strip
    branch_code_structure = line[BRANCH_IDENTIFIER_PATTERN]&.strip

    bank_code_structure = "" if bank_code_structure == "N/A"

    country_code = line[COUNTRY_CODE].strip
    hash[country_code] = convert_swift_convention(bban_structure,
                                                  bank_code_structure,
                                                  branch_code_structure)
  end
end

# IBAN Registry has BBAN format (which seems to be accurate), and Bank
# identifier length, which contains something roughly like the format for the
# bank code and usually the branch code where applicable. This is a best attempt
# to convert those from weird SWIFT-talk into regexes, and then work out the
# account number format regex by taking the bank and branch code regexes off
# the front of the BBAN format.
#
# This works about 70% of the time, the rest are overridden in
# structure_additions.yml
def convert_swift_convention(bban, bank, branch)
  bban_regex = iban_registry_to_regex(bban)
  bank_regex = iban_registry_to_regex(bank)
  branch_regex = branch.nil? ? nil : iban_registry_to_regex(branch)

  non_account_number_regex = [bank_regex, branch_regex].join
  account_number_start = (bban_regex.index(non_account_number_regex) || 0) +
    non_account_number_regex.length
  account_number_regex = bban_regex[account_number_start..-1]

  {
    bban_format: bban_regex,
    bank_code_format: bank_regex,
    branch_code_format: branch_regex,
    account_number_format: account_number_regex,
  }.compact
end

def iban_registry_to_regex(swift_string)
  swift_string.gsub(/(\d+)!([nac])/, '\2{\1}').
    gsub("n", '\d').
    gsub("a", "[A-Z]").
    gsub("c", "[A-Z0-9]")
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
    File.expand_path("../data/raw/IBAN_Registry.txt", __dir__),
    col_sep: "\t",
    headers: true,
    encoding: Encoding::ISO_8859_1,
  ).to_a.transpose

  iban_registry_file.shift

  iban_structures_file = File.read(
    File.expand_path("../data/raw/IBANSTRUCTURE.xml", __dir__),
  )

  iban_structures = get_iban_structures(
    iban_structures_file,
    iban_registry_file,
  )

  structure_additions = YAML.safe_load(
    File.read(File.expand_path("../data/raw/structure_additions.yml", __dir__)),
    permitted_classes: [Range, Symbol],
  )

  complete_structures = merge_structures(iban_structures, structure_additions)

  output_file_path = File.expand_path(
    "../data/structures.yml",
    __dir__,
  )

  File.open(output_file_path, "w") { |f| f.write(complete_structures.to_yaml) }
end
