require File.expand_path('../lib/iban_bru/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_development_dependency 'rspec',           '~> 3.1.0'
  gem.add_development_dependency 'rspec-its',       '~> 1.1'

  gem.authors = ['Grey Baker']
  gem.description = %q{Ruby library for manipulating and validating IBANs}
  gem.email = ['grey@gocardless.com']
  gem.files = `git ls-files`.split("\n")
  gem.homepage = 'https://github.com/gocardless/iban'
  gem.name = 'iban-bru'
  gem.require_paths = ['lib']
  gem.summary = %q{Ruby library for manipulating and validating IBANs}
  gem.test_files = `git ls-files -- {spec}/*`.split("\n")
  gem.version = IbanBru::VERSION.dup
end
