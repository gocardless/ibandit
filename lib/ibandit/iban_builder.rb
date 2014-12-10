module Ibandit
  module IBANBuilder
    SUPPORTED_COUNTRY_CODES = %w(AT BE CY DE EE ES FI FR GB IE IT LU LV MC PT SI
                                 SK SM).freeze

    def self.build(opts)
      country_code = opts.delete(:country_code)

      if country_code.nil?
        raise ArgumentError, 'You must provide a country_code'
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
      # The first three digits of Belgian account numbers are the bank_code, but
      # the account number is not considered complete without these threee
      # numbers and the IBAN structure file includes them in its definition of
      # the account number. As a result, this method ignores all arguments other
      # than the account number.
      opts[:account_number].gsub('-', '')
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
      # Spanish account numbers include two check digits, these digits are
      # part of the bank details shown to customers (the first 2 digits
      # of the account number). A method for generating these check digits
      # can be found below: mod_11_check_digit
      #
      # As Spanish account numbers can be split into three groups of digits
      # or given as a single 20 digit string, we allow both options.
      if opts.include?(:bank_code) && opts.include?(:branch_code)
        [
          opts[:bank_code],
          opts[:branch_code],
          opts[:account_number]
        ].join
      else
        opts[:account_number]
      end
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
      return opts[:account_number] unless opts[:account_number].scan('-').any?

      account_number = opts[:account_number].gsub('-', '')
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
      rib_key = opts[:rib_key] || CheckDigit.rib(opts[:bank_code],
                                                 opts[:branch_code],
                                                 opts[:account_number])

      [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number],
        rib_key
      ].join
    end

    def self.build_gb_bban(opts)
      # UK BBANs include the first four characters of the BIC. This requires a
      # BIC finder lambda to be defined, or the bank_code to be supplied.
      bank_code = opts[:bank_code] || Ibandit.find_bic('GB', opts[:branch_code])

      unless bank_code
        raise ArgumentError,
              'bank_code is required if a BIC finder is not defined'
      end

      [
        bank_code.slice(0, 4),
        opts[:branch_code].gsub('-', ''),
        opts[:account_number].rjust(8, '0')
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
      # Irish BBANs include the first four characters of the BIC as the bank
      # code. This requires a BIC finder lambda to be defined, or the bank code
      # to be supplied.
      bank_code = opts[:bank_code] || Ibandit.find_bic('IE', opts[:branch_code])

      unless bank_code
        raise ArgumentError,
              'bank_code is required if a BIC finder is not defined'
      end

      [
        bank_code.slice(0, 4),
        opts[:branch_code].gsub('-', ''),
        opts[:account_number].rjust(8, '0')
      ].join
    end

    def self.build_it_bban(opts)
      # Italian BBANs include a single BBAN-specific check digit, calculated
      # using a bespoke algorithm.
      combined_code = [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number]
      ].join

      [CheckDigit.italian(combined_code), combined_code].join
    end

    def self.build_mc_bban(opts)
      # Monaco uses the same BBAN construction method as France
      build_fr_bban(opts)
    end

    def self.build_pt_bban(opts)
      # Portugues BBANs include two BBAN-specific check digits, calculated using
      # the same algorithm as the overall IBAN check digits. A side-effect is
      # that the overall IBAN check digits will therefor always be 50.
      check_digits = CheckDigit.mod_97_10(opts[:bank_code] +
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
      check_digits = CheckDigit.mod_97_10(
        opts[:bank_code] + opts[:account_number].rjust(8, '0'))

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

    def self.require_fields(country_code, opts)
      required_fields(country_code).each do |arg|
        next if opts[arg]

        msg = "#{arg} is a required field when building an #{country_code} IBAN"
        raise ArgumentError, msg
      end
    end

    def self.required_fields(country_code)
      case country_code
      when 'AT', 'CY', 'DE', 'LU', 'LV', 'SI'
        %i(bank_code account_number)
      when 'BE', 'EE', 'FI', 'ES'
        %i(account_number)
      when 'SK'
        %i(bank_code account_number_prefix account_number)
      when 'GB', 'IE'
        %i(branch_code account_number)
      else
        %i(bank_code branch_code account_number)
      end
    end

    def self.build_iban(country_code, bban)
      iban = [
        country_code,
        CheckDigit.iban(country_code, bban),
        bban
      ].join

      IBAN.new(iban)
    end
  end
end
