require 'yaml'

module Ibandit
  class IBAN
    attr_reader :errors

    def initialize(string_or_hash)
      @iban_parts =
        if string_or_hash.is_a?(Hash)
          IBANBuilder.build(string_or_hash)
        elsif string_or_hash.nil? || string_or_hash.is_a?(String)
          IBANSplitter.new(string_or_hash).parts
        else
          raise TypeError, 'Must pass an IBAN string, or hash of local details'
        end

      @errors = {}
    end

    def to_s(format = :compact)
      case format
      when :compact   then iban
      when :formatted then formatted
      else raise ArgumentError, "invalid format '#{format}'"
      end
    end

    %i(country_code check_digits bank_code branch_code account_number iban).
      each { |part| define_method(part) { @iban_parts[part] || '' } }

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
        valid_bank_code_length?,
        valid_branch_code_length?,
        valid_account_number_length?,
        valid_format?
      ].all?
    end

    def valid_country_code?
      if Ibandit.structures.key?(country_code)
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

    def valid_bank_code_length?
      return unless valid_country_code?

      if bank_code.nil?
        @errors[:bank_code] = 'is required'
        return false
      end

      return true if bank_code.length == structure[:bank_code_length]

      @errors[:bank_code] = 'is the wrong length: must be ' \
                            "#{structure[:bank_code_length]}, not " \
                            "#{bank_code.length}"
      false
    end

    def valid_branch_code_length?
      return unless valid_country_code?

      if branch_code.length == 0 && structure[:branch_code_length] > 0
        @errors[:branch_code] = 'is required'
        return false
      end

      if branch_code.length > 0 && structure[:branch_code_length] == 0
        @errors[:branch_code] = "is not used in #{country_code}"
        return false
      end

      return true if branch_code.length == structure[:branch_code_length]

      @errors[:branch_code] = 'is the wrong length: must be ' \
                              "#{structure[:branch_code_length]}, not " \
                              "#{branch_code.length}"
      false
    end

    def valid_account_number_length?
      return unless valid_country_code?

      if account_number.nil?
        @errors[:account_number] = 'is required'
        return false
      end

      return true if account_number.length == structure[:account_number_length]

      @errors[:account_number] = 'is the wrong length: must be ' \
                                 "#{structure[:account_number_length]}, not "\
                                 "#{account_number.length}"
      false
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
      Ibandit.structures[country_code]
    end

    def formatted
      iban.gsub(/(.{4})/, '\1 ').strip
    end
  end
end
