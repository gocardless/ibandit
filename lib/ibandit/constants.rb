# frozen_string_literal: true

module Ibandit
  module Constants
    CONSTRUCTABLE_IBAN_COUNTRY_CODES = %w[AT BE BG CY CZ DE DK EE ES FI FR GB GR
                                          HR HU IE IS IT LT LU LV MC MT NL NO PL
                                          PT RO SE SI SK SM].freeze

    PSEUDO_IBAN_COUNTRY_CODES = %w[AU SE NZ CA US].freeze
    DECONSTRUCTABLE_IBAN_COUNTRY_CODES =
      CONSTRUCTABLE_IBAN_COUNTRY_CODES - PSEUDO_IBAN_COUNTRY_CODES

    PSEUDO_IBAN_CHECK_DIGITS = "ZZ"

    PSEUDO_IBAN_PADDING_CHARACTER_FOR = {
      "SE" => "X", # Using X for backwards compatibility
      "AU" => "_", # Using _ because AU account numbers are alphanumeric
      "NZ" => "_",
      "CA" => "_",
      "US" => "_",
    }.freeze

    SUPPORTED_COUNTRY_CODES = (
      CONSTRUCTABLE_IBAN_COUNTRY_CODES +
      DECONSTRUCTABLE_IBAN_COUNTRY_CODES +
      PSEUDO_IBAN_COUNTRY_CODES
    ).uniq
  end
end
