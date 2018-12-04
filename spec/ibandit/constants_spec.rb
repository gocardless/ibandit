# frozen_string_literal: true

require "spec_helper"

describe Ibandit::Constants do
  Ibandit::Constants::PSEUDO_IBAN_COUNTRY_CODES.each do |country_code|
    context country_code do
      it "has padding character" do
        padding =
          Ibandit::Constants::PSEUDO_IBAN_PADDING_CHARACTER_FOR[country_code]
        expect(padding).to_not be_nil
        expect(padding.length).to eq(1)
      end
    end
  end
end
