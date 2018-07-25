require "spec_helper"

describe Ibandit::PseudoIBANSplitter do
  subject(:splitter) { described_class.new(pseudo_iban) }

  describe "#split" do
    subject(:local_details) { splitter.split }

    context "for a swedish pseudo-IBAN" do
      let(:pseudo_iban) { "SEZZX1281XXX0105723" }

      its([:country_code]) { is_expected.to eq("SE") }
      its([:bank_code]) { is_expected.to be_nil }
      its([:branch_code]) { is_expected.to eq("1281") }
      its([:account_number]) { is_expected.to eq("0105723") }
    end

    context "for a New Zealand pseudo-IBAN" do
      let(:pseudo_iban) { "NZZZ0156997777777030" }

      its([:country_code]) { is_expected.to eq("NZ") }
      its([:bank_code]) { is_expected.to eq("01") }
      its([:branch_code]) { is_expected.to eq("5699") }
      its([:account_number]) { is_expected.to eq("7777777030") }
    end

    context "for an australian pseudo-IBAN" do
      let(:pseudo_iban) { "AUZZ123456123456789" }

      its([:country_code]) { is_expected.to eq("AU") }
      its([:bank_code]) { is_expected.to be_nil }
      its([:branch_code]) { is_expected.to eq("123456") }
      its([:account_number]) { is_expected.to eq("123456789") }
    end

    context "for an australian pseudo-IBAN with padding" do
      let(:pseudo_iban) { "AUZZ123456______XABC" }

      its([:country_code]) { is_expected.to eq("AU") }
      its([:bank_code]) { is_expected.to be_nil }
      its([:branch_code]) { is_expected.to eq("123456") }
      its([:account_number]) { is_expected.to eq("XABC") }
    end

    context "for an australian 10 character alphanumeric pseudo-iban" do
      let(:pseudo_iban) { "AUZZ12345601234567AB" }

      its([:country_code]) { is_expected.to eq("AU") }
      its([:bank_code]) { is_expected.to be_nil }
      its([:branch_code]) { is_expected.to eq("123456") }
      its([:account_number]) { is_expected.to eq("01234567AB") }
    end

    context "for an australian 10 character pseudo-iban with an X" do
      let(:pseudo_iban) { "AUZZ1234560X12345678" }

      its([:country_code]) { is_expected.to eq("AU") }
      its([:bank_code]) { is_expected.to be_nil }
      its([:branch_code]) { is_expected.to eq("123456") }
      its([:account_number]) { is_expected.to eq("0X12345678") }
    end

    context "for an australian 10 character pseudo-iban with a leading X" do
      let(:pseudo_iban) { "AUZZ123456X123456789" }

      its([:country_code]) { is_expected.to eq("AU") }
      its([:bank_code]) { is_expected.to be_nil }
      its([:branch_code]) { is_expected.to eq("123456") }
      its([:account_number]) { is_expected.to eq("X123456789") }
    end
  end
end
