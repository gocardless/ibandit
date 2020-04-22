#!/usr/bin/env ruby

# Script for parsing the Bankleitzahl file (BLZ2.xlsx) from the Deutsche
# Bundesbank.
# Directions:
# Locate the BLZ2.xlsx and place in data/raw/BLZ2.xlsx

require 'yaml'
require 'roo'
require_relative '../lib/ibandit/german_details_converter'

class Parser
  BLZ_FIELDS = {
    bank_code: "BLZ",
    primary_record: "eigene BLZ",
    check_digit_rule: "Prüfziffer",
    iban_rule: "IBAN",
  }

  attr_reader :rules

  def initialize(file_path:)
    @xlsx_file = Roo::Excelx.new(file_path)
    @data_positions = {}
    @rules = {}
  end

  def run!
    generate_rules!
    validate_rules_exist!
    true
  end

  private

  attr_reader :xlsx_file, :data_positions

  def parse_line(line)
    data_positions.each_with_object({}) do |(field, position), hash|
      hash[field] = line[position].value.to_s
    end
  end

  def determine_data_locations(line)
    BLZ_FIELDS.each_with_object({}) do |(field, header_name), hash|
      cell = line.find { |cell| cell.value == header_name }

      raise "Can't find '#{header_name}', file format may have changed!" unless cell

      # eg cell.coordinate = [1, 2], row 1 column 2, minus 1 for the array access
      hash[field] = cell.coordinate[1] - 1
    end
  end

  def generate_rules!
    @rules = xlsx_file.each_row_streaming.with_object({}) do |line, hash|
      # Are we on the header line?
      if line.first.coordinate[0] == 1
        data_positions.merge!(determine_data_locations(line))
      else
        bank_details = parse_line(line)

        next if bank_details.delete(:primary_record) == '2'

        hash[bank_details.delete(:bank_code)] = bank_details
      end
    end
  end

  def validate_rules_exist!
    iban_rules = rules.values.map { |r| r.fetch(:iban_rule) }.uniq
    iban_rule_classes = Ibandit::GermanDetailsConverter::BaseRule.all_iban_rules

    iban_rules.each do |iban_rule|
      if Ibandit::GermanDetailsConverter.const_defined?("Rule#{iban_rule}")
        iban_rule_classes.delete(Ibandit::GermanDetailsConverter.const_get("Rule#{iban_rule}"))
      else
        puts "Warning: Rule#{iban_rule} doesn't exist in german_details_converter"
      end
    end

    iban_rule_classes.each do |rule|
      puts "Note: No bank codes using Rule#{rule}"
    end
  end
end

# Only parse the files if this file is run as an executable (not required in,
# as it is in the specs)
if __FILE__ == $PROGRAM_NAME
  parser = Parser.new(file_path: File.expand_path('../../data/raw/BLZ2.xlsx', __FILE__))
  parser.run!
  iban_rules = parser.rules

  output_file_path = File.expand_path(
    '../../data/german_iban_rules.yml',
    __FILE__
  )

  File.open(output_file_path, 'w') { |f| f.write(iban_rules.to_yaml) }
end
