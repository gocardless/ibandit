module Ibandit
  module SwedishDetailsConverter
    def self.convert(account_number)
      cleaned_account_number =
        account_number.gsub(/[-.\s]/, '').gsub(/\A0+/, '')

      bank_info = bank_info_for(cleaned_account_number.slice(0, 4))

      if bank_info.nil?
        return { bank_code: nil,
                 account_number: cleaned_account_number.rjust(17, '0') }
      end

      clearing_code_length = bank_info.fetch(:clearing_code_length)
      serial_number_length = bank_info.fetch(:serial_number_length)

      clearing_code = cleaned_account_number.slice(0, clearing_code_length)
      serial_number = cleaned_account_number[clearing_code_length..-1]

      if bank_info.fetch(:zerofill_serial_number)
        serial_number = serial_number.rjust(serial_number_length, '0')
      end

      iban_account_number =
        if bank_info.fetch(:include_clearing_code)
          (clearing_code + serial_number).rjust(17, '0')
        else
          serial_number.rjust(17, '0')
        end

      {
        bank_code: bank_info.fetch(:bank_code).to_s,
        account_number: iban_account_number
      }
    end

    def self.valid_bank_code?(bank_code: nil, account_number: nil)
      possible_bank_infos = possible_bank_info_for(
        bank_code: bank_code, account_number: account_number
      )

      possible_bank_infos.any?
    end

    def self.valid_length?(bank_code: nil, account_number: nil)
      return unless valid_bank_code?(
        bank_code: bank_code, account_number: account_number
      )

      cleaned_account_number = account_number.gsub(/\A0+/, '')

      possible_bank_infos = possible_bank_info_for(
        bank_code: bank_code, account_number: account_number
      )

      possible_bank_infos.any? do |bank|
        length = bank.fetch(:serial_number_length)
        length += bank[:clearing_code_length] if bank[:include_clearing_code]

        if bank[:zerofill_serial_number] && !bank[:include_clearing_code]
          serial_number_length = bank.fetch(:serial_number_length)
          cleaned_account_number =
            cleaned_account_number.rjust(serial_number_length, '0')
        end

        cleaned_account_number.length == length
      end
    end

    private

    def self.bank_info_for(clearing_code)
      bank_info_table.find { |bank| bank[:range].include?(clearing_code.to_i) }
    end
    private_class_method :bank_info_for

    def self.possible_bank_info_for(bank_code: nil, account_number: nil)
      clearing_number = account_number.gsub(/\A0+/, '').slice(0, 4).to_i

      possible_bank_infos = bank_info_table.select do |bank|
        bank.fetch(:bank_code).to_s == bank_code
      end

      possible_bank_infos.select do |bank|
        !bank[:include_clearing_code] || bank[:range].include?(clearing_number)
      end
    end
    private_class_method :possible_bank_info_for

    def self.bank_info_table
      @swedish_bank_lookup ||=
        begin
          relative_path = '../../../data/raw/swedish_bank_lookup.yml'
          raw_info = YAML.load_file(File.expand_path(relative_path, __FILE__))

          raw_info.map { |bank| bank.merge(range: Range.new(*bank[:range])) }
        end
    end
    private_class_method :bank_info_table
  end
end
