require 'spec_helper'

describe Ibandit::CheckDigit do
  describe '.mod_11' do
    subject { described_class.mod_11(account_number) }

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
        expect { subject }.to raise_error(ArgumentError)
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
end
