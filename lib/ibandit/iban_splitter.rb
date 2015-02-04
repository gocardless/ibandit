module Ibandit
  class IBANSplitter
    attr_reader :iban

    def initialize(iban)
      @iban = iban
    end

    def parts
      {
        country_code:   country_code,
        check_digits:   check_digits,
        bank_code:      bank_code,
        branch_code:    branch_code,
        account_number: account_number
      }
    end

    ###################
    # Component parts #
    ###################

    private

    def country_code
      return if iban.nil? || iban.empty?

      iban.slice(0, 2)
    end

    def check_digits
      return unless decomposable?

      iban.slice(2, 2)
    end

    def bank_code
      return unless decomposable?

      iban.slice(
        structure[:bank_code_position] - 1,
        structure[:bank_code_length]
      )
    end

    def branch_code
      return unless decomposable? && structure[:branch_code_length] > 0

      iban.slice(
        structure[:branch_code_position] - 1,
        structure[:branch_code_length]
      )
    end

    def account_number
      return unless decomposable?

      iban.slice(
        structure[:account_number_position] - 1,
        structure[:account_number_length]
      )
    end

    def decomposable?
      structure && iban.length == structure[:total_length]
    end

    def structure
      Ibandit.structures[country_code]
    end
  end
end
