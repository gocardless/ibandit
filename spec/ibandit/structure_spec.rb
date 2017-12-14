require "spec_helper"

describe "structures.yml" do
  FILE = File.expand_path("../../../data/structures.yml", __FILE__)
  STRUCTURES = YAML.load_file(FILE)

  STRUCTURES.each do |country, rules|
    context country do
      rules.each do |rule, value|
        next unless rule =~ /_format$/

        it "builds #{rule} rule" do
          expect { Regexp.new(value) }.to_not raise_exception
        end
      end
    end
  end
end
