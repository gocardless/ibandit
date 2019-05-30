# frozen_string_literal: true

module Ibandit
  module IBANSplitter
    def self.split(iban)
      {
        country_code: country_code_from(iban),
        check_digits: check_digits_from(iban),
        bank_code: bank_code_from(iban),
        branch_code: branch_code_from(iban),
        account_number: account_number_from(iban),
      }
    end

    ###################
    # Component parts #
    ###################

    def self.country_code_from(iban)
      return if iban.nil? || iban.empty?

      iban.slice(0, 2)
    end

    def self.check_digits_from(iban)
      return unless decomposable?(iban)

      iban.slice(2, 2)
    end

    def self.bank_code_from(iban)
      return unless decomposable?(iban)

      iban.slice(
        structure(iban)[:bank_code_position] - 1,
        structure(iban)[:bank_code_length],
      )
    end

    def self.branch_code_from(iban)
      return unless decomposable?(iban) &&
        structure(iban)[:branch_code_length]&.positive?

      iban.slice(
        structure(iban)[:branch_code_position] - 1,
        structure(iban)[:branch_code_length],
      )
    end

    def self.account_number_from(iban)
      return unless decomposable?(iban)

      iban.slice(
        structure(iban)[:account_number_position] - 1,
        structure(iban)[:account_number_length],
      )
    end

    def self.decomposable?(iban)
      structure(iban) && iban.length == structure(iban)[:total_length]
    end

    def self.structure(iban)
      Ibandit.structures[country_code_from(iban)]
    end
  end
end
