# frozen_string_literal: true

require File.expand_path("lib/ibandit/version", __dir__)

Gem::Specification.new do |gem|
  gem.add_development_dependency "gc_ruboconfig",   "~> 3.3.0"
  gem.add_development_dependency "nokogiri",        "~> 1.6"
  gem.add_development_dependency "pry",             "~> 0.13"
  gem.add_development_dependency "pry-byebug",      "~> 3.9"
  gem.add_development_dependency "rspec",           "~> 3.3"
  gem.add_development_dependency "rspec-its",       "~> 1.2"
  gem.add_development_dependency "rspec_junit_formatter", "~> 0.6.0"
  gem.add_development_dependency "sax-machine", "~> 1.3"

  gem.add_runtime_dependency "i18n"

  gem.authors = %w[GoCardless]
  gem.description = "Ibandit is a Ruby library for manipulating and " \
                    "validating IBANs. It allows you to construct an IBAN " \
                    "from national banking details; deconstruct an IBAN into " \
                    "national banking details; and validate an IBAN's check " \
                    "digits and format."
  gem.email = %w[developers@gocardless.com]
  gem.files = `git ls-files`.split("\n")
  gem.homepage = "https://github.com/gocardless/ibandit"
  gem.licenses = ["MIT"]
  gem.name = "ibandit"
  gem.require_paths = ["lib"]
  gem.summary = "Convert national banking details into IBANs, and vice-versa."
  gem.version = Ibandit::VERSION.dup
  gem.metadata["rubygems_mfa_required"] = "true"
end
