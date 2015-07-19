require 'spec_helper'

describe Ibandit::SwedishDetailsConverter do
  subject(:converted) { described_class.convert(account_number) }

  context 'with a type-1 account number' do
    let(:account_number) { '12810105723' }

    its([:bank_code]) { is_expected.to eq('120') }
    its([:account_number]) { is_expected.to eq('00000012810105723') }

    context 'that includes hyphens' do
      let(:account_number) { '1281-0105723' }

      its([:bank_code]) { is_expected.to eq('120') }
      its([:account_number]) { is_expected.to eq('00000012810105723') }
    end

    context 'that includes spaces' do
      let(:account_number) { '1281 0105723' }

      its([:bank_code]) { is_expected.to eq('120') }
      its([:account_number]) { is_expected.to eq('00000012810105723') }
    end

    context 'that includes full stops' do
      let(:account_number) { '1281.010.572.3' }

      its([:bank_code]) { is_expected.to eq('120') }
      its([:account_number]) { is_expected.to eq('00000012810105723') }
    end

    context 'that has been zero-padded' do
      let(:account_number) { '000012810105723' }

      its([:bank_code]) { is_expected.to eq('120') }
      its([:account_number]) { is_expected.to eq('00000012810105723') }
    end

    context 'that needs the account number part to be zero-padded' do
      let(:account_number) { '1281-1' }

      its([:bank_code]) { is_expected.to eq('120') }
      # TODO: Decide whether we should be zero-padding here or not
      its([:account_number]) { is_expected.to eq('00000012810000001') }
    end
  end

  context "with a clearing code that doesn't match any banks" do
    let(:account_number) { '1001-1' }

    its([:bank_code]) { is_expected.to eq(nil) }
    its([:account_number]) { is_expected.to eq('00000000000010011') }
  end

  context 'with a Swedbank clearing code' do
    let(:account_number) { '7507-1211203' }

    its([:bank_code]) { is_expected.to eq('800') }
    its([:account_number]) { is_expected.to eq('00000075071211203') }

    context 'in the 8000s range' do
      let(:account_number) { '8327-9 33395390-9' }

      its([:bank_code]) { is_expected.to eq('800') }
      its([:account_number]) { is_expected.to eq('00832790333953909') }
    end

    context 'another in the 8000s range' do
      let(:account_number) { '8201-6 914357963-0' }

      its([:bank_code]) { is_expected.to eq('800') }
      its([:account_number]) { is_expected.to eq('00820169143579630') }
    end
  end

  context 'with a Sparbanken Öresund clearing code' do
    let(:account_number) { '9300-35299478' }

    its([:bank_code]) { is_expected.to eq('930') }
    its([:account_number]) { is_expected.to eq('00000000035299478') }

    context 'with clearing number 9330 or above' do
      let(:account_number) { '9330-5930160535' }

      its([:bank_code]) { is_expected.to eq('933') }
      its([:account_number]) { is_expected.to eq('00000005930160535') }
    end
  end

  context 'with a Sparbanken Syd clearing code' do
    let(:account_number) { '9570-5250093407' }

    its([:bank_code]) { is_expected.to eq('957') }
    its([:account_number]) { is_expected.to eq('00000005250093407') }
  end

  context 'with a Handelsbanken clearing code' do
    let(:account_number) { '6000-806967498' }

    its([:bank_code]) { is_expected.to eq('600') }
    its([:account_number]) { is_expected.to eq('00000000806967498') }

    context 'that has clearing code 6240' do
      let(:account_number) { '6240-219161038' }

      its([:bank_code]) { is_expected.to eq('600') }
      its([:account_number]) { is_expected.to eq('00000000219161038') }
    end
  end

  context 'with a Nordea PlusGirot clearing code' do
    let(:account_number) { '9960-3401258276' }

    its([:bank_code]) { is_expected.to eq('950') }
    its([:account_number]) { is_expected.to eq('00099603401258276') }
  end
end
