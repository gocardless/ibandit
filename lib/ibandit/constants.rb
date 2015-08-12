module Ibandit
  module Constants
    SUPPORTED_COUNTRY_CODES = %w(AT BE BG CY CZ DE DK EE ES FI FR GB GR HR HU IE
                                 IS IT LT LU LV MC MT NL NO PL PT RO SE SI SK
                                 SM).freeze
    EXPLICIT_SWIFT_DETAILS_COUNTRY_CODES = %w(SE).freeze
  end
end
