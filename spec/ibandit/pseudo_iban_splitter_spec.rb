require 'spec_helper'

describe Ibandit::PseudoIBANSplitter do
  subject(:splitter) { described_class.new(pseudo_iban) }

  describe '#split' do
    subject(:local_details) { splitter.split }

    context 'for a valid pseudo-IBAN' do
      let(:pseudo_iban) { 'SEZZX1281XXX0105723' }

      its([:country_code]) { is_expected.to eq('SE') }
      its([:bank_code]) { is_expected.to be_nil }
      its([:branch_code]) { is_expected.to eq('1281') }
      its([:account_number]) { is_expected.to eq('0105723') }
    end

    context 'for an unsupported country' do
      let(:pseudo_iban) { 'GBZZX1281XXX0105723' }

      it { is_expected.to be_nil }
    end

    context 'with invalid check digits' do
      let(:pseudo_iban) { 'SEYYX1281XXX0105723' }

      it { is_expected.to be_nil }
    end

    context 'with the wrong length' do
      let(:pseudo_iban) { 'SEYYX1281XXX010572' }

      it { is_expected.to be_nil }
    end
  end
end
