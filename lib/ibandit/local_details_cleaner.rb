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
      converted_details = GermanDetailsConverter.convert(local_details)

      return {} unless converted_details[:account_number].length >= 4

      {
        bank_code:      converted_details[:bank_code],
        account_number: converted_details[:account_number].rjust(10, '0')
      }
    end

    def self.clean_ee_details(local_details)
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
      local_details
    end

    def self.clean_lu_details(local_details)
      local_details
    end

    def self.clean_lv_details(local_details)
      local_details
    end

    def self.clean_ie_details(local_details)
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
      {
        bank_code:      local_details[:bank_code],
        branch_code:    local_details[:branch_code],
        account_number: local_details[:account_number].rjust(12, '0')
      }
    end

    def self.clean_mc_details(local_details)
      clean_fr_details(local_details)
    end

    def self.clean_nl_details(local_details)
      {
        bank_code:      local_details[:bank_code],
        account_number: local_details[:account_number].rjust(10, '0')
      }
    end

    def self.clean_pt_details(local_details)
      local_details
    end

    def self.clean_si_details(local_details)
      {
        bank_code:      local_details[:bank_code],
        account_number: local_details[:account_number].rjust(10, '0')
      }
    end

    def self.clean_sk_details(local_details)
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
      clean_it_details(local_details)
    end
  end
end
