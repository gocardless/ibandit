# frozen_string_literal: true

require "spec_helper"

describe "structures.yml" do
  structure_file = File.expand_path("../../data/structures.yml", __dir__)
  structures = YAML.load_file(structure_file)

  structures.each do |country, rules|
    context country do
      rules.each do |rule, value|
        next unless rule.to_s.end_with?("_format")

        it "builds #{rule} rule" do
          expect { Regexp.new(value) }.to_not raise_exception
        end
      end
    end
  end
end
