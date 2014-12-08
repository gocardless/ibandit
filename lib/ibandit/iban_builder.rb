module Ibandit
  module IBANBuilder
    SUPPORTED_COUNTRY_CODES = %w(AT BE CY DE EE ES FI FR IE IT LU LV MC PT SI SK
                                 SM)

    def self.build(opts)
      country_code = opts.delete(:country_code)

      if country_code.nil?
        msg = 'You must provide a country_code'
        raise ArgumentError, msg
      elsif !SUPPORTED_COUNTRY_CODES.include?(country_code)
        msg = "Don't know how to build an IBAN for country code #{country_code}"
        raise ArgumentError, msg
      else
        require_fields(country_code, opts)
        bban = send(:"build_#{country_code.downcase}_bban", opts)
        build_iban(country_code, bban)
      end
    end

    ##################################
    # Country-specific BBAN creation #
    ##################################

    def self.build_at_bban(opts)
      # Austrian BBANs don't include any BBAN-specific check digits. (Austrian
      # account numbers have built-in check digits, the checking of which is out
      # of scope for this gem.)
      [opts[:bank_code], opts[:account_number].rjust(11, '0')].join
    end

    def self.build_be_bban(opts)
      # Belgian BBANs don't include any BBAN-specific check digits. (The last
      # two digits of the account number are check digits, but these are
      # built-in. An implementation of the check digit algorithm is available in
      # .belgian_check_digits for completeness.)
      #
      # Belgian account numbers can be split into a bank_code and account_number
      # but they're never shown separately. This method therefore handles being
      # passed either a single account_number argument or an account_number
      # and bank_code.
      (opts[:bank_code] || '') + opts[:account_number]
    end

    def self.build_cy_bban(opts)
      # Cypriot BBANs don't include any BBAN-specific check digits. (Some
      # Cypriot banks may be using check digits in their account numbers, but
      # there's no central source of them.)
      #
      # Cypriot bank and branch codes are often communicated as a single code,
      # so this method handles being passed them together or separatedly.
      combined_bank_code = opts[:bank_code]
      combined_bank_code += opts[:branch_code] || ''

      [combined_bank_code, opts[:account_number].rjust(16, '0')].join
    end

    def self.build_de_bban(opts)
      # German BBANs don't include any BBAN-specific check digits, and are just
      # the concatenation of the Bankleitzahl (bank number) and Kontonummer
      # (account number).
      opts[:bank_code] + opts[:account_number]
    end

    def self.build_ee_bban(opts)
      # Estonian BBANs don't include any BBAN-specific check digits. (The last
      # digit of the account number is a check digit, but this is built-in. An
      # implementation of the check digit algorithm is available in
      # .estonian_check_digit for completeness.)
      #
      # Estonian bank codes are looked up from the account number. See
      # http://www.pangaliit.ee/en/settlements-and-standards/bank-codes-of-estonian-banks
      domestic_bank_code = opts[:account_number].gsub(/\A0+/, '').slice(0, 2)

      case domestic_bank_code
      when '11' then iban_bank_code = '22'
      when '93' then iban_bank_code = '00'
      else iban_bank_code = domestic_bank_code
      end

      iban_bank_code + opts[:account_number].rjust(14, '0')
    end

    def self.build_es_bban(opts)
      # Spanish BBANs include two BBAN-specific check digits (i.e., not included
      # in domestic details). They are calculated using a Mod 11 check.
      [
        opts[:bank_code],
        opts[:branch_code],
        mod_11_check_digit('00' + opts[:bank_code] + opts[:branch_code]),
        mod_11_check_digit(opts[:account_number].rjust(10, '0')),
        opts[:account_number].rjust(10, '0')
      ].join
    end

    def self.build_fi_bban(opts)
      # Finnish BBANs don't include any BBAN-specific check digits. (The last
      # digit of the account number is a check digit, but this is built-in. An
      # implementation of the check digit algorithm is available in
      # .lund_check_digit for completeness.)
      #
      # Finnish account numbers need to be expanded into "electronic format"
      # if they have been written in "traditional format" (with a dash), and
      # the expansion method depends on the first character.
      return opts[:account_number] unless opts[:account_number].scan(/-/).any?

      account_number = opts[:account_number].gsub(/-/, '')
      length = account_number.size

      if %w(4 5 6).include?(account_number[0])
        account_number[0, 7] + '0' * (14 - length) + account_number[7..-1]
      else
        account_number[0, 6] + '0' * (14 - length) + account_number[6..-1]
      end
    end

    def self.build_fr_bban(opts)
      # French BBANs include two "rib_key" check digits. These digits are part
      # of the bank details shown to customers, so it's wise to ask the customer
      # to provide them if possible. If not, this gem will generate them.
      rib_key = opts[:rib_key] || rib_check_digits(opts[:bank_code],
                                                   opts[:branch_code],
                                                   opts[:account_number])

      [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number],
        rib_key
      ].join
    end

    def self.build_lu_bban(opts)
      # Luxembourgian BBANs don't include any BBAN-specific check digits.
      [opts[:bank_code], opts[:account_number].rjust(13, '0')].join
    end

    def self.build_lv_bban(opts)
      # Latvian BBANs don't include any BBAN-specific check digits.
      [opts[:bank_code], opts[:account_number].rjust(13, '0')].join
    end

    def self.build_ie_bban(opts)
      # Irish BBANs don't include any BBAN-specific check digits.
      [opts[:bank_code], opts[:branch_code], opts[:account_number]].join
    end

    def self.build_it_bban(opts)
      # Italian BBANs include a single BBAN-specific check digit, calculated
      # using a bespoke algorithm.
      combined_code = [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number]
      ].join

      [italian_check_digit(combined_code), combined_code].join
    end

    def self.build_mc_bban(opts)
      # Monaco uses the same BBAN construction method as France
      build_fr_bban(opts)
    end

    def self.build_pt_bban(opts)
      # Portugues BBANs include two BBAN-specific check digits, calculated using
      # the same algorithm as the overall IBAN check digits. A side-effect is
      # that the overall IBAN check digits will therefor always be 50.
      check_digits = mod_97_10_check_digits(opts[:bank_code] +
                                            opts[:branch_code] +
                                            opts[:account_number])

      [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number],
        check_digits
      ].join
    end

    def self.build_si_bban(opts)
      # Slovenian BBANs include two BBAN-specific check digits, calculated using
      # the same algorithm as the overall IBAN check digits. A side-effect is
      # that the overall IBAN check digits will therefor always be 56.
      check_digits = mod_97_10_check_digits(opts[:bank_code] +
                                            opts[:account_number].rjust(8, '0'))

      [
        opts[:bank_code],
        opts[:account_number].rjust(8, '0'),
        check_digits
      ].join
    end

    def self.build_sk_bban(opts)
      # Slovakian BBANs don't include any BBAN-specific check digits. (There are
      # two check digits built in to the Slovakian account number, the
      # implementation for which are available in .slovakian_prefix_check_digit
      # and .slovakian_basic_check_digit for completeness)

      [
        opts[:bank_code],
        opts[:account_number_prefix].rjust(6, '0'),
        opts[:account_number]
      ].join
    end

    def self.build_sm_bban(opts)
      # San Marino uses the same BBAN construction method as Italy
      build_it_bban(opts)
    end

    ##############################
    # Check digit helper methods #
    ##############################

    def self.mod_11_check_digit(string)
      scaled_values = string.chars.map.with_index do |digit, index|
        digit.to_i * (2**index % 11)
      end
      result = 11 - scaled_values.inject(:+) % 11
      result < 10 ? result.to_s : (11 - result).to_s
    end

    def self.mod_97_10_check_digits(string)
      chars = string + '00'
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
        'A' => 1,  'B' => 0,  'C' => 5,  'D' => 7,  'E' => 9,  'F' => 13,
        'G' => 15, 'H' => 17, 'I' => 19, 'J' => 21, 'K' => 2,  'L' => 4,
        'M' => 18, 'N' => 20, 'O' => 11, 'P' => 3,  'Q' => 6,  'R' => 8,
        'S' => 12, 'T' => 14, 'U' => 16, 'V' => 10, 'W' => 22, 'X' => 25,
        'Y' => 24, 'Z' => 23, '0' => 1,  '1' => 0,  '2' => 5,  '3' => 7,
        '4' => 9,  '5' => 13, '6' => 15, '7' => 17, '8' => 19, '9' => 21
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

      (scaled_values.inject(:+) % 26 + 65).chr
    end

    # Currently unused in this class. This method calculates the last two digits
    # of a Belgian account number when given the first ten digits.
    def self.belgian_check_digits(string)
      remainder = string.to_i % 97
      format('%02d', remainder)
    end

    # Currently unused in this class. This method calculates the last digit
    # of a Estonian account number when given the initial digits.
    def self.estonian_check_digit(string)
      weights = [7, 3, 1]

      scaled_values = string.reverse.chars.map.with_index do |char, index|
        unless char.to_i.to_s == char
          raise "Unexpected non-numeric character '#{char}'"
        end

        char.to_i * weights[index % weights.size]
      end

      (scaled_values.inject(:+) % 10).to_s
    end

    # Currently unused in this class. This method calculates the last digit
    # of a Slovakian account number (basic) when given the initial digits.
    def self.slovakian_prefix_check_digit(string)
      weights = [10, 5, 8, 4, 2]

      scaled_values = string.chars.map.with_index do |char, index|
        unless char.to_i.to_s == char
          raise "Unexpected non-numeric character '#{char}'"
        end

        char.to_i * weights[index]
      end

      (11 - scaled_values.inject(:+) % 11).to_s
    end

    # Currently unused in this class. This method calculates the last digit
    # of a Slovakian account number prefix when given the initial digits.
    def self.slovakian_basic_check_digit(string)
      weights = [6, 3, 7, 9, 10, 5, 8, 4, 2]

      scaled_values = string.chars.map.with_index do |char, index|
        unless char.to_i.to_s == char
          raise "Unexpected non-numeric character '#{char}'"
        end

        char.to_i * weights[index]
      end

      (11 - scaled_values.inject(:+) % 11).to_s
    end

    # Currently unused in this class. This method calculates the last digit
    # of a Finnish account number when given the initial digits (in electronic
    # format).
    def self.lund_check_digit(string)
      weights = [2, 1]

      scaled_values = string.reverse.chars.map.with_index do |char, index|
        unless char.to_i.to_s == char
          raise "Unexpected non-numeric character '#{char}'"
        end

        scaled_value = char.to_i * weights[index % weights.size]
        scaled_value < 10 ? scaled_value : scaled_value % 10 + 1
      end

      (10 - scaled_values.inject(:+) % 10).to_s
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
        'A' => 1, 'B' => 2, 'C' => 3, 'D' => 4, 'E' => 5, 'F' => 6, 'G' => 7,
        'H' => 8, 'I' => 9, 'J' => 1, 'K' => 2, 'L' => 3, 'M' => 4, 'N' => 5,
        'O' => 6, 'P' => 7, 'Q' => 8, 'R' => 9, 'S' => 2, 'T' => 3, 'U' => 4,
        'V' => 5, 'W' => 6, 'X' => 7, 'Y' => 8, 'Z' => 9, '0' => 0, '1' => 1,
        '2' => 2, '3' => 3, '4' => 4, '5' => 5, '6' => 6, '7' => 7, '8' => 8,
        '9' => 9
      }

      string.chars.map do |char|
        raise "Unexpected byte '#{character}' in RIB" unless rib_mapping[char]
        rib_mapping[char]
      end.join.to_i
    end

    def self.require_fields(country_code, opts)
      required_fields(country_code).each do |arg|
        next if opts[arg]

        msg = "#{arg} is a required field when building an #{country_code} IBAN"
        raise ArgumentError, msg
      end
    end

    def self.required_fields(country_code)
      {
        'AT' => %i(bank_code account_number),
        'BE' => %i(account_number),
        'CY' => %i(bank_code account_number),
        'EE' => %i(account_number),
        'FI' => %i(account_number),
        'LV' => %i(bank_code account_number),
        'LU' => %i(bank_code account_number),
        'SI' => %i(bank_code account_number),
        'SK' => %i(bank_code account_number_prefix account_number),
        'DE' => %i(bank_code account_number)
      }.fetch(country_code, %i(bank_code branch_code account_number))
    end

    def self.build_iban(country_code, bban)
      iban = [
        country_code,
        iban_check_digits(country_code, bban),
        bban
      ].join

      IBAN.new(iban)
    end
  end
end
