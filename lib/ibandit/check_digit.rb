# frozen_string_literal: true

module Ibandit
  module CheckDigit
    ITALIAN_ODD_MAPPING = {
      "A" => 1,  "B" => 0,  "C" => 5,  "D" => 7,  "E" => 9,  "F" => 13,
      "G" => 15, "H" => 17, "I" => 19, "J" => 21, "K" => 2,  "L" => 4,
      "M" => 18, "N" => 20, "O" => 11, "P" => 3,  "Q" => 6,  "R" => 8,
      "S" => 12, "T" => 14, "U" => 16, "V" => 10, "W" => 22, "X" => 25,
      "Y" => 24, "Z" => 23, "0" => 1,  "1" => 0,  "2" => 5,  "3" => 7,
      "4" => 9,  "5" => 13, "6" => 15, "7" => 17, "8" => 19, "9" => 21
    }.freeze

    def self.iban(country_code, bban)
      chars = bban + country_code + "00"
      digits = chars.bytes.map do |byte|
        case byte
        when 48..57 then byte.chr           # 0..9
        when 65..90 then (byte - 55).to_s   # A..Z
        else
          raise InvalidCharacterError,
                "Unexpected non-alphanumeric character '#{byte.chr}'"
        end
      end
      remainder = digits.join.to_i % 97
      sprintf("%<check_digit>02d", check_digit: 98 - remainder)
    end

    def self.italian(string)
      scaled_values = string.chars.map.with_index do |char, index|
        if index.even?
          if ITALIAN_ODD_MAPPING.include?(char)
            ITALIAN_ODD_MAPPING[char]
          else
            raise InvalidCharacterError,
                  "Unexpected character '#{char}'"
          end
        else
          case char.ord
          when 48..57 then char.to_i         # 0..9
          when 65..90 then char.ord - 65     # A..Z
          else
            raise InvalidCharacterError,
                  "Unexpected character '#{char}'"
          end
        end
      end

      ((scaled_values.sum % 26) + 65).chr
    end
  end
end
