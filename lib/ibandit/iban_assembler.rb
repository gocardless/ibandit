module Ibandit
  module IBANAssembler
    SUPPORTED_COUNTRY_CODES = %w(AT BE CY DE EE ES FI FR GB IE IT LT LU LV MC NL
                                 PT SI SK SM).freeze

    def self.assemble(local_details)
      country_code = local_details[:country_code]

      return unless can_assemble?(local_details)

      bban = public_send(:"assemble_#{country_code.downcase}_bban",
                         local_details)

      assemble_iban(country_code, bban)
    end

    def self.can_assemble?(local_details)
      SUPPORTED_COUNTRY_CODES.include?(local_details[:country_code]) &&
        required_fields?(local_details)
    end

    def self.required_fields?(local_details)
      required_fields(local_details[:country_code]).all? do |field|
        local_details[field]
      end
    end

    ##################################
    # Country-specific BBAN creation #
    ##################################

    def self.assemble_at_bban(opts)
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
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.assemble_be_bban(opts)
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
      opts[:account_number]
    end

    def self.assemble_cy_bban(opts)
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
      [opts[:bank_code], opts[:branch_code], opts[:account_number]].join
    end

    def self.assemble_de_bban(opts)
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
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.assemble_ee_bban(opts)
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
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.assemble_es_bban(opts)
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
      [opts[:bank_code], opts[:branch_code], opts[:account_number]].join
    end

    def self.assemble_fi_bban(opts)
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
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.assemble_fr_bban(opts)
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
      [opts[:bank_code], opts[:branch_code], opts[:account_number]].join
    end

    def self.assemble_gb_bban(opts)
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
      [opts[:bank_code], opts[:branch_code], opts[:account_number]].join
    end

    def self.assemble_lt_bban(opts)
      # Additional info:
      #   Lithuanian national bank details were replaced with IBANs in 2004.
      #   All Lithuanian payers should therefore know their IBAN, and are
      #   unlikely to know how it breaks down. This method is included for
      #   consistency with the IBAN structure only.
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.assemble_lu_bban(opts)
      # Additional info:
      #   Luxembourgian national bank details were replaced with IBANs in 2002.
      #   All Luxembourgian payers should therefore know their IBAN, and are
      #   unlikely to know how it breaks down. This method is included for
      #   consistency with the IBAN structure only.
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.assemble_lv_bban(opts)
      # Additional info:
      #   Latvian national bank details were replaced with IBANs in 2004.
      #   All Latvian payers should therefore know their IBAN, and are
      #   unlikely to know how it breaks down. This method is included for
      #   consistency with the IBAN structure only.
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.assemble_ie_bban(opts)
      # Ireland uses the same BBAN construction method as the United Kingdom
      [opts[:bank_code], opts[:branch_code], opts[:account_number]].join
    end

    def self.assemble_it_bban(opts)
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
      partial_bban = [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number]
      ].join

      check_digit = opts[:check_digit] || CheckDigit.italian(partial_bban)

      [check_digit, partial_bban].join
    end

    def self.assemble_mc_bban(opts)
      # Monaco uses the same BBAN construction method as France
      assemble_fr_bban(opts)
    end

    def self.assemble_nl_bban(opts)
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
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.assemble_pt_bban(opts)
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
      [opts[:bank_code], opts[:branch_code], opts[:account_number]].join
    end

    def self.assemble_si_bban(opts)
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
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.assemble_sk_bban(opts)
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
      [opts[:bank_code], opts[:account_number]].join
    end

    def self.assemble_sm_bban(opts)
      # San Marino uses the same BBAN construction method as Italy
      assemble_it_bban(opts)
    end

    ##################
    # Helper methods #
    ##################

    def self.required_fields(country_code)
      case country_code
      when 'AT', 'CY', 'DE', 'FI', 'LT', 'LU', 'LV', 'NL', 'SI', 'SK'
        %i(bank_code account_number)
      when 'BE', 'EE'
        %i(account_number)
      when 'GB', 'IE'
        if Ibandit.bic_finder.nil? then %i(bank_code branch_code account_number)
        else %i(branch_code account_number)
        end
      else
        %i(bank_code branch_code account_number)
      end
    end

    def self.assemble_iban(country_code, bban)
      [
        country_code,
        CheckDigit.iban(country_code, bban),
        bban
      ].join
    end
  end
end
