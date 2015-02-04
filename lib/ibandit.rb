require 'ibandit/version'
require 'ibandit/errors'
require 'ibandit/iban'
require 'ibandit/german_details_converter'
require 'ibandit/iban_splitter'
require 'ibandit/iban_assembler'
require 'ibandit/local_details_cleaner'
require 'ibandit/check_digit'

module Ibandit
  class << self
    attr_accessor :bic_finder

    def find_bic(country_code, national_id)
      raise NotImplementedError, 'BIC finder is not defined' unless @bic_finder
      @bic_finder.call(country_code, national_id)
    end

    def structures
      @structures ||= YAML.load_file(
        File.expand_path('../../data/structures.yml', __FILE__)
      )
    end
  end
end
