# frozen_string_literal: true

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

I18n.load_path += Dir[File.expand_path("../config/locales/*.{rb,yml}",
                                       __dir__)]

module Ibandit
  class << self
    attr_accessor :bic_finder, :modulus_checker

    def find_bic(country_code, national_id)
      raise NotImplementedError, "BIC finder is not defined" unless @bic_finder

      @bic_finder.call(country_code, national_id)
    end

    def structures
      @structures ||= YAML.safe_load(
        File.read(File.expand_path("../data/structures.yml", __dir__)),
        permitted_classes: [Range, Symbol],
      )
    end

    def translate(key, options = {})
      I18n.translate(key, scope: [:ibandit], **options)
    end
  end
end
