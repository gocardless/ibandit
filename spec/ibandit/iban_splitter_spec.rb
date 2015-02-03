require 'spec_helper'

describe Ibandit::IBANSplitter do
  subject(:parts) { described_class.new(iban_code).parts }

  context 'with a poorly formatted IBAN' do
    let(:iban_code) { "  gb82 WeSt 1234 5698 7654 32\n" }
    its([:iban]) { is_expected.to eq('GB82WEST12345698765432') }
    its([:country_code]) { is_expected.to eq('GB') }
    its([:check_digits]) { is_expected.to eq('82') }
    its([:bank_code]) { is_expected.to eq('WEST') }
    its([:branch_code]) { is_expected.to eq('123456') }
    its([:account_number]) { is_expected.to eq('98765432') }
  end

  context 'with nil' do
    let(:iban_code) { nil }
    its([:iban]) { is_expected.to eq('') }
    its([:country_code]) { is_expected.to eq('') }
    its([:check_digits]) { is_expected.to eq('') }
    its([:bank_code]) { is_expected.to eq('') }
    its([:branch_code]) { is_expected.to eq('') }
    its([:account_number]) { is_expected.to eq('') }
  end

  describe 'with an empty string' do
    let(:iban_code) { '' }
    its([:iban]) { is_expected.to eq('') }
    its([:country_code]) { is_expected.to eq('') }
    its([:check_digits]) { is_expected.to eq('') }
    its([:bank_code]) { is_expected.to eq('') }
    its([:branch_code]) { is_expected.to eq('') }
    its([:account_number]) { is_expected.to eq('') }
  end
end
