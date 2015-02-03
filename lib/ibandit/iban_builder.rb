module Ibandit
  module IBANBuilder
    SUPPORTED_COUNTRY_CODES = %w(AT BE CY DE EE ES FI FR GB IE IT LT LU LV MC NL
                                 PT SI SK SM).freeze

    def self.build(opts)
      country_code = opts[:country_code]

      if country_code.nil?
        return opts
      elsif !SUPPORTED_COUNTRY_CODES.include?(country_code)
        return opts
      else
        return opts unless fields_for?(country_code, opts)
        bban_info = send(:"build_#{country_code.downcase}_bban_info", opts)
        build_iban_parts(country_code, bban_info)
      end
    end

    ##################################
    # Country-specific BBAN creation #
    ##################################

    def self.build_at_bban_info(opts)
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
      bank_code      = opts[:bank_code]
      account_number = opts[:account_number].rjust(11, '0')

      {
        bban:           bank_code + account_number,
        bank_code:      bank_code,
        account_number: account_number
      }
    end

    def self.build_be_bban_info(opts)
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
      account_number = opts[:account_number].tr('-', '')

      {
        bban:           account_number,
        account_number: account_number
      }
    end

    def self.build_cy_bban_info(opts)
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
      #   Some Cypriot banks may be using check digits in their account numbers,
      #   but there's no central source of them.
      #
      # Padding:
      #   Add leading zeros to account number if < 16 digits.
      #
      # Additional info:
      #   Cypriot bank and branch codes are often communicated as a single code,
      #   so this method handles being passed them together or separately.
      cleaned_bank_code = opts[:bank_code].gsub(/[-\s]/, '')

      bank_code      = cleaned_bank_code.slice(0, 3)
      branch_code    =
        if opts.include?(:branch_code)
          opts[:branch_code]
        elsif cleaned_bank_code.length > 3
          cleaned_bank_code[3..-1]
        end
      account_number = opts[:account_number].rjust(16, '0')

      {
        bban:           [bank_code, branch_code, account_number].compact.join,
        bank_code:      bank_code,
        branch_code:    branch_code,
        account_number: account_number
      }
    end

    def self.build_de_bban_info(opts)
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
      #   Bundesbank, and handled by the GermanDetailsConverter class.
      converted_details = GermanDetailsConverter.convert(opts)

      bank_code      = converted_details[:bank_code]
      account_number = converted_details[:account_number].rjust(10, '0')

      {
        bban:           bank_code + account_number,
        bank_code:      bank_code,
        account_number: account_number
      }
    end

    def self.build_ee_bban_info(opts)
      # Local account details format:
      #   bbaaaaaaaaaaax
      #   Account number may be up to 14 characters long
      #   Bank code can be found by extracted from the first two digits of the
      #   account number and converted using the rules at
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
      #   Add leading zeros to account number if < 14 digits.
      #
      # Additional info:
      #   Estonian national bank details were replaced with IBANs in Feb 2014.
      #   All Estonian payers should therefore know their IBAN.
      domestic_bank_code = opts[:account_number].gsub(/\A0+/, '').slice(0, 2)

      iban_bank_code =
        case domestic_bank_code
        when '11' then '22'
        when '93' then '00'
        else domestic_bank_code
        end

      account_number = opts[:account_number].rjust(14, '0')

      {
        bban:           iban_bank_code + account_number,
        bank_code:      iban_bank_code,
        account_number: account_number
      }
    end

    def self.build_es_bban_info(opts)
      # Local account details format:
      #   bbbb-ssss-xx-aaaaaaaaaa
      #   Usually not separated, except by spaces or dashes
      #
      # Local account details name(s):
      #   Full details (20 digits): Código Cuenta Cliente
      #   Bank code (first 4 digits): Código de entidad
      #   Branch code (next 4 digits): Código de oficina
      #   Check digits (next 2 ditigs): Dígitos de control
      #   Account number (final 10 digits): Número de cuenta
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   The 2 check digits described above are part of the "account number" as
      #   defined by SWIFT. See CheckDigit#spanish for their generation.
      #
      # Padding: None
      #
      # Additional info:
      #   This method supports being passed the component IBAN parts, as defined
      #   by SWIFT, or a single 20 digit string.
      if opts.include?(:bank_code) && opts.include?(:branch_code)
        bank_code   = opts[:bank_code]
        branch_code = opts[:branch_code]
        account_number = opts[:account_number]
      else
        cleaned_account_number = opts[:account_number].tr('-', '')

        bank_code      = cleaned_account_number.slice(0, 4)
        branch_code    = cleaned_account_number.slice(4, 4)
        account_number = cleaned_account_number[8..-1]
      end

      {
        bban:           bank_code + branch_code + account_number,
        bank_code:      bank_code,
        branch_code:    branch_code,
        account_number: account_number
      }
    end

    def self.build_fi_bban_info(opts)
      # Local account details format:
      #   bbbbbb-aaaaaaax
      #   Usually two joined fields separated by a hyphen
      #
      # Local account details name(s):
      #   Full details: 'Tilinumeron rakenne'
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   The last digit of the account number is a check digit. The check digit
      #   algorithm is available in CheckDigit#lund.
      #
      # Padding:
      #   Finnish account numbers need to be expanded into "electronic format"
      #   by adding zero-padding. The expansion method depends on the first
      #   character of the bank code.
      account_number =
        if %w(4 5 6).include?(opts[:bank_code][0])
          [
            opts[:account_number][0],
            opts[:account_number][1..-1].rjust(7, '0')
          ].join
        else
          opts[:account_number].rjust(8, '0')
        end

      {
        bban:           opts[:bank_code] + account_number,
        bank_code:      opts[:bank_code],
        account_number: account_number
      }
    end

    def self.build_fr_bban_info(opts)
      # Local account details format:
      #   bbbbb-sssss-aaaaaaaaaaa-xx
      #   4 separated fields
      #
      # Local account details name(s):
      #   Bank code (5 digits): 'Code banque'
      #   Branch code (5 digits): 'Code guichet'
      #   Account number (max 11 digits): 'Numéro de compte'
      #   Check digits (2 digits): 'Clé RIB'
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   French BBANs include two "RIB key" check digits. In the SWIFT IBAN
      #   structure definition these check digits are part of the account
      #   number, although customers expect to see them as a separate field.
      #   You should concatenate the account number with the entered check
      #   digits when using this method.
      #
      # Padding: None
      {
        bban: opts[:bank_code] + opts[:branch_code] + opts[:account_number],
        bank_code: opts[:bank_code],
        branch_code: opts[:branch_code],
        account_number: opts[:account_number]
      }
    end

    def self.build_gb_bban_info(opts)
      # Local account details format:
      #   ssssss aaaaaaaa
      #   2 separated fields
      #
      # Local account details name(s):
      #   Branch code: Sort code
      #   Account number: Account number
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   Local bank validation is carried out on a bank-by-bank basis, and out
      #   of scope for this gem.
      #
      # Padding:
      #   Add leading zeros to account number if < 8 digits.
      #
      # Additional info:
      #   UK BBANs include the first four characters of the BIC. This requires a
      #   BIC finder lambda to be defined, or the bank_code to be supplied.
      branch_code = opts[:branch_code].gsub(/[-\s]/, '')

      if opts[:bank_code]
        bank_code = opts[:bank_code]
      else
        bic = Ibandit.find_bic('GB', branch_code)
        bank_code = bic.nil? ? nil : bic.slice(0, 4)
      end

      account_number = opts[:account_number].gsub(/[-\s]/, '').rjust(8, '0')

      {
        bban:           [bank_code, branch_code, account_number].join,
        bank_code:      bank_code,
        branch_code:    branch_code,
        account_number: account_number
      }
    end

    def self.build_lt_bban_info(opts)
      # Additional info:
      #   Lithuanian national bank details were replaced with IBANs in 2004.
      #   All Lithuanian payers should therefore know their IBAN, and are
      #   unlikely to know how it breaks down. This method is included for
      #   consistency with the IBAN structure only.
      opts.merge(bban: opts[:bank_code] + opts[:account_number])
    end

    def self.build_lu_bban_info(opts)
      # Additional info:
      #   Luxembourgian national bank details were replaced with IBANs in 2002.
      #   All Luxembourgian payers should therefore know their IBAN, and are
      #   unlikely to know how it breaks down. This method is included for
      #   consistency with the IBAN structure only.
      opts.merge(bban: opts[:bank_code] + opts[:account_number])
    end

    def self.build_lv_bban_info(opts)
      # Additional info:
      #   Latvian national bank details were replaced with IBANs in 2004.
      #   All Latvian payers should therefore know their IBAN, and are
      #   unlikely to know how it breaks down. This method is included for
      #   consistency with the IBAN structure only.
      opts.merge(bban: opts[:bank_code] + opts[:account_number])
    end

    def self.build_ie_bban_info(opts)
      # Ireland uses the same BBAN construction method as the United Kingdom
      branch_code = opts[:branch_code].gsub(/[-\s]/, '')

      if opts[:bank_code]
        bank_code = opts[:bank_code]
      else
        bic = Ibandit.find_bic('IE', branch_code)
        bank_code = bic.nil? ? nil : bic.slice(0, 4)
      end

      account_number = opts[:account_number].gsub(/[-\s]/, '').rjust(8, '0')

      {
        bban:           [bank_code, branch_code, account_number].join,
        bank_code:      bank_code,
        branch_code:    branch_code,
        account_number: account_number
      }
    end

    def self.build_it_bban_info(opts)
      # Local account details format:
      #   x/bbbbb/sssss/cccccccccccc
      #   4 fields, separated by slashes
      #   The check digit is NOT included in the any of the other SWIFT
      #   elements, so should be passed explicitly or left blank for it to be
      #   calculated implicitly
      #
      # Local bank details name(s):
      #   Check digit: 'CIN'
      #   Bank code: 'Codice ABI'
      #   Branch code: 'CAB'
      #   Account number: 'Numero di conto'
      #
      # BBAN-specific check digits:
      #   Italian BBANs include a single BBAN-specific check digit, calculated
      #   using a bespoke algorithm. See CheckDigit#italian.
      #
      # Padding:
      #   Add leading zeros to account number if < 10 digits.
      bank_code      = opts[:bank_code]
      branch_code    = opts[:branch_code]
      account_number = opts[:account_number].rjust(12, '0')

      partial_bban = bank_code + branch_code + account_number

      check_digit = opts[:check_digit] || CheckDigit.italian(partial_bban)

      {
        bban:           check_digit + partial_bban,
        bank_code:      bank_code,
        branch_code:    branch_code,
        account_number: account_number
      }
    end

    def self.build_mc_bban_info(opts)
      # Monaco uses the same BBAN construction method as France
      build_fr_bban_info(opts)
    end

    def self.build_nl_bban_info(opts)
      # Local account details format:
      #   aaaaaaaaaa
      #   1 field for account number only
      #   In theory the bank code can be looked up from the account number, but
      #   we don't currently have a way of doing so.
      #
      # Local bank details name(s):
      #   Account number: 'Rekeningnummer'
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   A modulus 11 check can be applied to Dutch IBANs. See CheckDigit#dutch
      #   for an implementation.
      #
      # Padding:
      #   Add leading zeros to account number if < 10 digits.
      account_number = opts[:account_number].rjust(10, '0')

      {
        bban:           opts[:bank_code] + account_number,
        bank_code:      opts[:bank_code],
        account_number: account_number
      }
    end

    def self.build_pt_bban_info(opts)
      # Local account details format:
      #   bbbb.ssss.ccccccccccc.xx
      #   Usually presented in one block
      #
      # Local account details name(s):
      #   Full details: Número de Identificaçao Bancária (NIB)
      #   Bank code: Código de Banco
      #   Branch code: Código de Balcao
      #   Account number: Número de conta
      #   Local check digits: Dígitos de controlo
      #
      # BBAN-specific check digits:
      #   Technically none, but see below
      #
      # Other check digits:
      #   The last two digits of Portuguese account numbers, as defined by
      #   SWIFT, are check digits, calculated using the same algorithm as the
      #   overall IBAN check digits (i.e., mod_97_10). However, customers expect
      #   to see these check digits as a separate field. You should concatenate
      #   the account number with the entered check digits when using this
      #   method.
      #
      # Additional info:
      #   A side-effect of Portugal using the same algorithm for its local check
      #   digits as the overall IBAN check digits is that the overall digits are
      #   always 50.
      opts.merge(bban: [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number]
      ].join)
    end

    def self.build_si_bban_info(opts)
      # Local account details format:
      #   bbbbb-aaaaaaaaxx
      #   Two fields, separated by a dash
      #
      # Local account details name(s):
      #   Full details: Transakcijski račun
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   The last two digits of Slovenian account numbers, as defined by
      #   SWIFT, are check digits, calculated using the same algorithm as the
      #   overall IBAN check digits (i.e., mod_97_10).
      #
      # Additional info:
      #   A side-effect of Slovenia using the same algorithm for its local check
      #   digits as the overall IBAN check digits is that the overall digits are
      #   always 56.
      account_number = opts[:account_number].rjust(10, '0')

      {
        bban:           opts[:bank_code] + account_number,
        bank_code:      opts[:bank_code],
        account_number: account_number
      }
    end

    def self.build_sk_bban_info(opts)
      # Local account details format:
      #   pppppp-aaaaaaaaaa/bbbb
      #   Three fields (or two, if prefix and account number are merged)
      #
      # Local account details name(s):
      #   Account number prefix: Předčíslí
      #   Account number: číslo účtu
      #   Bank code: 'Kód banky'
      #
      # BBAN-specific check digits: none
      #
      # Other check digits:
      #   The last digits of the account_number_prefix and the account_number
      #   are check digits. See CheckDigit#slovakian_prefix and
      #   CheckDigit#slovakian_basic
      #
      # Additional info:
      #   The SWIFT definition of a Slovakian IBAN includes both the account
      #   number prefix and the account number. This method therefore supports
      #   passing those fields concatenated.
      account_number =
        if opts.include?(:account_number_prefix)
          [
            opts[:account_number_prefix].rjust(6, '0'),
            opts[:account_number].rjust(10, '0')
          ].join
        else
          opts[:account_number].tr('-', '').rjust(16, '0')
        end

      {
        bban:           opts[:bank_code] + account_number,
        bank_code:      opts[:bank_code],
        account_number: account_number
      }
    end

    def self.build_sm_bban_info(opts)
      # San Marino uses the same BBAN construction method as Italy
      build_it_bban_info(opts)
    end

    ##################
    # Helper methods #
    ##################

    def self.fields_for?(country_code, opts)
      required_fields(country_code).all? { |argument| opts[argument] }
    end

    def self.required_fields(country_code)
      case country_code
      when 'AT', 'CY', 'DE', 'FI', 'LT', 'LU', 'LV', 'NL', 'SI', 'SK'
        %i(bank_code account_number)
      when 'BE', 'EE', 'ES'
        %i(account_number)
      when 'GB', 'IE'
        if Ibandit.bic_finder.nil? then %i(bank_code branch_code account_number)
        else %i(branch_code account_number)
        end
      else
        %i(bank_code branch_code account_number)
      end
    end

    def self.build_iban_parts(country_code, bban_info)
      check_digits = CheckDigit.iban(country_code, bban_info[:bban])

      {
        iban:           country_code + check_digits + bban_info[:bban],
        country_code:   country_code,
        check_digits:   check_digits,
        bank_code:      bban_info[:bank_code],
        branch_code:    bban_info[:branch_code],
        account_number: bban_info[:account_number]
      }
    end
  end
end
