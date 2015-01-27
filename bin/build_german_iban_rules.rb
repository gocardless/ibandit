#!/usr/bin/env ruby

# Script for parsing the Bankleitzahl file (BLZ2.txt) from the Deutsche
# Bundesbank.
require 'yaml'

BLZ_FIELDS = {
  bank_code:           { position: 0, length: 8 },
  primary_record:      { position: 8, length: 1 },
  check_digit_rule:    { position: 150, length: 2 },
  iban_rule:           { position: 168, length: 6 }
}.freeze

def parse_line(line)
  BLZ_FIELDS.each_with_object({}) do |(field, details), hash|
    hash[field] = line.slice(details[:position], details[:length])
  end
end

def get_iban_rules(blz2_file)
  blz2_file.each_with_object({}) do |line, hash|
    bank_details = parse_line(line)

    next if bank_details.delete(:primary_record) == '2'

    hash[bank_details.delete(:bank_code)] = bank_details
  end
end

# Only parse the files if this file is run as an executable (not required in,
# as it is in the specs)
if __FILE__ == $PROGRAM_NAME
  blz2_file = File.open(File.expand_path('../../data/raw/BLZ2.txt', __FILE__))
  iban_rules = get_iban_rules(blz2_file)

  output_file_path = File.expand_path(
    '../../data/german_iban_rules.yml',
    __FILE__
  )

  File.open(output_file_path, 'w') { |f| f.write(iban_rules.to_yaml) }
end
