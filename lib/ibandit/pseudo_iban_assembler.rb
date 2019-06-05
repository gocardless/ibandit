# frozen_string_literal: true

module Ibandit
  class PseudoIBANAssembler
    def initialize(country_code: nil,
                   bank_code: nil,
                   branch_code: nil,
                   account_number: nil)
      @country_code = country_code
      @bank_code = bank_code
      @branch_code = branch_code
      @account_number = account_number
    end

    def assemble
      return unless can_assemble?

      [
        @country_code,
        Constants::PSEUDO_IBAN_CHECK_DIGITS,
        padded_bank_code,
        padded_branch_code,
        padded_account_number,
      ].join
    end

    private

    def can_assemble?
      country_code_valid? &&
        bank_code_valid? &&
        branch_code_valid? &&
        account_number_valid?
    end

    def country_code_valid?
      Constants::PSEUDO_IBAN_COUNTRY_CODES.include?(@country_code)
    end

    def padding_character
      Constants::PSEUDO_IBAN_PADDING_CHARACTER_FOR[@country_code]
    end

    def bank_code_valid?
      param_valid?(@bank_code, :pseudo_iban_bank_code_length)
    end

    def branch_code_valid?
      param_valid?(@branch_code, :pseudo_iban_branch_code_length)
    end

    def account_number_valid?
      param_valid?(@account_number, :pseudo_iban_account_number_length)
    end

    def param_valid?(value, length_key)
      return true unless value.nil?
      return true if structure[length_key]&.zero?

      false
    end

    def padded_bank_code
      pad(@bank_code, :pseudo_iban_bank_code_length)
    end

    def padded_branch_code
      pad(@branch_code, :pseudo_iban_branch_code_length)
    end

    def padded_account_number
      pad(@account_number, :pseudo_iban_account_number_length)
    end

    def pad(number, length_key)
      return if number.nil?

      number.rjust(structure[length_key], padding_character)
    end

    def structure
      Ibandit.structures.fetch(@country_code)
    end
  end
end
