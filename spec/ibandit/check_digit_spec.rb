require 'spec_helper'

describe Ibandit::CheckDigit do
  describe '.spanish' do
    subject { described_class.spanish(account_number) }

    context 'sequence that should give a check digit of 0' do
      let(:account_number) { '12345678' }
      it { is_expected.to eq('0') }
    end

    context 'sequence that should give a check digit of 8' do
      let(:account_number) { '0000012345' }
      it { is_expected.to eq('8') }
    end

    context 'with a non-numeric character' do
      let(:account_number) { '000001234A' }
      it 'raises an error' do
        expect { subject }.to raise_error(Ibandit::InvalidCharacterError)
      end
    end
  end

  describe '.lund' do
    subject { described_class.lund(account_number) }

    let(:account_number) { '1200300002088' }
    it { is_expected.to eq('3') }

    context 'with another account number (double checking!)' do
      let(:account_number) { '1428350017114' }
      it { is_expected.to eq('1') }
    end

    context 'with a non-numeric character' do
      let(:account_number) { '1BAD2014' }
      specify { expect { subject }.to raise_error(/non-numeric character/) }
    end
  end

  describe '.estonian' do
    subject { described_class.estonian(account_number) }

    context "with an account_number that doesn't start with a zero" do
      let(:account_number) { '22102014568' }
      it { is_expected.to eq('5') }
    end

    context 'with leading zeros' do
      let(:account_number) { '0022102014568' }
      it { is_expected.to eq('5') }
    end

    context 'with a non-numeric character' do
      let(:account_number) { '1BAD2014' }
      specify { expect { subject }.to raise_error(/non-numeric character/) }
    end
  end

  describe '.dutch' do
    subject { described_class.dutch(account_number) }

    let(:account_number) { '041716430' }
    it { is_expected.to eq('0') }

    context 'with another account number (double checking!)' do
      let(:account_number) { '030006526' }
      it { is_expected.to eq('4') }
    end

    context 'with a non-numeric character' do
      let(:account_number) { '1BAD2014' }
      specify { expect { subject }.to raise_error(/non-numeric character/) }
    end
  end

  describe '.slovakian_prefix' do
    subject { described_class.slovakian_prefix(account_number) }

    let(:account_number) { '00001' }
    it { is_expected.to eq('9') }

    context 'with a non-numeric character' do
      let(:account_number) { '1BAD2014' }
      specify { expect { subject }.to raise_error(/non-numeric character/) }
    end
  end

  describe '.slovakian_basic' do
    subject { described_class.slovakian_basic(account_number) }

    let(:account_number) { '874263754' }
    it { is_expected.to eq('1') }

    context 'with a non-numeric character' do
      let(:account_number) { '1BAD2014' }
      specify { expect { subject }.to raise_error(/non-numeric character/) }
    end
  end

  describe '.rib' do
    subject { described_class.rib(bank_code, branch_code, account_number) }

    context 'with some non-numeric characters' do
      let(:bank_code) { '12BD4' }
      let(:branch_code) { '367WX' }
      let(:account_number) { '12345678912' }

      it { is_expected.to eq('20') }
    end

    context 'with numeric characters' do
      let(:bank_code) { '12244' }
      let(:branch_code) { '36767' }
      let(:account_number) { '12345678912' }

      it { is_expected.to eq('20') }
    end
  end
end
