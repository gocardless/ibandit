module Ibandit
  class PseudoIBANSplitter
    def initialize(pseudo_iban)
      @pseudo_iban = pseudo_iban
    end

    def split
      return unless decomposable?

      {
        country_code: country_code,
        bank_code: bank_code,
        branch_code: branch_code,
        account_number: account_number,
      }
    end

    private

    def country_code
      @pseudo_iban.slice(0, 2)
    end

    def check_digits
      @pseudo_iban.slice(2, 2)
    end

    def bank_code
      pseudo_iban_part(bank_code_start_index, :pseudo_iban_bank_code_length)
    end

    def branch_code
      pseudo_iban_part(branch_code_start_index,
                       :pseudo_iban_branch_code_length)
    end

    def account_number
      pseudo_iban_part(account_number_start_index,
                       :pseudo_iban_account_number_length)
    end

    def pseudo_iban_part(start_index, length_key)
      length = structure.fetch(length_key)
      return if length == 0

      @pseudo_iban.slice(start_index, length).gsub(/\AX+/, "")
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

    def expected_length
      account_number_start_index +
        structure.fetch(:pseudo_iban_account_number_length)
    end

    def decomposable?
      country_code_valid? && check_digits_valid? && correct_length?
    end

    def country_code_valid?
      Constants::PSEUDO_IBAN_COUNTRY_CODES.include?(country_code)
    end

    def check_digits_valid?
      check_digits == Constants::PSEUDO_IBAN_CHECK_DIGITS
    end

    def correct_length?
      @pseudo_iban.length == expected_length
    end

    def structure
      Ibandit.structures[country_code]
    end
  end
end
