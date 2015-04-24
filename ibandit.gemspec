require File.expand_path('../lib/ibandit/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_development_dependency 'rspec',           '~> 3.1'
  gem.add_development_dependency 'rspec-its',       '~> 1.1'
  gem.add_development_dependency 'rubocop',         '~> 0.30.1'
  gem.add_development_dependency 'sax-machine',     '~> 1.1'
  gem.add_development_dependency 'nokogiri',        '~> 1.6'

  gem.add_runtime_dependency 'i18n', '~> 0.7.0'

  gem.authors = ['Grey Baker']
  gem.description = 'Ibandit is a Ruby library for manipulating and ' \
                    'validating IBANs. It allows you to construct an IBAN ' \
                    'from national banking details; deconstruct an IBAN into ' \
                    'national banking details; and validate an IBAN\'s check ' \
                    'digits and format.'
  gem.email = ['grey@gocardless.com']
  gem.files = `git ls-files`.split("\n")
  gem.homepage = 'https://github.com/gocardless/ibandit'
  gem.licenses = ['MIT']
  gem.name = 'ibandit'
  gem.require_paths = ['lib']
  gem.summary = 'Convert national banking details into IBANs, and vice-versa.'
  gem.version = Ibandit::VERSION.dup
end
