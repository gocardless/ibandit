# frozen_string_literal: true

require File.expand_path("lib/ibandit/version", __dir__)

Gem::Specification.new do |spec|
  spec.name = "ibandit"
  spec.version = Ibandit::VERSION.dup
  spec.summary = "Convert national banking details into IBANs, and vice-versa."
  spec.description = <<~MSG.strip.tr("\n", " ")
    Ibandit is a Ruby library for manipulating and
    validating IBANs. It allows you to construct an IBAN
    from national banking details; deconstruct an IBAN into
    national banking details; and validate an IBAN's check
    digits and format.
  MSG
  spec.authors = %w[GoCardless]
  spec.email = %w[developers@gocardless.com]
  spec.licenses = ["MIT"]

  spec.files = `git ls-files`.split("\n")
  spec.homepage = "https://github.com/gocardless/ibandit"

  spec.metadata = {
    "rubygems_mfa_required" => "true",
  }

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"
  spec.add_development_dependency "gc_ruboconfig",   "~> 4.3"
  spec.add_development_dependency "nokogiri",        "~> 1.6"
  spec.add_development_dependency "pry",             "~> 0.13"
  spec.add_development_dependency "pry-byebug",      "~> 3.10"
  spec.add_development_dependency "rspec",           "~> 3.12"
  spec.add_development_dependency "rspec-its",       "~> 1.2"
  spec.add_development_dependency "sax-machine", "~> 1.3"

  spec.add_runtime_dependency "i18n"
end
