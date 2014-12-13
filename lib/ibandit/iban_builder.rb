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
      # Local account details format:
      #   aaaaaaaaaaa bbbbb
      #   Account number may be 4-11 digits long
      #
      # Local account details name(s):
      #   Bank code: 'Bankleitzahl' or 'BLZ'
      #   Account number: 'Kontonummer' or 'Kto.-Nr'
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   Austrian account numbers have built-in check digits. The checking
      #   rules are not public.
      #
      # Padding:
      #   Add leading zeros to account number if < 11 digits.
      [
        opts[:bank_code],
        opts[:account_number].rjust(11, '0')
      ].join
    end

    def self.build_be_bban(opts)
      # Local account details format: bbb-aaaaaaa-cc
      #
      # Local account details name(s):
      #   Single name for all fields: "Rekeningnummer / Numéro de compte"
      #   All fields are entered in one block, separated by hyphens for clarity
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   The last two digits of the account number are check digits, but these
      #   are considered integral to the account number itself. See
      #   CheckDigit#belgian for details of their calculation.
      #
      # Additional info:
      #   The first three digits of Belgian account numbers are the bank_code,
      #   but the account number is not considered complete without these three
      #   numbers and the IBAN structure file includes them in its definition of
      #   the account number. As a result, this method ignores all arguments
      #   other than the account number.
      opts[:account_number].gsub('-', '')
    end

    def self.build_cy_bban(opts)
      # Local account details format:
      #   bbb-sssss aaaaaaaaaaaaaaaa
      #   Account number may be 7-16 digits long
      #
      # Local account details name(s):
      #   Bank code: 'Kodikos Trapezas'
      #   Branch code: 'Kodikos Katastimatos'
      #   Account number: 'Arithmos Logariasmou'
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   Cypriot BBANs don't include any BBAN-specific check digits. (Some
      #   Cypriot banks may be using check digits in their account numbers, but
      #   there's no central source of them.)
      #
      # Padding:
      #   Add leading zeros to account number if < 16 digits.
      #
      # Additional info:
      #   Cypriot bank and branch codes are often communicated as a single code,
      #   so this method handles being passed them together or separatedly.
      combined_bank_code = opts[:bank_code]
      combined_bank_code += opts[:branch_code] || ''

      [
        combined_bank_code,
        opts[:account_number].rjust(16, '0')
      ].join
    end

    def self.build_de_bban(opts)
      # Local account details format:
      #   bbbbbbbb aaaaaaaaaa
      #   Account number may be 1-10 digits long
      #
      # Local account details name(s):
      #   Bank code: 'Bankleitzahl' or 'BLZ'
      #   Account number: 'Kontonummer' or 'Kto.-Nr'
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   Local bank validation is carried out by matching the bank code with
      #   the right algorithm key, then applying that bank-specific algorithm.
      #
      # Padding:
      #   Add leading zeros to account number if < 10 digits.
      #
      # Additional info:
      #   There are many exceptions to the way German bank details translate
      #   into an IBAN, detailed into a 200 page document compiled by the
      #   Bundesbank.
      [
        opts[:bank_code],
        opts[:account_number].rjust(10, '0')
      ].join
    end

    def self.build_ee_bban(opts)
      # Local account details format:
      #   bbaaaaaaaaaaax
      #   Account number may be up to 14 characters long
      #   Bank code is extracted from the first two digits of the account number
      #   and converted using the rules at
      #   http://www.pangaliit.ee/en/settlements-and-standards/bank-codes-of-estonian-banks
      #
      # Local account details name(s):
      #   Account number: 'Kontonumber'
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   The last digit of the account number is a check digit, but this is
      #   built-in. An implementation of the check digit algorithm is available
      #   in CheckDigit#estonian.
      #
      # Padding:
      #   Add leading zeros to account number if < 10 digits.
      #
      # Additional info:
      #   Estonian national bank details were replaced with IBANs in Feb 2014.
      #   All Estonian payers should therefore know their IBAN.
      domestic_bank_code = opts[:account_number].gsub(/\A0+/, '').slice(0, 2)

      case domestic_bank_code
      when '11' then iban_bank_code = '22'
      when '93' then iban_bank_code = '00'
      else iban_bank_code = domestic_bank_code
      end

      iban_bank_code + opts[:account_number].rjust(14, '0')
    end

    def self.build_es_bban(opts)
      # Local account details format:
      #   Account number (called Código Cuenta Cliente): 20 digits
      #     bbbb-ssss-xxcccccccccc (usually inputed together)
      #     First 4 digits: bank code ('Código de entidad')
      #     Next 4 digits: branch code ('Código de oficina')
      #     Next 2 digits: local check digits (part of the account nunber),
      #     called 'Dígitos de control'
      #     Final 10 digits: bank account number per se ('Número de cuenta')
      #
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
      # Local bank details format: bbbbbb-cccccccx ('Tilinumeron rakenne')
      #   Bank code [6 digits]
      #   Account number [1-7 digits plus 1 check digit in last position], with
      #   leading zeros
      #   These 2 numbers should be in 2 joined fields separated by a hyphen
      #
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
      # Local bank details format (4 separated fields)
      #   Bank code ('Code banque'): 5 digits
      #   Branch code ('Code guichet'): 5 digits
      #   Account number ('Numéro de compte'): max 11 digits
      #   RIB key ('Clé RIB'): 2 digits
      #
      # French BBANs include two "rib_key" check digits. These digits are part
      # of the bank details shown to customers and part of the account number
      # in the IBAN structure definition. Hence we expect the account_number
      # below to be 13 digits long = customer_acct_number + rib_key, even though
      # they should be displayed as 2 separate fields to a payer.
      [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number]
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
      # IBAN is the default since 2002 so there is no need to ask for local bank
      # details
      # These obsolete bank details were formatted as follows:
      #   Bank code: 3 digits
      #   Account number: 13 digits
      #
      # Luxembourgian BBANs don't include any BBAN-specific check digits.
      unless opts[:account_number].length == 13
        raise ArgumentError,
              'account_number should have 13 digits'
      end
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.build_lv_bban(opts)
      # Local bank details format:
      #   Account number: 13 digits
      #   Bank code: 4 digits [this is also the first 4 letters of the BIC]
      #   either the bank code needs to be supplied, or a bank dropdown
      #
      # Latvian BBANs don't include any BBAN-specific check digits.
      unless opts[:account_number].length == 13
        raise ArgumentError,
              'account_number should have 13 digits'
      end
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.build_ie_bban(opts)
      # Local bank details format:
      #   Account number: 8 digits
      #   Sort code: 6 digits
      #
      # Irish BBANs include the first four characters of the BIC as the bank
      # code. This requires a BIC finder lambda to be defined, or the bank code
      # to be supplied.
      bank_code = opts[:bank_code] || Ibandit.find_bic('IE', opts[:branch_code])

      unless bank_code
        raise ArgumentError,
              'bank_code is required if a BIC finder is not defined'
      end

      unless opts[:account_number].length == 8
        raise ArgumentError,
              'account_number should have 8 digits'
      end

      [
        bank_code.slice(0, 4),
        opts[:branch_code].gsub('-', ''),
        opts[:account_number]
      ].join
    end

    def self.build_it_bban(opts)
      # Local bank details format: x-bbbbb-sssss-cccccccccccc (4 fields)
      #   Check digit: 1 digit ('CIN')
      #   Bank code: 5 digits ('Codice ABI')
      #   Branch code: 5 digits ('CAB')
      #   Account number: 12 digits ('Numero di conto')
      #
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
      # Local bank details format: bbbbsssscccccccccccxx (in one block)
      #   Bank code: 4 digits
      #   Branch code: 4 digits
      #   Account number: 11 digits
      #   Local check digits: 2 digits
      #   All these are contained into one single field called NIB code
      #
      # Portuguese BBANs include two BBAN-specific check digits, calculated using
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
      # Local bank details format (forming 'Transakcijski račun' together)
      #   Bank code: 5 digits
      #     Usually 2 digits for bank code and 3 digits for branch code
      #     Or 5 digits as a block for a payment institution (starts with 91)
      #   Account number: 10 digits (incl. last 2 digits as check digits)
      #
      # Slovenian BBANs include two BBAN-specific check digits, calculated using
      # the same algorithm as the overall IBAN check digits. A side-effect is
      # that the overall IBAN check digits will therefore always be 56.
      check_digits = CheckDigit.mod_97_10(
        opts[:bank_code] + opts[:account_number].rjust(8, '0'))

      [
        opts[:bank_code],
        opts[:account_number].rjust(8, '0'),
        check_digits
      ].join
    end

    def self.build_sk_bban(opts)
      # Local bank details format:
      #   Bank account number: pppppp/cccccccccc (separated by slash)
      #     Account number prefix: 6 digits ('Předčíslí') - optional
      #     Account number: 2-10 digits ('číslo účtu')
      #   Bank code: 4 digits ('Kód banky')
      #
      # Slovakian BBANs don't include any BBAN-specific check digits. (There are
      # two check digits built in to the Slovakian account number, the
      # implementation for which are available in .slovakian_prefix_check_digit
      # and .slovakian_basic_check_digit for completeness)

      [
        opts[:bank_code],
        opts[:account_number_prefix].rjust(6, '0'),
        opts[:account_number].rjust(10, '0')
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
