# frozen_string_literal: true

module Ibandit
  module IBANAssembler
    EXCEPTION_COUNTRY_CODES = %w[IT SM BE].freeze

    def self.assemble(local_details)
      country_code = local_details[:country_code]

      return unless can_assemble?(local_details)

      bban =
        if EXCEPTION_COUNTRY_CODES.include?(country_code)
          public_send(:"assemble_#{country_code.downcase}_bban", local_details)
        else
          assemble_general_bban(local_details)
        end

      assemble_iban(country_code, bban)
    rescue InvalidCharacterError
      nil
    end

    ##############################
    # General case BBAN creation #
    ##############################

    def self.assemble_general_bban(opts)
      [opts[:bank_code], opts[:branch_code], opts[:account_number]].join
    end

    ##################################
    # Country-specific BBAN creation #
    ##################################

    def self.assemble_be_bban(opts)
      # The first three digits of Belgian account numbers are the bank_code,
      # but the account number is not considered complete without these three
      # numbers and the IBAN structure file includes them in its definition of
      # the account number. As a result, this method ignores all arguments
      # other than the account number.
      opts[:account_number]
    end

    def self.assemble_it_bban(opts)
      # The  Italian check digit is NOT included in the any of the other SWIFT
      # elements, so should be passed explicitly or left blank for it to be
      # calculated implicitly
      partial_bban = [
        opts[:bank_code],
        opts[:branch_code],
        opts[:account_number],
      ].join

      check_digit = opts[:check_digit] || CheckDigit.italian(partial_bban)

      [check_digit, partial_bban].join
    end

    def self.assemble_sm_bban(opts)
      # San Marino uses the same BBAN construction method as Italy
      assemble_it_bban(opts)
    end

    ##################
    # Helper methods #
    ##################

    def self.can_assemble?(local_details)
      supported_country_code?(local_details) && valid_arguments?(local_details)
    end

    def self.supported_country_code?(local_details)
      Constants::CONSTRUCTABLE_IBAN_COUNTRY_CODES.
        include?(local_details[:country_code])
    end

    def self.valid_arguments?(local_details)
      country_code = local_details[:country_code]

      supplied = local_details.keys.select { |key| local_details[key] }
      supplied.delete(:country_code)

      allowed = allowed_fields(country_code)

      required_fields(country_code).all? { |key| supplied.include?(key) } &&
        supplied.all? { |key| allowed.include?(key) }
    end

    def self.required_fields(country_code)
      case country_code
      when "AT", "CY", "CZ", "DE", "DK", "EE", "FI", "HR", "IS", "LT", "LU",
           "LV", "NL", "NO", "PL", "RO", "SE", "SI", "SK"
        %i[bank_code account_number]
      when "BE"
        %i[account_number]
      else
        %i[bank_code branch_code account_number]
      end
    end

    def self.allowed_fields(country_code)
      # Some countries have additional optional fields
      case country_code
      when "BE" then %i[bank_code account_number]
      when "CY" then %i[bank_code branch_code account_number]
      when "IT" then %i[bank_code branch_code account_number check_digit]
      when "CZ", "SK" then %i[bank_code account_number account_number_prefix]
      else required_fields(country_code)
      end
    end

    def self.assemble_iban(country_code, bban)
      [
        country_code,
        CheckDigit.iban(country_code, bban),
        bban,
      ].join
    rescue InvalidCharacterError
      nil
    end
  end
end
