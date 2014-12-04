#!/usr/bin/env ruby

# Script for parsing the IBAN registry (IBAN_Registry.txt) and IBAN structures
# (IBANSTRUCTURE.txt) files from SWIFT.
#
require 'csv'
require 'yaml'

def get_iban_structures(iban_structures_file, iban_registry_file)
  bban_formats = iban_registry_file.each_with_object({}) do |line, hash|
    bban_structure = line['BBAN structure '].strip
    country_code = line['Country code as defined in ISO 3166'].strip
    hash[country_code] = convert_swift_convention(bban_structure)
  end

  iban_structures_file.each_with_object({}) do |line, hash|
    country_code = line['IBAN COUNTRY CODE']

    hash[country_code] = {
      bank_code_position: line["BANK IDENTIFIER POSITION"].to_i,
      bank_code_length: line["BANK IDENTIFIER LENGTH"].to_i,
      branch_code_position: line["BRANCH IDENTIFIER POSITION"].to_i,
      branch_code_length: line["BRANCH IDENTIFIER LENGTH"].to_i,
      account_number_position: line["ACCOUNT NUMBER POSITION"].to_i,
      account_number_length: line["ACCOUNT NUMBER LENGTH"].to_i,
      total_length: line["IBAN TOTAL LENGTH"].to_i,
      iban_national_id_length: line["IBAN NATIONAL ID LENGTH"].to_i,
      bban_format: bban_formats[country_code]
    }
  end
end

def convert_swift_convention(swift_string)
  regex_string = swift_string.gsub(/(\d+)!([nac])/, '\2{\1}').
                              gsub('n', '\d').
                              gsub('a', '[A-Z]').
                              gsub('c', '[A-Z0-9]')
end

# Only parse the files if this file is run as an executable (not required in,
# as it is in the specs)
if __FILE__ == $0
  iban_registry_file = CSV.read(
    File.expand_path("../../data/IBAN_Registry.txt", __FILE__),
    col_sep: "\t",
    headers: true
  )

  iban_structures_file = CSV.read(
    File.expand_path("../../data/IBANSTRUCTURE.txt", __FILE__),
    col_sep: "\t",
    headers: true
  )

  iban_structures = get_iban_structures(
    iban_structures_file,
    iban_registry_file
  )

  output_file_path = File.expand_path(
    "../../lib/ibandit/structures.yml",
    __FILE__
  )

  File.open(output_file_path, "w") do |f|
    f.write(iban_structures.to_yaml)
  end
end
