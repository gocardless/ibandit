module Ibandit
  module Constants
    SUPPORTED_COUNTRY_CODES = %w(AT BE BG CY CZ DE DK EE ES FI FR GB GR HR HU IE
                                 IS IT LT LU LV MC MT NL NO PL PT RO SE SI SK
                                 SM).freeze

    PSEUDO_IBAN_COUNTRY_CODES = %w(SE).freeze
    PSEUDO_IBAN_CHECK_DIGITS = 'ZZ'.freeze
  end
end
