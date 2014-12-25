module Ibandit
  module CheckDigit
    def self.mod_97_10(string)
      chars = string + '00'
      digits = chars.bytes.map do |byte|
        case byte
        when 48..57 then byte.chr           # 0..9
        when 65..90 then (byte - 55).to_s   # A..Z
        else
          raise InvalidCharacterError,
                "Unexpected non-alphanumeric character '#{char}'"
        end
      end
      remainder = digits.join.to_i % 97
      format('%02d', 98 - remainder)
    end

    # Currently unused in this gem. This method calculates a mod 11
    # check digit from the string of digits passed in. These check
    # digits are used in the 1st and 2nd digits of local Spanish
    # account numbers.
    def self.spanish(string)
      scaled_values = string.chars.map.with_index do |digit, index|
        unless digit.to_i.to_s == digit
          raise InvalidCharacterError,
                "Unexpected non-numeric character '#{digit}'"
        end
        Integer(digit) * (2**index % 11)
      end
      result = 11 - scaled_values.inject(:+) % 11
      result < 10 ? result.to_s : (11 - result).to_s
    end

    def self.italian(string)
      odd_mapping = {
        'A' => 1,  'B' => 0,  'C' => 5,  'D' => 7,  'E' => 9,  'F' => 13,
        'G' => 15, 'H' => 17, 'I' => 19, 'J' => 21, 'K' => 2,  'L' => 4,
        'M' => 18, 'N' => 20, 'O' => 11, 'P' => 3,  'Q' => 6,  'R' => 8,
        'S' => 12, 'T' => 14, 'U' => 16, 'V' => 10, 'W' => 22, 'X' => 25,
        'Y' => 24, 'Z' => 23, '0' => 1,  '1' => 0,  '2' => 5,  '3' => 7,
        '4' => 9,  '5' => 13, '6' => 15, '7' => 17, '8' => 19, '9' => 21
      }

      scaled_values = string.chars.map.with_index do |char, index|
        if index.even?
          odd_mapping[char]
        else
          case char.ord
          when 48..57 then char.to_i         # 0..9
          when 65..90 then char.ord - 65     # A..Z
          else
            raise InvalidCharacterError,
                  "Unexpected non-alphanumeric character '#{char}'"
          end
        end
      end

      (scaled_values.inject(:+) % 26 + 65).chr
    end

    # Currently unused in this gem. This method calculates the last two digits
    # of a Belgian account number when given the first ten digits.
    def self.belgian(string)
      remainder = string.to_i % 97
      format('%02d', remainder)
    end

    # Currently unused in this gem. This method calculates the last digit
    # of a Estonian account number when given the initial digits.
    def self.estonian(string)
      weights = [7, 3, 1]

      scaled_values = string.reverse.chars.map.with_index do |char, index|
        unless char.to_i.to_s == char
          raise InvalidCharacterError,
                "Unexpected non-numeric character '#{char}'"
        end

        char.to_i * weights[index % weights.size]
      end

      (scaled_values.inject(:+) % 10).to_s
    end

    # Currently unused in this gem. This method calculates the last digit
    # of a Slovakian account number (basic) when given the initial digits.
    def self.slovakian_prefix(string)
      weights = [10, 5, 8, 4, 2]

      scaled_values = string.chars.map.with_index do |char, index|
        unless char.to_i.to_s == char
          raise InvalidCharacterError,
                "Unexpected non-numeric character '#{char}'"
        end

        char.to_i * weights[index]
      end

      (11 - scaled_values.inject(:+) % 11).to_s
    end

    # Currently unused in this gem. This method calculates the last digit
    # of a Slovakian account number prefix when given the initial digits.
    def self.slovakian_basic(string)
      weights = [6, 3, 7, 9, 10, 5, 8, 4, 2]

      scaled_values = string.chars.map.with_index do |char, index|
        unless char.to_i.to_s == char
          raise InvalidCharacterError,
                "Unexpected non-numeric character '#{char}'"
        end

        char.to_i * weights[index]
      end

      (11 - scaled_values.inject(:+) % 11).to_s
    end

    # Currently unused in this gem. This method calculates the last digit
    # of a Dutch account number when given the first nine digits.
    def self.dutch(string)
      scaled_values = string.reverse.chars.map.with_index do |char, index|
        unless char.to_i.to_s == char
          raise InvalidCharacterError,
                "Unexpected non-numeric character '#{char}'"
        end

        char.to_i * (index + 2)
      end

      result = 11 - scaled_values.inject(:+) % 11
      result < 10 ? result.to_s : (11 - result).to_s
    end

    # Currently unused in this gem. This method calculates the last digit
    # of a Finnish account number when given the initial digits (in electronic
    # format).
    def self.lund(string)
      weights = [2, 1]

      scaled_values = string.reverse.chars.map.with_index do |char, index|
        unless char.to_i.to_s == char
          raise InvalidCharacterError,
                "Unexpected non-numeric character '#{char}'"
        end

        scaled_value = char.to_i * weights[index % weights.size]
        scaled_value < 10 ? scaled_value : scaled_value % 10 + 1
      end

      (10 - scaled_values.inject(:+) % 10).to_s
    end

    def self.rib(bank_code, branch_code, account_number)
      remainder = 97 - (89 * rib_value(bank_code) +
                        15 * rib_value(branch_code) +
                        3 * rib_value(account_number)) % 97
      format('%02d', remainder)
    end

    def self.iban(country_code, bban)
      mod_97_10(bban + country_code)
    end

    def self.rib_value(string)
      rib_mapping = {
        'A' => 1, 'B' => 2, 'C' => 3, 'D' => 4, 'E' => 5, 'F' => 6, 'G' => 7,
        'H' => 8, 'I' => 9, 'J' => 1, 'K' => 2, 'L' => 3, 'M' => 4, 'N' => 5,
        'O' => 6, 'P' => 7, 'Q' => 8, 'R' => 9, 'S' => 2, 'T' => 3, 'U' => 4,
        'V' => 5, 'W' => 6, 'X' => 7, 'Y' => 8, 'Z' => 9, '0' => 0, '1' => 1,
        '2' => 2, '3' => 3, '4' => 4, '5' => 5, '6' => 6, '7' => 7, '8' => 8,
        '9' => 9
      }

      string.chars.map do |character|
        unless rib_mapping[character]
          raise InvalidCharacterError, "Unexpected byte '#{character}' in RIB"
        end
        rib_mapping[character]
      end.join.to_i
    end
  end
end
