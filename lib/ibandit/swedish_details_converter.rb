module Ibandit
  module SwedishDetailsConverter
    def self.convert(account_number)
      cleaned_account_number =
        account_number.gsub(/[-.\s]/, '').gsub(/\A0+/, '')

      bank_info = bank_info_for(cleaned_account_number.slice(0, 4))

      if bank_info.nil?
        return {
          bank_code: nil,
          account_number: cleaned_account_number.rjust(17, '0')
        }
      end

      clearing_code_length = bank_info.fetch(:clearing_code_length)

      clearing_code = cleaned_account_number.slice(0, clearing_code_length)
      local_account_number = cleaned_account_number[clearing_code_length..-1]

      iban_account_number =
        if bank_info.fetch(:type) == 1
          (clearing_code + local_account_number.rjust(7, '0')).rjust(17, '0')
        elsif bank_info[:zerofill]
          (clearing_code + local_account_number.rjust(10, '0')).rjust(17, '0')
        else
          local_account_number.rjust(17, '0')
        end

      {
        bank_code: bank_info.fetch(:bank_code).to_s,
        account_number: iban_account_number
      }
    end

    def self.bank_info_for(clearing_code)
      bank_info_table.find { |bank| bank[:range].include?(clearing_code.to_i) }
    end
    private_class_method :bank_info_for

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
