#!/usr/bin/env ruby
# frozen_string_literal: true

# Script for parsing the Bankleitzahl file (BLZ2.xml) from the Deutsche Bundesbank.
require "yaml"
require "sax-machine"

class BLZRecord
  include SAXMachine
  element "BLZ", as: :bank_code
  element "Merkmal", as: :primary_record
  element "PruefZiffMeth", as: :check_digit_rule
  element "IBANRegel", as: :iban_rule
end

class BLZFile
  include SAXMachine
  elements "BLZEintrag", as: :records, class: BLZRecord
end

def get_iban_rules(blz2_file)
  BLZFile.parse(blz2_file).records.each_with_object({}) do |bank_details, hash|
    next if bank_details.primary_record == "2"

    hash[bank_details.bank_code] = {
      check_digit_rule: bank_details.check_digit_rule,
      iban_rule: bank_details.iban_rule,
    }
  end
end

# Only parse the files if this file is run as an executable (not required in,
# as it is in the specs)
if __FILE__ == $PROGRAM_NAME
  blz2_file = File.read(File.expand_path("../data/raw/BLZ2.xml", __dir__))
  iban_rules = get_iban_rules(blz2_file)

  output_file_path = File.expand_path(
    "../data/german_iban_rules.yml",
    __dir__,
  )

  File.open(output_file_path, "w") { |f| f.write(iban_rules.to_yaml) }
end
