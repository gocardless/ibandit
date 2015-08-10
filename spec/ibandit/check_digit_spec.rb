require 'spec_helper'

describe Ibandit::CheckDigit do
  describe '.mod_97_10' do
    subject { described_class.mod_97_10(account_number) }

    context 'with a non-numeric character' do
      let(:account_number) { 'hhhh' }
      specify { expect { subject }.to raise_error(/non-alphanumeric/) }
    end
  end

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

    context 'with a string that is fewer than 10 characters' do
      let(:account_number) { '20386010' }

      it 'zero-pads the string to get the correct check digit' do
        expect(subject).to eq('5')
      end
    end
  end

  describe '.belgian' do
    subject { described_class.belgian(account_number) }

    let(:account_number) { '5100075470' }
    it { is_expected.to eq('61') }

    context 'with an account number which is a factor of 97' do
      let(:account_number) { '1030343409' }
      it { is_expected.to eq('97') }
    end
  end

  describe '.luhn' do
    subject { described_class.luhn(account_number) }

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

  describe '.hungarian' do
    subject { described_class.hungarian(account_number) }

    let(:account_number) { '1234567' }
    it { is_expected.to eq('6') }

    context 'with another account number (double checking!)' do
      let(:account_number) { '1111101' }
      it { is_expected.to eq('8') }
    end

    context 'with all zeros' do
      let(:account_number) { '0000000' }
      it { is_expected.to eq('0') }
    end

    context 'with a non-numeric character' do
      let(:account_number) { '1BAD2014' }
      specify { expect { subject }.to raise_error(/non-numeric character/) }
    end
  end

  describe '.croatian' do
    subject { described_class.croatian(account_number) }

    let(:account_number) { '0823' }
    it { is_expected.to eq('5') }

    context 'with another account number (double checking!)' do
      let(:account_number) { '100100' }
      it { is_expected.to eq('5') }
    end

    context 'with all zeros' do
      let(:account_number) { '186300016' }
      it { is_expected.to eq('0') }
    end

    context 'with a non-numeric character' do
      let(:account_number) { '1BAD2014' }
      specify { expect { subject }.to raise_error(/non-numeric character/) }
    end
  end

  describe '.icelandic' do
    subject { described_class.icelandic(kennitala) }

    let(:kennitala) { '52121206' }
    it { is_expected.to eq('3') }

    context 'with another kennitala (double checking!)' do
      let(:kennitala) { '42027802' }
      it { is_expected.to eq('0') }
    end

    context 'with a third kennitala (triple checking!)' do
      let(:kennitala) { '12017433' }
      it { is_expected.to eq('9') }
    end

    context 'with a non-numeric character' do
      let(:kennitala) { '1BAD2014' }
      specify { expect { subject }.to raise_error(/non-numeric character/) }
    end
  end

  describe '.norwegian' do
    subject { described_class.norwegian(account_number) }

    let(:account_number) { '8601111794' }
    it { is_expected.to eq('7') }

    context 'with another account number (double checking!)' do
      let(:account_number) { '8601549472' }
      it { is_expected.to eq('9') }
    end

    context 'with a third account number (triple checking!)' do
      let(:account_number) { '3000501790' }
      it { is_expected.to eq('0') }
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
