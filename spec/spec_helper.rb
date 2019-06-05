# frozen_string_literal: true

require "ibandit"
require "rspec/its"
require "json"

RSpec.configure do |config|
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.raise_errors_for_deprecations!
end

def json_fixture(filename)
  JSON.parse(File.read("spec/fixtures/#{filename}.json"))
end

RSpec.shared_context "locale en", locale: :en do
  around { |example| I18n.with_locale(:en) { example.run } }
end

RSpec.shared_context "locale fr", locale: :fr do
  around { |example| I18n.with_locale(:fr) { example.run } }
end

RSpec.shared_context "locale de", locale: :de do
  around { |example| I18n.with_locale(:de) { example.run } }
end

RSpec.shared_context "locale pt", locale: :pt do
  around { |example| I18n.with_locale(:pt) { example.run } }
end

RSpec.shared_context "locale es", locale: :es do
  around { |example| I18n.with_locale(:es) { example.run } }
end

RSpec.shared_context "locale it", locale: :it do
  around { |example| I18n.with_locale(:it) { example.run } }
end

RSpec.shared_context "locale nl", locale: :nl do
  around { |example| I18n.with_locale(:nl) { example.run } }
end

RSpec.shared_context "locale nb", locale: :nb do
  around { |example| I18n.with_locale(:nb) { example.run } }
end

RSpec.shared_context "locale sl", locale: :sl do
  around { |example| I18n.with_locale(:sl) { example.run } }
end

RSpec.shared_context "locale sv", locale: :sv do
  around { |example| I18n.with_locale(:sv) { example.run } }
end

RSpec.shared_context "locale da", locale: :da do
  around { |example| I18n.with_locale(:da) { example.run } }
end
