module Ibandit
  module Sweden
    class BankLookup
      def self.for_clearing_code(clearing_code)
        code = clearing_code.to_s.slice(0, 4).to_i
        bank_info_table.find { |bank| bank[:range].include?(code) }
      end

      def self.for_bank_code(bank_code)
        bank_info_table.select { |bank| bank[:bank_code] == bank_code.to_i }
      end

      def self.bank_info_table
        @swedish_bank_lookup ||=
          begin
            relative_path = "../../../../data/raw/swedish_bank_lookup.yml"
            raw_info = YAML.load_file(File.expand_path(relative_path, __FILE__))

            raw_info.map { |bank| bank.merge(range: Range.new(*bank[:range])) }
          end
      end
    end
  end
end
