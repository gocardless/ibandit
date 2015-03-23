require 'ibandit'
require 'rspec/its'
require 'json'

RSpec.configure do |config|
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.raise_errors_for_deprecations!
end

def json_fixture(filename)
  JSON.parse(File.read("spec/fixtures/#{filename}.json"))
end

RSpec.shared_context 'locale en', locale: :en do
  around { |example| I18n.with_locale(:en) { example.run } }
end

RSpec.shared_context 'locale fr', locale: :fr do
  around { |example| I18n.with_locale(:fr) { example.run } }
end
