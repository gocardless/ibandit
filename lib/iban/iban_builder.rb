module IBAN
  module IBANBuilder
    SUPPORTED_COUNTRY_CODES = %w(ES IT FR PT)

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
        msg = "#{arg} is a required field when building an IT IBAN"
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

    # Note: the French "rib_key" check digit is a public attribute. It's
    # probably wiser to ask the customer for it than to calculate it (or it
    # obviously can't serve its purpose of checking for typos in the other
    # fields they've entered).
    def self.build_fr_iban(opts)
      %i(bank_code branch_code account_number).each do |arg|
        msg = "#{arg} is a required field when building an FR IBAN"
        raise ArgumentError.new(msg) unless opts[arg]
      end

      rib_key = opts[:rib_key] || rib_check_digits(opts[:bank_code],
                                                   opts[:branch_code],
                                                   opts[:account_number])
      bban = [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number],
        rib_key
      ].join

      IBAN.new("FR#{iban_check_digits("FR", bban)}#{bban}")
    end

    def self.build_pt_iban(opts)
      %i(bank_code branch_code account_number).each do |arg|
        msg = "#{arg} is a required field when building an PT IBAN"
        raise ArgumentError.new(msg) unless opts[arg]
      end

      check_digits = mod_97_10_check_digits(opts[:bank_code] +
                                            opts[:branch_code] +
                                            opts[:account_number])

      bban = [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number],
        check_digits
      ].join

      IBAN.new("PT#{iban_check_digits("PT", bban)}#{bban}")
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

    def self.mod_97_10_check_digits(string)
      chars = string + "00"
      digits = chars.bytes.map do |byte|
        case byte
        when 48..57 then byte.chr           # 0..9
        when 65..90 then (byte - 55).to_s   # A..Z
        else raise "Unexpected byte '#{byte}'"
        end
      end
      remainder = digits.join.to_i % 97
      format('%02d', 98 - remainder)
    end

    def self.italian_check_digit(string)
      odd_mapping = {
        "A" => 1,  "B" => 0,  "C" => 5,  "D" => 7,  "E" => 9,  "F" => 13,
        "G" => 15, "H" => 17, "I" => 19, "J" => 21, "K" => 2,  "L" => 4,
        "M" => 18, "N" => 20, "O" => 11, "P" => 3,  "Q" => 6,  "R" => 8,
        "S" => 12, "T" => 14, "U" => 16, "V" => 10, "W" => 22, "X" => 25,
        "Y" => 24, "Z" => 23, "0" => 1,  "1" => 0,  "2" => 5,  "3" => 7,
        "4" => 9,  "5" => 13, "6" => 15, "7" => 17, "8" => 19, "9" => 21
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

    def self.rib_check_digits(bank_code, branch_code, account_number)
      remainder = 97 - (89 * rib_value(bank_code) +
                        15 * rib_value(branch_code) +
                        3 * rib_value(account_number)) % 97
      format('%02d', remainder)
    end

    def self.iban_check_digits(country_code, bban)
      mod_97_10_check_digits(bban + country_code)
    end

    def self.rib_value(string)
      rib_mapping = {
        "A" => 1, "B" => 2, "C" => 3, "D" => 4, "E" => 5, "F" => 6, "G" => 7,
        "H" => 8, "I" => 9, "J" => 1, "K" => 2, "L" => 3, "M" => 4, "N" => 5,
        "O" => 6, "P" => 7, "Q" => 8, "R" => 9, "S" => 2, "T" => 3, "U" => 4,
        "V" => 5, "W" => 6, "X" => 7, "Y" => 8, "Z" => 9, "0" => 0, "1" => 1,
        "2" => 2, "3" => 3, "4" => 4, "5" => 5, "6" => 6, "7" => 7, "8" => 8,
        "9" => 9
      }

      string.chars.map do |char|
        raise "Unexpected byte '#{character}' in RIB" unless rib_mapping[char]
        rib_mapping[char]
      end.join.to_i
    end
  end
end
