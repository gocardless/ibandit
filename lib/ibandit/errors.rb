module Ibandit
  class BicNotFoundError < StandardError; end
  class InvalidCharacterError < StandardError; end
  class UnsupportedCountryError < StandardError; end
  class UnsupportedAccountDetails < StandardError; end
end
