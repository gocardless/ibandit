# frozen_string_literal: true

require "yaml"

module Ibandit
  class IBAN
    attr_reader :errors, :iban, :country_code, :check_digits, :bank_code,
                :branch_code, :account_number, :swift_bank_code,
                :swift_branch_code, :swift_account_number

    def initialize(argument)
      if argument.is_a?(String)
        input = argument.to_s.gsub(/\s+/, "").upcase

        if pseudo_iban?(input) && !PseudoIBANSplitter.new(input).split.nil?
          local_details = PseudoIBANSplitter.new(input).split
          build_iban_from_local_details(local_details)
        else
          @iban = input
          extract_swift_details_from_iban!
        end
      elsif argument.is_a?(Hash)
        build_iban_from_local_details(argument)
      else
        raise TypeError, "Must pass an IBAN string or hash of local details"
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

    def swift_national_id
      return unless decomposable?

      national_id = swift_bank_code.to_s
      national_id += swift_branch_code.to_s
      national_id.slice(0, structure[:national_id_length])
    end

    def local_check_digits
      return unless decomposable? && structure[:local_check_digit_position]

      iban.slice(
        structure[:local_check_digit_position] - 1,
        structure[:local_check_digit_length],
      )
    end

    def bban
      iban[4..-1] unless iban.nil?
    end

    def pseudo_iban
      @pseudo_iban ||= PseudoIBANAssembler.new(
        country_code: country_code,
        bank_code: bank_code,
        branch_code: branch_code,
        account_number: account_number,
      ).assemble
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
        valid_local_modulus_check?,
        passes_country_specific_checks?,
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

      if swift_bank_code.nil? || swift_bank_code.empty?
        @errors[:bank_code] = Ibandit.translate(:is_required)
        return false
      end

      return true if swift_bank_code.length == structure[:bank_code_length]

      @errors[:bank_code] =
        Ibandit.translate(:wrong_length, expected: structure[:bank_code_length])
      false
    end

    def valid_branch_code_length?
      return unless valid_country_code?
      if swift_branch_code.to_s.length == structure[:branch_code_length]
        return true
      end

      if structure[:branch_code_length].zero?
        @errors[:branch_code] = Ibandit.translate(:not_used_in_country,
                                                  country_code: country_code)
      elsif swift_branch_code.nil? || swift_branch_code.empty?
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

      if swift_account_number.nil?
        @errors[:account_number] = Ibandit.translate(:is_required)
        return false
      end

      if swift_account_number.length == structure[:account_number_length]
        return true
      end

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
                            characters: iban.scan(/[^A-Z\d]/).join(" "))
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

      if swift_bank_code =~ Regexp.new(structure[:bank_code_format])
        true
      else
        @errors[:bank_code] = Ibandit.translate(:is_invalid)
        false
      end
    end

    def valid_branch_code_format?
      return unless valid_branch_code_length?
      return true unless structure[:branch_code_format]

      if swift_branch_code =~ Regexp.new(structure[:branch_code_format])
        true
      else
        @errors[:branch_code] = Ibandit.translate(:is_invalid)
        false
      end
    end

    def valid_account_number_format?
      return unless valid_account_number_length?

      if swift_account_number =~ Regexp.new(structure[:account_number_format])
        true
      else
        @errors[:account_number] = Ibandit.translate(:is_invalid)
        false
      end
    end

    def valid_local_modulus_check?
      return unless valid_format?
      return true unless Ibandit.modulus_checker

      valid_modulus_check_bank_code? &&
        valid_modulus_check_branch_code? &&
        valid_modulus_check_account_number?
    end

    def passes_country_specific_checks?
      return unless valid_country_code?

      case country_code
      when "DE" then supports_iban_determination?
      when "SE" then valid_swedish_details?
      else true
      end
    end

    def supports_iban_determination?
      return unless valid_format?
      return true unless country_code == "DE"

      begin
        GermanDetailsConverter.convert(
          country_code: country_code,
          bank_code: swift_bank_code,
          account_number: swift_account_number,
        )
        true
      rescue UnsupportedAccountDetails
        @errors[:account_number] = Ibandit.translate(:does_not_support_payments)
        false
      end
    end

    def valid_swedish_details?
      return true unless country_code == "SE"

      if branch_code
        valid_swedish_local_details?
      else
        valid_swedish_swift_details?
      end
    end

    def valid_swedish_swift_details?
      unless Sweden::Validator.bank_code_exists?(swift_bank_code)
        bank_code_field = bank_code.nil? ? :account_number : :bank_code
        @errors[bank_code_field] = Ibandit.translate(:is_invalid)
        @errors.delete(:bank_code) if bank_code.nil?
        return false
      end

      length_valid =
        Sweden::Validator.account_number_length_valid_for_bank_code?(
          bank_code: swift_bank_code,
          account_number: swift_account_number,
        )

      unless length_valid
        @errors[:account_number] = Ibandit.translate(:is_invalid)
        return false
      end

      true
    end

    def valid_swedish_local_details?
      unless Sweden::Validator.valid_clearing_code_length?(branch_code)
        @errors[:branch_code] = Ibandit.translate(:is_invalid)
        return false
      end

      valid_serial_number = Sweden::Validator.valid_serial_number_length?(
        clearing_code: branch_code,
        serial_number: account_number,
      )

      unless valid_serial_number
        @errors[:account_number] = Ibandit.translate(:is_invalid)
        return false
      end

      true
    end

    ###################
    # Private methods #
    ###################

    private

    def decomposable?
      [iban, country_code, swift_bank_code, swift_account_number].none?(&:nil?)
    end

    def build_iban_from_local_details(details_hash)
      local_details = LocalDetailsCleaner.clean(details_hash)

      @country_code         = try_dup(local_details[:country_code])
      @account_number       = try_dup(local_details[:account_number])
      @branch_code          = try_dup(local_details[:branch_code])
      @bank_code            = try_dup(local_details[:bank_code])

      @swift_account_number = try_dup(local_details[:swift_account_number])
      @swift_branch_code    = try_dup(local_details[:swift_branch_code])
      @swift_bank_code      = try_dup(local_details[:swift_bank_code])

      @iban                 = IBANAssembler.assemble(swift_details)
      @check_digits         = @iban.slice(2, 2) unless @iban.nil?
    end

    def extract_swift_details_from_iban!
      swift_details = IBANSplitter.split(@iban)

      @country_code         = swift_details[:country_code]
      @check_digits         = swift_details[:check_digits]

      @swift_bank_code      = swift_details[:bank_code]
      @swift_branch_code    = swift_details[:branch_code]
      @swift_account_number = swift_details[:account_number]

      return if Constants::PSEUDO_IBAN_COUNTRY_CODES.
          include?(@country_code)

      @bank_code      = swift_details[:bank_code]
      @branch_code    = swift_details[:branch_code]
      @account_number = swift_details[:account_number]
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
      return true if Ibandit.modulus_checker.valid_bank_code?(self)

      @errors[:bank_code] = Ibandit.translate(:is_invalid)
      false
    end

    def valid_modulus_check_branch_code?
      return true if Ibandit.modulus_checker.valid_branch_code?(self)

      @errors[:branch_code] = Ibandit.translate(:is_invalid)
      false
    end

    def valid_modulus_check_account_number?
      return true if Ibandit.modulus_checker.valid_account_number?(self)

      @errors[:account_number] = Ibandit.translate(:is_invalid)
      false
    end

    def swift_details
      {
        country_code: @country_code,
        account_number: @swift_account_number,
        branch_code: @swift_branch_code,
        bank_code: @swift_bank_code,
      }
    end

    def pseudo_iban?(input)
      input.slice(2, 2) == Constants::PSEUDO_IBAN_CHECK_DIGITS
    end
  end
end
