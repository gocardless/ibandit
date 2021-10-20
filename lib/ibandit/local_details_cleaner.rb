# frozen_string_literal: true

module Ibandit
  module LocalDetailsCleaner
    def self.clean(local_details)
      country_code = local_details[:country_code]
      if can_clean?(country_code, local_details)
        local_details = local_details.merge(
          public_send(:"clean_#{country_code.downcase}_details", local_details),
        )
      end

      return local_details if explicit_swift_details?(local_details)

      swift_details_for(local_details).merge(local_details)
    end

    ###########
    # Helpers #
    ###########

    def self.can_clean?(country_code, local_details)
      Constants::SUPPORTED_COUNTRY_CODES.include?(country_code) &&
        fields_for?(country_code, local_details)
    end

    def self.explicit_swift_details?(local_details)
      local_details.include?(:swift_account_number)
    end

    def self.fields_for?(country_code, opts)
      required_fields(country_code).all? { |argument| opts[argument] }
    end

    def self.required_fields(country_code)
      case country_code
      when "AT", "CY", "DE", "FI", "LT", "LU",
            "LV", "NL", "RO", "SI", "SK", "US"
        %i[bank_code account_number]
      when "BE", "CZ", "DK", "EE", "ES", "HR",
            "HU", "IS", "NO", "PL", "SE", "NZ"
        %i[account_number]
      when "GB", "IE", "MT"
        if Ibandit.bic_finder.nil? then %i[bank_code branch_code account_number]
        else
          %i[branch_code account_number]
        end
      when "AU"
        %i[branch_code account_number]
      else
        %i[bank_code branch_code account_number]
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
        account_number: local_details[:account_number].rjust(11, "0"),
      }
    end

    def self.clean_au_details(local_details)
      # Account number may be up to 10 digits long.
      #
      # Minimum account_number length is 5
      return {} unless local_details[:account_number].length >= 5

      {
        branch_code: local_details[:branch_code].delete("-"),
        account_number: local_details[:account_number],
      }
    end

    def self.clean_be_details(local_details)
      account_number = local_details[:account_number].tr("-", "")

      {
        bank_code: local_details[:bank_code] || account_number.slice(0, 3),
        account_number: account_number,
      }
    end

    def self.clean_ca_details(local_details)
      account_number = local_details[:account_number].tr("-", "")

      return {} unless (7..12).cover?(account_number.length)

      bank_code = if local_details[:bank_code].length == 3
                    local_details[:bank_code].rjust(4, "0")
                  else
                    local_details[:bank_code]
                  end

      {
        account_number: account_number,
        bank_code: bank_code,
      }
    end

    def self.clean_us_details(local_details)
      return {} unless local_details[:bank_code].length == 9

      account_number = local_details[:account_number].delete(" ")
      return {} unless (1..17).cover?(account_number.length)

      {
        bank_code: local_details[:bank_code],
        account_number: account_number,
      }
    end

    def self.clean_bg_details(local_details)
      # Bulgarian national bank details were replaced with IBANs in 2006.
      local_details
    end

    def self.clean_cy_details(local_details)
      # Account number may be 7-16 digits long.
      # Add leading zeros to account number if < 16 digits.
      cleaned_bank_code = local_details[:bank_code].gsub(/[-\s]/, "")

      bank_code      = cleaned_bank_code.slice(0, 3)
      branch_code    =
        if local_details[:branch_code]
          local_details[:branch_code]
        elsif cleaned_bank_code.length > 3
          cleaned_bank_code[3..-1]
        end
      account_number =
        if local_details[:account_number].length >= 7
          local_details[:account_number].rjust(16, "0")
        else
          local_details[:account_number]
        end

      {
        bank_code: bank_code,
        branch_code: branch_code,
        account_number: account_number,
      }
    end

    def self.clean_cz_details(local_details)
      #   The SWIFT definition of a Czech IBAN includes both the account
      #   number prefix and the account number. This method therefore supports
      #   passing those fields concatenated.
      account_number =
        if local_details.include?(:account_number_prefix)
          [
            local_details[:account_number_prefix].rjust(6, "0"),
            local_details[:account_number].rjust(10, "0"),
          ].join
        else
          local_details[:account_number].tr("-", "").rjust(16, "0")
        end

      {
        bank_code: local_details[:bank_code],
        account_number: account_number,
      }
    end

    def self.clean_de_details(local_details)
      # Account number may be up to 10 digits long.
      # Add leading zeros to account number if < 10 digits.
      #
      # There are many exceptions to the way German bank details translate
      # into an IBAN, detailed into a 200 page document compiled by the
      # Bundesbank, and handled by the GermanDetailsConverter class.
      converted_details =
        begin
          GermanDetailsConverter.convert(local_details)
        rescue UnsupportedAccountDetails
          local_details.dup
        end

      return {} unless converted_details[:account_number].length >= 4

      {
        bank_code: converted_details[:bank_code],
        account_number: converted_details[:account_number].rjust(10, "0"),
      }
    end

    def self.clean_dk_details(local_details)
      # This method supports being passed the component IBAN parts, as defined
      # by SWIFT, or a single traditional-format string split by a '-'.
      if local_details[:bank_code]
        bank_code      = local_details[:bank_code].rjust(4, "0")
        account_number = local_details[:account_number].rjust(10, "0")
      elsif local_details[:account_number].include?("-")
        bank_code, account_number = local_details[:account_number].split("-", 2)
      elsif local_details[:account_number].gsub(/\s/, "").length == 14
        cleaned_account_number = local_details[:account_number].gsub(/\s/, "")
        bank_code = cleaned_account_number.slice(0, 4)
        account_number = cleaned_account_number.slice(4, 10)
      else
        return {}
      end

      {
        bank_code: bank_code.rjust(4, "0"),
        account_number: account_number.delete("-").rjust(10, "0"),
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
        local_details[:account_number].gsub(/\A0+/, "").slice(0, 2)

      iban_bank_code =
        case domestic_bank_code
        when "11" then "22"
        when "93" then "00"
        else domestic_bank_code
        end

      account_number = local_details[:account_number].rjust(14, "0")

      { bank_code: iban_bank_code, account_number: account_number }
    end

    def self.clean_es_details(local_details)
      # This method supports being passed the component IBAN parts, as defined
      # by SWIFT, or a single 20 digit string.
      if local_details[:bank_code] && local_details[:branch_code]
        bank_code      = local_details[:bank_code]
        branch_code    = local_details[:branch_code]
        account_number = local_details[:account_number].gsub(/[-\s]/, "")
      else
        cleaned_account_number =
          local_details[:account_number].gsub(/[-\s]/, "")

        bank_code      = cleaned_account_number.slice(0, 4)
        branch_code    = cleaned_account_number.slice(4, 4)
        account_number = cleaned_account_number[8..-1]
      end

      {
        bank_code: bank_code,
        branch_code: branch_code,
        account_number: account_number,
      }
    end

    def self.clean_fi_details(local_details)
      #   Finnish account numbers need to be expanded into "electronic format"
      #   by adding zero-padding. The expansion method depends on the first
      #   character of the bank code.
      account_number =
        if %w[4 5 6].include?(local_details[:bank_code][0])
          [
            local_details[:account_number][0],
            local_details[:account_number][1..-1].rjust(7, "0"),
          ].join
        else
          local_details[:account_number].rjust(8, "0")
        end

      {
        bank_code: local_details[:bank_code],
        account_number: account_number,
      }
    end

    def self.clean_fr_details(local_details)
      {
        bank_code: local_details[:bank_code],
        branch_code: local_details[:branch_code],
        account_number: local_details[:account_number].gsub(/[-\s]/, ""),
      }
    end

    def self.clean_gb_details(local_details)
      # Account number may be 6-8 digits
      # Add leading zeros to account number if < 8 digits.
      branch_code = local_details[:branch_code].gsub(/[-\s]/, "")

      if local_details[:bank_code]
        bank_code = local_details[:bank_code]
      else
        bic = Ibandit.find_bic("GB", branch_code)
        bank_code = bic.nil? ? nil : bic.slice(0, 4)
      end

      account_number = local_details[:account_number].gsub(/[-\s]/, "")
      account_number = account_number.rjust(8, "0") if account_number.length > 5

      {
        bank_code: bank_code,
        branch_code: branch_code,
        account_number: account_number,
      }
    end

    def self.clean_gr_details(local_details)
      # Greek IBANs construction is idiosyncratic to the individual banks, and
      # no central specification is published.
      local_details
    end

    def self.clean_hr_details(local_details)
      # This method supports being passed the component IBAN parts, as defined
      # by SWIFT, or a single traditional-format string split by a '-'.
      return local_details if local_details[:bank_code]
      return local_details unless local_details[:account_number].include?("-")

      bank_code, account_number = local_details[:account_number].split("-", 2)

      {
        bank_code: bank_code,
        account_number: account_number,
      }
    end

    def self.clean_hu_details(local_details)
      # This method supports being passed the component IBAN parts, as defined
      # by SWIFT, or a single 16 or 24 digit string.
      return local_details if local_details[:bank_code] || local_details[:branch_code]

      cleaned_acct_number = local_details[:account_number].gsub(/[-\s]/, "")

      case cleaned_acct_number.length
      when 16
        {
          bank_code: cleaned_acct_number.slice(0, 3),
          branch_code: cleaned_acct_number.slice(3, 4),
          account_number: cleaned_acct_number.slice(7, 9).ljust(17, "0"),
        }
      when 24
        {
          bank_code: cleaned_acct_number.slice(0, 3),
          branch_code: cleaned_acct_number.slice(3, 4),
          account_number: cleaned_acct_number.slice(7, 17),
        }
      else local_details
      end
    end

    def self.clean_ie_details(local_details)
      # Ireland uses the same local details as the United Kingdom
      branch_code = local_details[:branch_code].gsub(/[-\s]/, "")

      if local_details[:bank_code]
        bank_code = local_details[:bank_code]
      else
        bic = Ibandit.find_bic("IE", branch_code)
        bank_code = bic.nil? ? nil : bic.slice(0, 4)
      end

      account_number = local_details[:account_number].gsub(/[-\s]/, "")
      account_number = account_number.rjust(8, "0") if account_number.length > 5

      {
        bank_code: bank_code,
        branch_code: branch_code,
        account_number: account_number,
      }
    end

    def self.clean_is_details(local_details)
      if local_details[:bank_code]
        bank_code = local_details[:bank_code]
        parts = local_details[:account_number].split("-")
      elsif local_details[:account_number].include?("-")
        bank_code, *parts = local_details[:account_number].split("-")
      else
        bank_code = local_details[:account_number].slice(0, 4)
        parts = Array(local_details[:account_number][4..-1])
      end

      {
        bank_code: bank_code.rjust(4, "0"),
        account_number: pad_is_account_number(parts),
      }
    end

    def self.clean_it_details(local_details)
      # Add leading zeros to account number if < 12 digits.
      {
        bank_code: local_details[:bank_code],
        branch_code: local_details[:branch_code],
        account_number: local_details[:account_number].rjust(12, "0"),
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

    def self.clean_mc_details(local_details)
      # Monaco uses the same local details method as France
      clean_fr_details(local_details)
    end

    def self.clean_mt_details(local_details)
      # Add leading zeros to account number if < 18 digits.
      branch_code = local_details[:branch_code]

      if local_details[:bank_code]
        bank_code = local_details[:bank_code]
      else
        bic = Ibandit.find_bic("MT", branch_code)
        bank_code = bic.nil? ? nil : bic.slice(0, 4)
      end

      account_number = local_details[:account_number].gsub(/[-\s]/, "")
      account_number = account_number.rjust(18, "0")

      {
        bank_code: bank_code,
        branch_code: branch_code,
        account_number: account_number,
      }
    end

    def self.clean_nl_details(local_details)
      # Add leading zeros to account number if < 10 digits.
      {
        bank_code: local_details[:bank_code],
        account_number: local_details[:account_number].rjust(10, "0"),
      }
    end

    def self.clean_no_details(local_details)
      # This method supports being passed the component IBAN parts, as defined
      # by SWIFT, or a single 11 digit string.
      if local_details[:bank_code]
        bank_code      = local_details[:bank_code]
        account_number = local_details[:account_number]
      else
        cleaned_acct_number = local_details[:account_number].gsub(/[-.\s]/, "")

        bank_code      = cleaned_acct_number.slice(0, 4)
        account_number = cleaned_acct_number[4..-1]
      end

      {
        bank_code: bank_code,
        account_number: account_number,
      }
    end

    def self.clean_nz_details(local_details)
      # This method supports being passed the component parts of the NZ account
      # number, or a single 15/16 digit string (BBbbbb-AAAAAAA-0SS) in the
      # account number field.
      #
      # When given a 15/16 digit string, the component parts (i.e bank_code,
      # branch_code and account_number) are extracted, with the 7-digit account
      # number body and 2/3-digit account number suffix making up the actual
      # account_number field.
      if local_details[:bank_code] && local_details[:branch_code]
        bank_code = local_details[:bank_code]
        branch_code = local_details[:branch_code]
        account_number = local_details[:account_number].tr("-", "")
      else
        cleaned_account_number = local_details[:account_number].tr("-", "")
        bank_code = cleaned_account_number.slice(0, 2)
        branch_code = cleaned_account_number.slice(2, 4)
        account_number = cleaned_account_number[6..-1]
      end

      if account_number && account_number.length == 9
        # > Some banks (such as BNZ) include three digits of the suffix in their
        # > presentation of the account number to the end customer. Other banks
        # > only show the last two digits of the suffix to the end customer.
        # > Technically, all banks have three digit suffixes, it's just that the
        # > first digit of the suffix is always 0 so it's usually ignored.
        # > [https://en.wikipedia.org/wiki/New_Zealand_bank_account_number]
        #
        # Here, we insert the zero in cases where it is ignored.
        account_number = account_number[0..6] + "0" + account_number[7..8]
      end

      {
        bank_code: bank_code,
        branch_code: branch_code,
        account_number: account_number,
      }
    end

    def self.clean_pl_details(local_details)
      # This method supports being passed the component IBAN parts, as defined
      # by SWIFT, or a single 26 digit string.
      if local_details[:bank_code]
        bank_code      = local_details[:bank_code]
        account_number = local_details[:account_number]
      else
        cleaned_acct_number = local_details[:account_number].gsub(/\s/, "")

        bank_code      = cleaned_acct_number.slice(2, 8)
        account_number = cleaned_acct_number[10..-1]
      end

      {
        bank_code: bank_code,
        account_number: account_number,
      }
    end

    def self.clean_pt_details(local_details)
      local_details
    end

    def self.clean_ro_details(local_details)
      # Romanian national bank details were replaced with IBANs in 2004.
      local_details
    end

    def self.clean_se_details(local_details)
      if local_details[:bank_code]
        # If a bank_code was provided without a branch code we're (probably)
        # dealing with SWIFT details and should just return them.
        {
          swift_account_number: local_details[:account_number],
          swift_bank_code: local_details[:bank_code],
        }
      else
        Sweden::LocalDetailsConverter.new(
          branch_code: local_details[:branch_code],
          account_number: local_details[:account_number],
        ).convert
      end
    end

    def self.clean_si_details(local_details)
      # Add leading zeros to account number if < 10 digits.
      {
        bank_code: local_details[:bank_code],
        account_number: local_details[:account_number].rjust(10, "0"),
      }
    end

    def self.clean_sk_details(local_details)
      # Slovakia uses the same local details method as the Czech Republic
      clean_cz_details(local_details)
    end

    def self.clean_sm_details(local_details)
      # San Marino uses the same local details method as France
      clean_it_details(local_details)
    end

    def self.pad_is_account_number(parts)
      hufo           = parts[0].nil? ? "" : parts[0].rjust(2, "0")
      reikningsnumer = parts[1].nil? ? "" : parts[1].rjust(6, "0")
      ken_1          = parts[2].nil? ? "" : parts[2].rjust(6, "0")
      ken_2          = parts[3].nil? ? "" : parts[3].rjust(4, "0")

      kennitala = ken_1.empty? ? "" : (ken_1 + ken_2).rjust(10, "0")

      hufo + reikningsnumer + kennitala
    end
    private_class_method :pad_is_account_number

    def self.swift_details_for(local_details)
      {
        swift_bank_code: local_details[:bank_code],
        swift_branch_code: local_details[:branch_code],
        swift_account_number: local_details[:account_number],
      }
    end
    private_class_method :swift_details_for
  end
end
