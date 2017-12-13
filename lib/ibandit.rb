require "i18n"
require "ibandit/version"
require "ibandit/errors"
require "ibandit/constants"
require "ibandit/iban"
require "ibandit/german_details_converter"
require "ibandit/sweden/local_details_converter"
require "ibandit/sweden/validator"
require "ibandit/sweden/bank_lookup"
require "ibandit/iban_splitter"
require "ibandit/iban_assembler"
require "ibandit/pseudo_iban_assembler"
require "ibandit/pseudo_iban_splitter"
require "ibandit/local_details_cleaner"
require "ibandit/check_digit"

I18n.load_path += Dir[File.expand_path("../../config/locales/*.{rb,yml}",
                                       __FILE__)]

module Ibandit
  class << self
    attr_accessor :bic_finder, :modulus_checker

    def find_bic(country_code, national_id)
      raise NotImplementedError, "BIC finder is not defined" unless @bic_finder
      @bic_finder.call(country_code, national_id)
    end

    def structures
      @structures ||= YAML.load_file(
        File.expand_path("../../data/structures.yml", __FILE__),
      )
    end

    def translate(key, options = {})
      I18n.translate(key, { scope: [:ibandit] }.merge(options))
    end
  end
end
