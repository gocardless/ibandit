module IBAN
  module IBANBuilder
    SUPPORTED_COUNTRY_CODES = ['ES', 'IT']

    def self.build(opts)
      country_code = opts.delete(:country_code)

      if country_code.nil?
        msg = "You must provide a country_code"
        raise ArgumentError.new(msg)
      elsif !SUPPORTED_COUNTRY_CODES.include?(country_code)
        msg = "Don't know how to build an IBAN for country code #{country_code}"
        raise ArgumentError.new(msg)
      else
        self.send(:"build_#{country_code.downcase}_iban", opts)
      end
    end

    def self.build_es_iban(opts)
      %i(bank_code branch_code account_number).each do |arg|
        msg = "#{arg} is a required field when building an ES IBAN"
        raise ArgumentError.new(msg) unless opts[arg]
      end

      bban = [
        opts[:bank_code],
        opts[:branch_code],
        mod_11_check_digit('00' + opts[:bank_code] + opts[:branch_code]),
        mod_11_check_digit(opts[:account_number]),
        opts[:account_number]
      ].join

      IBAN.new("ES#{iban_check_digits("ES", bban)}#{bban}")
    end

    def self.build_it_iban(opts)
      %i(bank_code branch_code account_number).each do |arg|
        msg = "#{arg} is a required field when building an ES IBAN"
        raise ArgumentError.new(msg) unless opts[arg]
      end

      combined_code = [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number]
      ].join
      bban = [italian_check_digit(combined_code), combined_code].join

      IBAN.new("IT#{iban_check_digits("IT", bban)}#{bban}")
    end

    ##########################
    # Check digit generation #
    ##########################

    def self.mod_11_check_digit(string)
      scaled_values = string.chars.map.with_index do |digit, index|
        digit.to_i * (2 ** index % 11)
      end
      result = 11 - scaled_values.inject(:+) % 11
      result < 10 ? result.to_s : (11 - result).to_s
    end

    def self.italian_check_digit(string)
      odd_mapping = {
        "A" => 1, "B" => 0, "C" => 5, "D" => 7, "E" => 9, "F" => 13, "G" => 15,
        "H" => 17, "I" => 19, "J" => 21, "K" => 2, "L" => 4, "M" => 18,
        "N" => 20, "O" => 11, "P" => 3, "Q" => 6, "R" => 8, "S" => 12,
        "T" => 14, "U" => 16, "V" => 10, "W" => 22, "X" => 25, "Y" => 24,
        "Z" => 23, "0" => 1, "1" => 0, "2" => 5, "3" => 7, "4" => 9, "5" => 13,
        "6" => 15, "7" => 17, "8" => 19, "9" => 21
      }

      scaled_values = string.chars.map.with_index do |character, index|
        if index.even?
          odd_mapping[character]
        else
          case character.ord
          when 48..57 then character.to_i         # 0..9
          when 65..90 then character.ord - 65     # A..Z
          else raise "Unexpected byte '#{character}' in IBAN code"
          end
        end
      end

      result = (scaled_values.inject(:+) % 26 + 65).chr
    end

    def self.iban_check_digits(country_code, bban)
      iban_chars = bban + country_code + "00"
      iban_digits = iban_chars.bytes.map do |byte|
        case byte
        when 48..57 then byte.chr           # 0..9
        when 65..90 then (byte - 55).to_s   # A..Z
        else raise "Unexpected byte '#{byte}' in IBAN code"
        end
      end
      remainder = iban_digits.join.to_i % 97
      format('%02d', 98 - remainder)
    end
  end
end
