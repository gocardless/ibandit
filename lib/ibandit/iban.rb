require 'yaml'

module Ibandit
  class IBAN
    attr_reader :errors, :iban,  :country_code, :check_digits, :bank_code,
                :branch_code, :account_number

    def initialize(argument)
      if argument.is_a?(String)
        @iban = argument.to_s.gsub(/\s+/, '').upcase
        extract_local_details_from_iban!
      elsif argument.is_a?(Hash)
        build_iban_from_local_details(argument)
      else
        raise TypeError, 'Must pass an IBAN string or hash of local details'
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

    ###################
    # Component parts #
    ###################

    def iban_national_id
      return unless decomposable?

      national_id = bank_code.to_s
      national_id += branch_code.to_s
      national_id.slice(0, structure[:iban_national_id_length])
    end

    def local_check_digits
      return unless decomposable? && structure[:local_check_digit_position]

      iban.slice(
        structure[:local_check_digit_position] - 1,
        structure[:local_check_digit_length]
      )
    end

    def bban
      iban[4..-1] unless iban.nil?
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
      return unless decomposable? && valid_characters?

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
      return unless valid_country_code? && !iban.nil?

      if iban.length == structure[:total_length]
        true
      else
        @errors[:length] = "Length doesn't match SWIFT specification " \
                           "(expected #{structure[:total_length]} " \
                           "characters, received #{iban.size})"
        false
      end
    end

    def valid_bank_code_length?
      return unless valid_country_code?

      if bank_code.nil? || bank_code.length == 0
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
      return true if branch_code.to_s.length == structure[:branch_code_length]

      if structure[:branch_code_length] == 0
        @errors[:branch_code] = "is not used in #{country_code}"
      elsif branch_code.nil? || branch_code.length == 0
        @errors[:branch_code] = 'is required'
      else
        @errors[:branch_code] = 'is the wrong length: must be ' \
                                "#{structure[:branch_code_length]}, not " \
                                "#{branch_code.length}"
      end
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
      return if iban.nil?
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

    def decomposable?
      [iban, country_code, bank_code, account_number].none?(&:nil?)
    end

    def build_iban_from_local_details(details_hash)
      local_details = LocalDetailsCleaner.clean(details_hash)

      @country_code   = local_details[:country_code].dup
      @account_number = local_details[:account_number].dup
      @branch_code    = local_details[:branch_code].dup
      @bank_code      = local_details[:bank_code].dup
      @iban           = IBANAssembler.assemble(local_details)
      @check_digits   = @iban.slice(2, 2) unless @iban.nil?
    end

    def extract_local_details_from_iban!
      local_details = IBANSplitter.split(@iban)

      @country_code   = local_details[:country_code]
      @check_digits   = local_details[:check_digits]
      @bank_code      = local_details[:bank_code]
      @branch_code    = local_details[:branch_code]
      @account_number = local_details[:account_number]
    end

    def structure
      Ibandit.structures[country_code]
    end

    def formatted
      iban.gsub(/(.{4})/, '\1 ').strip
    end
  end
end
