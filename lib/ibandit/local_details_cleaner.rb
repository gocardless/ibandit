module Ibandit
  module LocalDetailsCleaner
    SUPPORTED_COUNTRY_CODES = %w(AT BE CY DE EE ES FI FR GB IE IT LT LU LV MC NL
                                 PT SI SK SM).freeze

    def self.clean(local_details)
      country_code = local_details[:country_code]

      return local_details unless can_clean?(country_code, local_details)

      local_details.merge(
        public_send(:"clean_#{country_code.downcase}_details", local_details))
    end

    ###########
    # Helpers #
    ###########

    def self.can_clean?(country_code, local_details)
      SUPPORTED_COUNTRY_CODES.include?(country_code) &&
        fields_for?(country_code, local_details)
    end

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

    ##########################
    # Country-specific logic #
    ##########################

    def self.clean_at_details(local_details)
      # Account number may be 4-11 digits long.
      # Add leading zeros to account number if < 11 digits.
      return {} unless local_details[:account_number].length >= 4
      {
        bank_code: local_details[:bank_code],
        account_number: local_details[:account_number].rjust(11, '0')
      }
    end

    def self.clean_be_details(local_details)
      { account_number: local_details[:account_number].tr('-', '') }
    end

    def self.clean_cy_details(local_details)
      # Account number may be 7-16 digits long.
      # Add leading zeros to account number if < 16 digits.
      cleaned_bank_code = local_details[:bank_code].gsub(/[-\s]/, '')

      bank_code      = cleaned_bank_code.slice(0, 3)
      branch_code    =
        if local_details[:branch_code]
          local_details[:branch_code]
        elsif cleaned_bank_code.length > 3
          cleaned_bank_code[3..-1]
        end
      account_number =
        if local_details[:account_number].length >= 7
          local_details[:account_number].rjust(16, '0')
        else
          local_details[:account_number]
        end

      {
        bank_code:      bank_code,
        branch_code:    branch_code,
        account_number: account_number
      }
    end

    def self.clean_de_details(local_details)
      # Account number may be up to 10 digits long.
      # Add leading zeros to account number if < 10 digits.
      #
      # There are many exceptions to the way German bank details translate
      # into an IBAN, detailed into a 200 page document compiled by the
      # Bundesbank, and handled by the GermanDetailsConverter class.
      converted_details = GermanDetailsConverter.convert(local_details)

      return {} unless converted_details[:account_number].length >= 4

      {
        bank_code:      converted_details[:bank_code],
        account_number: converted_details[:account_number].rjust(10, '0')
      }
    end

    def self.clean_ee_details(local_details)
      # Account number may be up to 14 characters long.
      # Add leading zeros to account number if < 14 digits.
      #
      # Bank code can be found by extracted from the first two digits of the
      # account number and converted using the rules at
      # http://www.pangaliit.ee/en/settlements-and-standards/bank-codes-of-estonian-banks
      domestic_bank_code =
        local_details[:account_number].gsub(/\A0+/, '').slice(0, 2)

      iban_bank_code =
        case domestic_bank_code
        when '11' then '22'
        when '93' then '00'
        else domestic_bank_code
        end

      account_number = local_details[:account_number].rjust(14, '0')

      { bank_code: iban_bank_code, account_number: account_number }
    end

    def self.clean_es_details(local_details)
      # This method supports being passed the component IBAN parts, as defined
      # by SWIFT, or a single 20 digit string.
      if local_details[:bank_code] && local_details[:branch_code]
        bank_code      = local_details[:bank_code]
        branch_code    = local_details[:branch_code]
        account_number = local_details[:account_number]
      else
        cleaned_account_number = local_details[:account_number].tr('-', '')

        bank_code      = cleaned_account_number.slice(0, 4)
        branch_code    = cleaned_account_number.slice(4, 4)
        account_number = cleaned_account_number[8..-1]
      end

      {
        bank_code:      bank_code,
        branch_code:    branch_code,
        account_number: account_number
      }
    end

    def self.clean_fi_details(local_details)
      #   Finnish account numbers need to be expanded into "electronic format"
      #   by adding zero-padding. The expansion method depends on the first
      #   character of the bank code.
      account_number =
        if %w(4 5 6).include?(local_details[:bank_code][0])
          [
            local_details[:account_number][0],
            local_details[:account_number][1..-1].rjust(7, '0')
          ].join
        else
          local_details[:account_number].rjust(8, '0')
        end

      {
        bank_code:      local_details[:bank_code],
        account_number: account_number
      }
    end

    def self.clean_fr_details(local_details)
      {
        bank_code:      local_details[:bank_code],
        branch_code:    local_details[:branch_code],
        account_number: local_details[:account_number].gsub(/[-\s]/, '')
      }
    end

    def self.clean_gb_details(local_details)
      # Account number may be 6-8 digits
      # Add leading zeros to account number if < 8 digits.
      branch_code = local_details[:branch_code].gsub(/[-\s]/, '')

      if local_details[:bank_code]
        bank_code = local_details[:bank_code]
      else
        bic = Ibandit.find_bic('GB', branch_code)
        bank_code = bic.nil? ? nil : bic.slice(0, 4)
      end

      account_number = local_details[:account_number].gsub(/[-\s]/, '')
      account_number = account_number.rjust(8, '0') if account_number.length > 5

      {
        bank_code:      bank_code,
        branch_code:    branch_code,
        account_number: account_number
      }
    end

    def self.clean_lt_details(local_details)
      # Lithuanian national bank details were replaced with IBANs in 2004.
      local_details
    end

    def self.clean_lu_details(local_details)
      # Luxembourgian national bank details were replaced with IBANs in 2002.
      local_details
    end

    def self.clean_lv_details(local_details)
      # Latvian national bank details were replaced with IBANs in 2004.
      local_details
    end

    def self.clean_ie_details(local_details)
      # Ireland uses the same local details as the United Kingdom
      branch_code = local_details[:branch_code].gsub(/[-\s]/, '')

      if local_details[:bank_code]
        bank_code = local_details[:bank_code]
      else
        bic = Ibandit.find_bic('IE', branch_code)
        bank_code = bic.nil? ? nil : bic.slice(0, 4)
      end

      account_number = local_details[:account_number].gsub(/[-\s]/, '')
      account_number = account_number.rjust(8, '0') if account_number.length > 5

      {
        bank_code:      bank_code,
        branch_code:    branch_code,
        account_number: account_number
      }
    end

    def self.clean_it_details(local_details)
      # Add leading zeros to account number if < 12 digits.
      {
        bank_code:      local_details[:bank_code],
        branch_code:    local_details[:branch_code],
        account_number: local_details[:account_number].rjust(12, '0')
      }
    end

    def self.clean_mc_details(local_details)
      # Monaco uses the same local details method as France
      clean_fr_details(local_details)
    end

    def self.clean_nl_details(local_details)
      # Add leading zeros to account number if < 10 digits.
      {
        bank_code:      local_details[:bank_code],
        account_number: local_details[:account_number].rjust(10, '0')
      }
    end

    def self.clean_pt_details(local_details)
      local_details
    end

    def self.clean_si_details(local_details)
      # Add leading zeros to account number if < 10 digits.
      {
        bank_code:      local_details[:bank_code],
        account_number: local_details[:account_number].rjust(10, '0')
      }
    end

    def self.clean_sk_details(local_details)
      #   The SWIFT definition of a Slovakian IBAN includes both the account
      #   number prefix and the account number. This method therefore supports
      #   passing those fields concatenated.
      account_number =
        if local_details.include?(:account_number_prefix)
          [
            local_details[:account_number_prefix].rjust(6, '0'),
            local_details[:account_number].rjust(10, '0')
          ].join
        else
          local_details[:account_number].tr('-', '').rjust(16, '0')
        end

      {
        bank_code:      local_details[:bank_code],
        account_number: account_number
      }
    end

    def self.clean_sm_details(local_details)
      # San Marino uses the same local details method as France
      clean_it_details(local_details)
    end
  end
end
