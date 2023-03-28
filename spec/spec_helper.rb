# frozen_string_literal: true

require "ibandit"
require "rspec/its"
require "json"

RSpec.configure do |config|
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.raise_errors_for_deprecations!

  config.around do |example|
    locale = example.metadata.fetch(:locale, :en)

    I18n.with_locale(locale) { example.run }
  end
end

def json_fixture(filename)
  JSON.parse(File.read("spec/fixtures/#{filename}.json"))
end
