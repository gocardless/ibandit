require 'yaml'

module Ibandit
  class IBAN
    attr_reader :iban
    attr_reader :errors

    def self.structures
      @structures ||= YAML.load_file("#{File.dirname(__FILE__)}/structures.yml")
    end

    def initialize(iban)
      @iban = iban.to_s.gsub(/\s+/, '').upcase
      @errors = {}
    end

    def to_s(format = :compact)
      case format
      when :compact then iban
      when :formatted then formatted
      else raise ArgumentError, "invalid format '#{format}'"
      end
    end

    ###################
    # Component parts #
    ###################

    def country_code
      iban[0, 2]
    end

    def check_digits
      iban[2, 2] || ''
    end

    def bank_code
      return '' unless structure
      iban.slice(
        structure[:bank_code_position] - 1,
        structure[:bank_code_length]
      ) || ''
    end

    def branch_code
      return '' unless structure && structure[:branch_code_length] > 0

      iban.slice(
        structure[:branch_code_position] - 1,
        structure[:branch_code_length]
      ) || ''
    end

    def account_number
      return '' unless structure

      iban.slice(
        structure[:account_number_position] - 1,
        structure[:account_number_length]
      ) || ''
    end

    def iban_national_id
      return '' unless structure

      national_id = branch_code.nil? ? bank_code : bank_code + branch_code
      national_id.slice(0, structure[:iban_national_id_length])
    end

    def local_check_digits
      return '' unless structure && structure[:local_check_digit_position]

      iban.slice(structure[:local_check_digit_position] - 1,
                 structure[:local_check_digit_length]
      ) || ''
    end

    def bban
      iban[4..-1] || ''
    end

    ###############
    # Validations #
    ###############

    def valid?
      [
        valid_country_code?,
        valid_characters?,
        valid_check_digits?,
        valid_length?,
        valid_format?
      ].all?
    end

    def valid_country_code?
      if IBAN.structures.key?(country_code)
        true
      else
        @errors[:country_code] = "'#{country_code}' is not a valid " \
                                 'ISO 3166-1 IBAN country code'
        false
      end
    end

    def valid_check_digits?
      return unless valid_country_code? && valid_characters?

      expected_check_digits = CheckDigit.iban(country_code, bban)
      if check_digits == expected_check_digits
        true
      else
        @errors[:check_digits] = 'Check digits failed modulus check. ' \
                                 "Expected '#{expected_check_digits}', " \
                                 "received '#{check_digits}'"
        false
      end
    end

    def valid_length?
      return unless valid_country_code?

      if iban.size == structure[:total_length]
        true
      else
        @errors[:length] = "Length doesn't match SWIFT specification " \
                           "(expected #{structure[:total_length]} " \
                           "characters, received #{iban.size})"
        false
      end
    end

    def valid_characters?
      if iban.scan(/[^A-Z0-9]/).any?
        @errors[:characters] = 'Non-alphanumeric characters found: ' \
                               "#{iban.scan(/[^A-Z\d]/).join(' ')}"
        false
      else
        true
      end
    end

    def valid_format?
      return unless valid_country_code?

      if bban =~ Regexp.new(structure[:bban_format])
        true
      else
        @errors[:format] = "Unexpected format for a #{country_code} IBAN."
        false
      end
    end

    ###################
    # Private methods #
    ###################

    private

    def structure
      IBAN.structures[country_code]
    end

    def formatted
      iban.gsub(/(.{4})/, '\1 ').strip
    end
  end
end
