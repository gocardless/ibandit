# frozen_string_literal: true

module Ibandit
  module Sweden
    class LocalDetailsConverter
      # Converts local Swedish details into SWIFT details.
      #
      # Local details can be provided as either:
      # - branch_code: clearing number, account_number: serial number
      # - branch_code: nil, account_number: #{clearing number}#{serial number}
      #
      # The reverse conversion (extracting local details from SWIFT details) is
      # not possible, since the clearing number cannot be derived. You should
      # NOT pass this class a SWIFT account number, as it will not convert it to
      # local details successfully.
      def initialize(branch_code: nil, account_number: nil)
        @branch_code = branch_code
        @account_number = account_number
      end

      def convert
        if bank_info.nil?
          return { swift_bank_code: nil,
                   swift_account_number: cleaned_account_number.rjust(17, "0") }
        end

        {
          account_number: serial_number,
          branch_code: clearing_code,
          swift_bank_code: bank_info.fetch(:bank_code).to_s,
          swift_account_number: swift_account_number,
        }
      end

      private

      def cleaned_account_number
        # Don't trim leading zeroes if the account number we are given is a
        # serial number (i.e. if the clearing code is separate).
        @cleaned_account_number ||= remove_bad_chars(@account_number)
      end

      def cleaned_branch_code
        @cleaned_branch_code ||= remove_bad_chars(@branch_code)
      end

      def remove_bad_chars(number)
        return if number.nil?

        number.gsub(/[-.\s]/, "")
      end

      def bank_info
        @bank_info ||= Sweden::BankLookup.for_clearing_code(bank_info_key)
      end

      def bank_info_key
        (cleaned_branch_code || cleaned_account_number).slice(0, 4)
      end

      def clearing_code_length
        bank_info.fetch(:clearing_code_length)
      end

      def serial_number_length
        bank_info.fetch(:serial_number_length)
      end

      def clearing_code
        cleaned_branch_code ||
          cleaned_account_number.slice(0, clearing_code_length)
      end

      def serial_number
        serial_number = if @branch_code.nil?
                          cleaned_account_number[clearing_code_length..-1]
                        else
                          cleaned_account_number
                        end

        return serial_number unless bank_info.fetch(:zerofill_serial_number)

        serial_number&.rjust(serial_number_length, "0")
      end

      def swift_account_number
        if bank_info.fetch(:include_clearing_code) &&
            clearing_code && serial_number
          (clearing_code + serial_number).rjust(17, "0")
        else
          serial_number&.rjust(17, "0")
        end
      end
    end
  end
end
