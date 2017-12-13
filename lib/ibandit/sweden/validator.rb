# frozen_string_literal: true

module Ibandit
  module Sweden
    class Validator
      ###########################
      # Local detail validators #
      ###########################

      def self.bank_code_exists_for_clearing_code?(clearing_code)
        !Sweden::BankLookup.for_clearing_code(clearing_code).nil?
      end

      def self.valid_clearing_code_length?(clearing_code)
        return unless bank_code_exists_for_clearing_code?(clearing_code)

        bank_info = Sweden::BankLookup.for_clearing_code(clearing_code)
        bank_info.fetch(:clearing_code_length) == clearing_code.to_s.length
      end

      def self.valid_serial_number_length?(clearing_code: nil,
                                           serial_number: nil)
        return false unless serial_number
        return unless bank_code_exists_for_clearing_code?(clearing_code)

        bank_info = Sweden::BankLookup.for_clearing_code(clearing_code)
        serial_number_length = bank_info.fetch(:serial_number_length)

        if bank_info.fetch(:zerofill_serial_number)
          serial_number = serial_number.rjust(serial_number_length, "0")
        end

        serial_number_length == serial_number.to_s.length
      end

      ###########################
      # SWIFT detail validators #
      ###########################

      def self.bank_code_exists?(bank_code)
        Sweden::BankLookup.for_bank_code(bank_code).any?
      end

      def self.bank_code_possible_for_account_number?(bank_code: nil,
                                                      account_number: nil)
        return unless bank_code_exists?(bank_code)

        clearing_code = account_number.gsub(/\A0+/, "").slice(0, 4).to_i
        Sweden::BankLookup.for_bank_code(bank_code).any? do |bank|
          !bank[:include_clearing_code] || bank[:range].include?(clearing_code)
        end
      end

      def self.account_number_length_valid_for_bank_code?(bank_code: nil,
                                                          account_number: nil)
        bank_code_possible = bank_code_possible_for_account_number?(
          bank_code: bank_code,
          account_number: account_number,
        )
        return unless bank_code_possible

        Sweden::BankLookup.for_bank_code(bank_code).any? do |bank|
          length = bank.fetch(:serial_number_length)
          length += bank[:clearing_code_length] if bank[:include_clearing_code]

          cleaned_account_number = account_number.gsub(/\A0+/, "")
          if bank[:zerofill_serial_number] && !bank[:include_clearing_code]
            cleaned_account_number =
              cleaned_account_number.
                rjust(bank.fetch(:serial_number_length), "0")
          end

          cleaned_account_number.length == length
        end
      end
    end
  end
end
