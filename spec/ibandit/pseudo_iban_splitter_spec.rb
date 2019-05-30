# frozen_string_literal: true

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

    context "for a canadian pseudo-IBAN without padding" do
      let(:pseudo_iban) { "CAZZ0036000630123456" }

      its([:country_code]) { is_expected.to eq("CA") }
      its([:bank_code]) { is_expected.to eq("0036") }
      its([:branch_code]) { is_expected.to eq("00063") }
      its([:account_number]) { is_expected.to eq("0123456") }
    end

    context "for a canadian pseudo-IBAN with padding" do
      let(:pseudo_iban) { "CAZZ003600063_____0123456" }

      its([:country_code]) { is_expected.to eq("CA") }
      its([:bank_code]) { is_expected.to eq("0036") }
      its([:branch_code]) { is_expected.to eq("00063") }
      its([:account_number]) { is_expected.to eq("0123456") }
    end

    context "for a canadian pseudo-IBAN with a 12-digit account number" do
      let(:pseudo_iban) { "CAZZ003600063012345678900" }

      its([:country_code]) { is_expected.to eq("CA") }
      its([:bank_code]) { is_expected.to eq("0036") }
      its([:branch_code]) { is_expected.to eq("00063") }
      its([:account_number]) { is_expected.to eq("012345678900") }
    end

    context "for a US pseudo-IBAN without padding" do
      let(:pseudo_iban) { "USZZ0123456780123456" }

      its([:country_code]) { is_expected.to eq("US") }
      its([:bank_code]) { is_expected.to eq("012345678") }
      its([:account_number]) { is_expected.to eq("0123456") }
    end

    context "for a US pseudo-IBAN with padding" do
      let(:pseudo_iban) { "USZZ012345678__________0123456" }

      its([:country_code]) { is_expected.to eq("US") }
      its([:bank_code]) { is_expected.to eq("012345678") }
      its([:account_number]) { is_expected.to eq("0123456") }
    end

    context "for a US pseudo-IBAN with a 17-digit account number" do
      let(:pseudo_iban) { "USZZ01234567801234567890123456" }

      its([:country_code]) { is_expected.to eq("US") }
      its([:bank_code]) { is_expected.to eq("012345678") }
      its([:account_number]) { is_expected.to eq("01234567890123456") }
    end
  end
end
