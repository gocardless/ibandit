# frozen_string_literal: true

module Ibandit
  class PseudoIBANSplitter
    def initialize(pseudo_iban)
      @pseudo_iban = pseudo_iban
    end

    def split
      {
        country_code: country_code,
        check_digits: check_digits,
        bank_code: bank_code,
        branch_code: branch_code,
        account_number: account_number,
      }
    end

    def country_code
      @pseudo_iban.slice(0, 2)
    end

    private

    def check_digits
      @pseudo_iban.slice(2, 2)
    end

    def bank_code
      return unless country_code_valid?

      pseudo_iban_part(bank_code_start_index, :pseudo_iban_bank_code_length)
    end

    def branch_code
      return unless country_code_valid?

      pseudo_iban_part(branch_code_start_index, :pseudo_iban_branch_code_length)
    end

    def account_number
      return unless country_code_valid?

      remove_leading_padding(
        @pseudo_iban.slice(account_number_start_index, @pseudo_iban.length),
      )
    end

    def pseudo_iban_part(start_index, length_key)
      length = structure.fetch(length_key)
      return if length&.zero?

      remove_leading_padding(@pseudo_iban.slice(start_index, length))
    end

    def bank_code_start_index
      4
    end

    def branch_code_start_index
      bank_code_start_index + structure.fetch(:pseudo_iban_bank_code_length)
    end

    def account_number_start_index
      branch_code_start_index + structure.fetch(:pseudo_iban_branch_code_length)
    end

    def country_code_valid?
      Constants::PSEUDO_IBAN_COUNTRY_CODES.include?(country_code)
    end

    def padding_character
      Constants::PSEUDO_IBAN_PADDING_CHARACTER_FOR[country_code]
    end

    def structure
      Ibandit.structures[country_code]
    end

    def remove_leading_padding(input)
      return unless padding_character

      input.gsub(/\A#{padding_character}+/, "")
    end
  end
end
