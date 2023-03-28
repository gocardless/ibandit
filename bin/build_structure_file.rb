#!/usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Layout/LineLength

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
  elements "ibanstructure_v2", as: :countries, class: Country
end

class IbanRegistryTextFile
  attr_accessor :lines, :registry

  FILE_ELEMENTS = [
    # 0 Data element
    # 1 Name of country
    # 2 IBAN prefix country code (ISO 3166)
    COUNTRY_CODE = 2,
    # 3 Country code includes other countries/territories
    # 4 SEPA country
    # 5 SEPA country also includes
    # 6 Domestic account number example
    DOMESTIC_ACCOUNT_NUMBER_EXAMPLE = 6,
    # 7 BBAN
    # 8 BBAN structure
    BBAN_STRUCTURE = 8,
    # 9 BBAN length
    # 10 Bank identifier position within the BBAN
    BANK_IDENTIFIER_POSITION = 10,
    # 11 Bank identifier pattern
    BANK_IDENTIFIER_PATTERN = 11,
    # 12 Branch identifier position within the BBAN
    BRANCH_IDENTIFIER_POSITION = 12,
    # 13 Branch identifier pattern
    BRANCH_IDENTIFIER_PATTERN = 13,
    # 14 Bank identifier example
    # 15 Branch identifier example
    # 16 BBAN example
    BBAN_EXAMPLE = 16,
    # 17 IBAN
    # 18 IBAN structure
    # 19 IBAN length
    # 20 Effective date
    # 21 IBAN electronic format example
    IBAN_EXAMPLE = 21,
  ].freeze

  def self.call(path = "../data/raw/IBAN_Registry.txt")
    lines = CSV.read(
      File.expand_path(path, __dir__),
      col_sep: "\t",
      headers: true,
      encoding: Encoding::ISO_8859_1,
    ).to_a.transpose.tap(&:shift)

    new(lines).tap(&:parse)
  end

  def initialize(lines)
    @lines = lines
    @registry = {}
  end

  def parse
    lines.each do |line|
      country_code = clean_string(line[COUNTRY_CODE])

      bban_details = convert_swift_convention(
        country_code: country_code,
        bban_structure: clean_string(line[BBAN_STRUCTURE]),
        bank_code_structure: clean_string(line[BANK_IDENTIFIER_PATTERN]),
        branch_code_structure: clean_string(line[BRANCH_IDENTIFIER_PATTERN]),
        bank_identifier_position: clean_string(line[BANK_IDENTIFIER_POSITION]),
        branch_identifier_position: clean_string(line[BRANCH_IDENTIFIER_POSITION]),
      ) || {}

      registry[country_code] = {
        iban_example: clean_string(line[IBAN_EXAMPLE]),
        bban_example: clean_string(line[BBAN_EXAMPLE]),
        domestic_account_number_example: clean_string(line[DOMESTIC_ACCOUNT_NUMBER_EXAMPLE]),
        **bban_details,
      }.compact
    end
  end

  private

  def clean_string(string)
    return nil if string.nil?

    string.strip!
    return nil if string == "N/A"

    string
  end

  # IBAN Registry has BBAN format (which seems to be accurate), and Bank
  # identifier length, which contains something roughly like the format for the
  # bank code and usually the branch code where applicable. This is a best attempt
  # to convert those from weird SWIFT-talk into regexes, and then work out the
  # account number format regex by taking the bank and branch code regexes off
  # the front of the BBAN format.
  #
  # This works about 90% of the time, the rest are overridden in
  # structure_additions.yml
  def convert_swift_convention( # rubocop:todo Metrics/AbcSize
    country_code:,
    bban_structure:,
    branch_code_structure:,
    bank_code_structure: nil,
    bank_identifier_position: nil,
    branch_identifier_position: nil
  )
    bban_regex = iban_registry_to_regex(bban_structure)
    bank_regex = iban_registry_to_regex(bank_code_structure)
    branch_regex = branch_code_structure.nil? ? nil : iban_registry_to_regex(branch_code_structure)

    bban_ranges = create_bban_ranges(bban_structure)
    ranges_to_remove = [
      convert_string_range(bank_identifier_position),
      convert_string_range(branch_identifier_position),
    ].compact.uniq
    max_bank_details_index = ranges_to_remove.map(&:last).max

    _, non_bank_identifier_ranges = bban_ranges.partition do |_, range|
      max_bank_details_index >= range.last
    end

    account_number_regex = iban_registry_to_regex(non_bank_identifier_ranges.map(&:first).join)

    {
      bban_format: bban_regex.source,
      bank_code_format: bank_regex.source,
      branch_code_format: branch_regex&.source,
      account_number_format: account_number_regex.source,
    }
  rescue StandardError => e
    puts "-----------------"
    puts "Issue with: #{country_code}"
    puts "\t #{e.message}"
    puts "\t #{e.backtrace}"
    puts "\t -----------------"
    puts "\t country_code: #{country_code}"
    puts "\t bban_structure: #{bban_structure}"
    puts "\t branch_code_structure: #{branch_code_structure}"
    puts "\t bank_code_structure: #{bank_code_structure}"
    puts "\t bank_identifier_position: #{bank_identifier_position}"
    puts "\t branch_identifier_position: #{branch_identifier_position}"
  end

  # Given "4!n4!n12!c" this returns an array that contains the ranges that cover the
  # structure. Eg; [["4!n", 0..3]]
  def create_bban_ranges(bban_structure)
    arr = bban_structure.scan(/((\d+)![anc])/)

    start = 0

    arr.each_with_object([]) do |(structure, length), acc|
      end_number = start + length.to_i - 1
      acc.push([structure, start..end_number])
      start = end_number + 1
    end
  end

  def convert_string_range(str)
    start_val, end_val = str.split("-").map(&:to_i)
    (start_val - 1)..(end_val - 1)
  rescue StandardError
    nil
  end

  def iban_registry_to_regex(swift_string)
    regex = swift_string.
      gsub(/(\d+)!n/, '\\d{\1}').
      gsub(/(\d+)!a/, '[A-Z]{\1}').
      gsub(/(\d+)!c/, '[A-Z0-9]{\1}')
    Regexp.new(regex)
  end
end

class IbanStructureFile
  attr_accessor :report, :iban_registry_file

  def self.call(iban_registry_file, path: "../data/raw/IBANSTRUCTURE.xml")
    iban_structures_file = File.read(File.expand_path(path, __dir__))
    new(iban_registry_file:, iban_structures_file:).parse
  end

  def initialize(iban_registry_file:, iban_structures_file:)
    @iban_registry_file = iban_registry_file
    @report = Report.parse(iban_structures_file)
  end

  def parse # rubocop:todo Metrics/AbcSize
    report.countries.each_with_object({}) do |country, hash|
      country_bban = iban_registry_file.registry[country.country_code] || {}

      hash[country.country_code] = {
        bank_code_position: country.bank_code_position.to_i,
        bank_code_length: country.bank_code_length.to_i,
        branch_code_position: country.branch_code_position.to_i,
        branch_code_length: country.branch_code_length.to_i,
        account_number_position: country.account_number_position.to_i,
        account_number_length: country.account_number_length.to_i,
        total_length: country.total_length.to_i,
        national_id_length: country.national_id_length.to_i,
        **country_bban,
      }
    end
  end
end

def merge_structures(structures, additions)
  additions.each_pair do |key, value|
    structures[key].merge!(value).compact! if structures.include?(key)
  end

  structures
end

def load_yaml_file(path)
  YAML.safe_load(
    File.read(File.expand_path(path, __dir__)),
    permitted_classes: [Range, Symbol, Regexp],
  )
end

# Only parse the files if this file is run as an executable (not required in,
# as it is in the specs)
if __FILE__ == $PROGRAM_NAME
  old_file = load_yaml_file("../data/structures.yml")

  iban_registry_file = IbanRegistryTextFile.call
  iban_structures = IbanStructureFile.call(iban_registry_file)

  structure_additions = load_yaml_file("../data/raw/structure_additions.yml")

  complete_structures = merge_structures(iban_structures, structure_additions)
  pseudo_ibans = load_yaml_file("../data/raw/pseudo_ibans.yml")

  complete_structures.merge!(pseudo_ibans)

  output_file_path = File.expand_path(
    "../data/structures.yml",
    __dir__,
  )

  File.open(output_file_path, "w") { |f| f.write(complete_structures.to_yaml) }

  new_countries = old_file.keys.to_set ^ complete_structures.keys.to_set
  puts "New countries:"
  new_countries.each do |country|
    puts "#{country} #{complete_structures[country][:iban_example]} #{complete_structures[country][:domestic_account_number_example]}"
  end
end

# rubocop:enable Layout/LineLength
