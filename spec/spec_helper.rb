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
