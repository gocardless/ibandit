require "spec_helper"

describe Ibandit::IBANSplitter do
  subject(:split) { described_class.split(iban_code) }

  context "with a valid IBAN" do
    let(:iban_code) { "GB82WEST12345698765432" }
    its([:country_code]) { is_expected.to eq("GB") }
    its([:check_digits]) { is_expected.to eq("82") }
    its([:bank_code]) { is_expected.to eq("WEST") }
    its([:branch_code]) { is_expected.to eq("123456") }
    its([:account_number]) { is_expected.to eq("98765432") }
  end

  context "with nil" do
    let(:iban_code) { nil }
    its([:country_code]) { is_expected.to eq(nil) }
    its([:check_digits]) { is_expected.to eq(nil) }
    its([:bank_code]) { is_expected.to eq(nil) }
    its([:branch_code]) { is_expected.to eq(nil) }
    its([:account_number]) { is_expected.to eq(nil) }
  end

  context "with an empty string" do
    let(:iban_code) { "" }
    its([:country_code]) { is_expected.to eq(nil) }
    its([:check_digits]) { is_expected.to eq(nil) }
    its([:bank_code]) { is_expected.to eq(nil) }
    its([:branch_code]) { is_expected.to eq(nil) }
    its([:account_number]) { is_expected.to eq(nil) }
  end

  context "with an invalid length IBAN" do
    let(:iban_code) { "MC9320052222100112233M445" }
    its([:country_code]) { is_expected.to eq("MC") }
    its([:check_digits]) { is_expected.to eq(nil) }
    its([:bank_code]) { is_expected.to eq(nil) }
    its([:branch_code]) { is_expected.to eq(nil) }
    its([:account_number]) { is_expected.to eq(nil) }
  end
end
