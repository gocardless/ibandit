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
      when :compact   then iban.to_s
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
        valid_format?,
        valid_bank_code_format?,
        valid_branch_code_format?,
        valid_account_number_format?,
        valid_local_modulus_check?
      ].all?
    end

    def valid_country_code?
      if Ibandit.structures.key?(country_code)
        true
      else
        @errors[:country_code] = Ibandit.translate(:invalid_country_code,
                                                   country_code: country_code)
        false
      end
    end

    def valid_check_digits?
      return unless decomposable? && valid_characters?

      expected_check_digits = CheckDigit.iban(country_code, bban)
      if check_digits == expected_check_digits
        true
      else
        @errors[:check_digits] =
          Ibandit.translate(:invalid_check_digits,
                            expected_check_digits: expected_check_digits,
                            check_digits: check_digits)
        false
      end
    end

    def valid_length?
      return unless valid_country_code? && !iban.nil?

      if iban.length == structure[:total_length]
        true
      else
        @errors[:length] =
          Ibandit.translate(:invalid_length,
                            expected_length: structure[:total_length],
                            length: iban.size)
        false
      end
    end

    def valid_bank_code_length?
      return unless valid_country_code?

      if bank_code.nil? || bank_code.length == 0
        @errors[:bank_code] = Ibandit.translate(:is_required)
        return false
      end

      return true if bank_code.length == structure[:bank_code_length]

      @errors[:bank_code] =
        Ibandit.translate(:wrong_length, expected: structure[:bank_code_length])
      false
    end

    def valid_branch_code_length?
      return unless valid_country_code?
      return true if branch_code.to_s.length == structure[:branch_code_length]

      if structure[:branch_code_length] == 0
        @errors[:branch_code] = Ibandit.translate(:not_used_in_country,
                                                  country_code: country_code)
      elsif branch_code.nil? || branch_code.length == 0
        @errors[:branch_code] = Ibandit.translate(:is_required)
      else
        @errors[:branch_code] =
          Ibandit.translate(:wrong_length,
                            expected: structure[:branch_code_length])
      end
      false
    end

    def valid_account_number_length?
      return unless valid_country_code?

      if account_number.nil?
        @errors[:account_number] = Ibandit.translate(:is_required)
        return false
      end

      return true if account_number.length == structure[:account_number_length]

      @errors[:account_number] =
        Ibandit.translate(:wrong_length,
                          expected: structure[:account_number_length])
      false
    end

    def valid_characters?
      return if iban.nil?
      if iban.scan(/[^A-Z0-9]/).any?
        @errors[:characters] =
          Ibandit.translate(:non_alphanumeric_characters,
                            characters: iban.scan(/[^A-Z\d]/).join(' '))
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
        @errors[:format] = Ibandit.translate(:invalid_format,
                                             country_code: country_code)
        false
      end
    end

    def valid_bank_code_format?
      return unless valid_bank_code_length?

      if bank_code =~ Regexp.new(structure[:bank_code_format])
        true
      else
        @errors[:bank_code] = Ibandit.translate(:is_invalid)
        false
      end
    end

    def valid_branch_code_format?
      return unless valid_branch_code_length?
      return true unless structure[:branch_code_format]

      if branch_code =~ Regexp.new(structure[:branch_code_format])
        true
      else
        @errors[:branch_code] = Ibandit.translate(:is_invalid)
        false
      end
    end

    def valid_account_number_format?
      return unless valid_account_number_length?

      if account_number =~ Regexp.new(structure[:account_number_format])
        true
      else
        @errors[:account_number] = Ibandit.translate(:is_invalid)
        false
      end
    end

    def valid_local_modulus_check?
      return unless valid_format?
      return true unless Ibandit.modulus_checker

      valid_modulus_check_bank_code? && valid_modulus_check_account_number?
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

      @country_code   = try_dup(local_details[:country_code])
      @account_number = try_dup(local_details[:account_number])
      @branch_code    = try_dup(local_details[:branch_code])
      @bank_code      = try_dup(local_details[:bank_code])
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

    def try_dup(object)
      object.dup
    rescue TypeError
      object
    end

    def structure
      Ibandit.structures[country_code]
    end

    def formatted
      iban.to_s.gsub(/(.{4})/, '\1 ').strip
    end

    def valid_modulus_check_bank_code?
      return true if Ibandit.modulus_checker.valid_bank_code?(iban.to_s)

      @errors[modulus_check_bank_code_field] = Ibandit.translate(:is_invalid)
      false
    end

    def valid_modulus_check_account_number?
      return true if Ibandit.modulus_checker.valid_account_number?(iban.to_s)

      @errors[:account_number] = Ibandit.translate(:is_invalid)
      false
    end

    def modulus_check_bank_code_field
      if LocalDetailsCleaner.required_fields(country_code).
         include?(:branch_code)
        :branch_code
      else
        :bank_code
      end
    end
  end
end
