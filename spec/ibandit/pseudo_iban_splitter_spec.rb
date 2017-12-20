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

    context "for an australian pseudo-IBAN" do
      let(:pseudo_iban) { "AUZZ123456123456789" }

      its([:country_code]) { is_expected.to eq("AU") }
      its([:bank_code]) { is_expected.to be_nil }
      its([:branch_code]) { is_expected.to eq("123456") }
      its([:account_number]) { is_expected.to eq("123456789") }
    end
  end
end
