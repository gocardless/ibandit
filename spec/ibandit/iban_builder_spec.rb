require 'spec_helper'

describe Ibandit::IBANBuilder do
  describe '.build' do
    subject(:build) { described_class.build(args) }
    let(:args) { { country_code: 'ES' } }

    context 'without a country_code' do
      let(:args) { { bank_code: 1 } }

      it 'raises a helpful error message' do
        expect { build }.to raise_error(ArgumentError, /provide a country_code/)
      end
    end

    context 'with an unsupported country_code' do
      let(:args) { { country_code: 'FU' } }

      it 'raises a helpful error message' do
        expect { build }.to raise_error(ArgumentError, /Don't know how/)
      end
    end

    context 'with AT as the country_code' do
      let(:args) do
        {
          country_code: 'AT',
          account_number: '00234573201',
          bank_code: '19043'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('AT611904300234573201') }
      end

      context "with an account number that hasn't been zero-padded" do
        before { args[:account_number] = '234573201' }

        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('AT611904300234573201') }
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end

      context 'without an bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end
    end

    context 'with BE as the country_code' do
      let(:args) do
        {
          country_code: 'BE',
          account_number: '510007547061'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('BE62510007547061') }
      end

      context 'with dashes' do
        before { args[:account_number] = '510-0075470-61' }

        describe 'it strips the dashes out' do
          it { is_expected.to be_a(Ibandit::IBAN) }
          its(:iban) { is_expected.to eq('BE62510007547061') }
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with CY as the country_code' do
      let(:args) do
        {
          country_code: 'CY',
          account_number: '0000001200527600',
          bank_code: '002',
          branch_code: '00128'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('CY17002001280000001200527600') }
      end

      context "with an account number that hasn't been zero-padded" do
        before { args[:account_number] = '1200527600' }

        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('CY17002001280000001200527600') }
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end

      context 'without an bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without an branch_code' do
        before { args.delete(:branch_code) }

        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('CY040020000001200527600') }
      end
    end

    context 'with DE as the country_code' do
      let(:args) do
        { country_code: 'DE',
          bank_code: '37040044',
          account_number: '0532013000' }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('DE89370400440532013000') }
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        specify do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        specify do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with EE as the country_code' do
      let(:args) { { country_code: 'EE', account_number: '0221020145685' } }

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('EE382200221020145685') }
      end

      context 'with an account number that needs translating' do
        before { args[:account_number] = '111020145685' }

        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('EE412200111020145685') }
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with ES as the country_code' do
      let(:args) do
        {
          country_code: 'ES',
          bank_code: '2310',
          branch_code: '0001',
          account_number: '0000012345'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('ES8023100001180000012345') }
      end

      context 'with an account number that needs to be zero-padded' do
        before { args[:account_number] = '12345' }

        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('ES8023100001180000012345') }
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without a branch_code' do
        before { args.delete(:branch_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with FI as the country_code' do
      let(:args) { { country_code: 'FI', account_number: '123456-785' } }

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('FI2112345600000785') }
      end

      context 'with an electronic format account_number' do
        before { args[:account_number] = '12345600000785' }

        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('FI2112345600000785') }
      end

      context 'with a savings bank account_number in traditional format' do
        before { args[:account_number] = '423456-78510' }

        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('FI3442345670008510') }
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with FR as the country_code' do
      let(:args) do
        {
          country_code: 'FR',
          bank_code: '20041',
          branch_code: '01005',
          account_number: '0500013M026'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('FR1420041010050500013M02606') }
      end

      context 'with a rib_key' do
        before { args[:rib_key] = '00' }
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('FR7920041010050500013M02600') }
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without a branch_code' do
        before { args.delete(:branch_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with IE as the country_code' do
      let(:args) do
        {
          country_code: 'IE',
          bank_code: 'AIBK',
          branch_code: '931152',
          account_number: '12345678'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('IE29AIBK93115212345678') }
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without a branch_code' do
        before { args.delete(:branch_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with IT as the country_code' do
      let(:args) do
        {
          country_code: 'IT',
          bank_code: '05428',
          branch_code: '11101',
          account_number: '000000123456'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('IT60X0542811101000000123456') }
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without a branch_code' do
        before { args.delete(:branch_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with LU as the country_code' do
      let(:args) do
        {
          country_code: 'LU',
          account_number: '1234567890123',
          bank_code: 'BANK'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('LU75BANK1234567890123') }
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end
    end

    context 'with LV as the country_code' do
      let(:args) do
        {
          country_code: 'LV',
          account_number: '1234567890123',
          bank_code: 'BANK'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('LV72BANK1234567890123') }
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end
    end

    context 'with MC as the country_code' do
      let(:args) do
        {
          country_code: 'MC',
          bank_code: '20041',
          branch_code: '01005',
          account_number: '0500013M026'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('MC9320041010050500013M02606') }
      end

      context 'with a rib_key' do
        before { args[:rib_key] = '00' }
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('MC6120041010050500013M02600') }
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without a branch_code' do
        before { args.delete(:branch_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with PT as the country_code' do
      let(:args) do
        {
          country_code: 'PT',
          bank_code: '0002',
          branch_code: '0023',
          account_number: '00238430005'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('PT50000200230023843000578') }
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without a branch_code' do
        before { args.delete(:branch_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with SI as the country_code' do
      let(:args) do
        {
          country_code: 'SI',
          bank_code: '19100',
          account_number: '00001234'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('SI56191000000123438') }
      end

      context 'with an account number that needs padding' do
        before { args[:account_number] = '1234' }

        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('SI56191000000123438') }
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with SK as the country_code' do
      let(:args) do
        {
          country_code: 'SK',
          bank_code: '1200',
          account_number_prefix: '000019',
          account_number: '8742637541'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('SK3112000000198742637541') }
      end

      context 'with an account number prefix that needs padding' do
        before { args[:account_number_prefix] = '19' }

        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('SK3112000000198742637541') }
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end

      context 'without an account_number_prefix' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context 'with SM as the country_code' do
      let(:args) do
        {
          country_code: 'SM',
          bank_code: '05428',
          branch_code: '11101',
          account_number: '000000123456'
        }
      end

      context 'with valid arguments' do
        it { is_expected.to be_a(Ibandit::IBAN) }
        its(:iban) { is_expected.to eq('SM88X0542811101000000123456') }
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context 'without a branch_code' do
        before { args.delete(:branch_code) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        it 'raises a helpful error message' do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end
  end

  describe '.estonian_check_digit' do
    subject { described_class.estonian_check_digit(account_number) }

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

  describe '.slovakian_prefix_check_digit' do
    subject { described_class.slovakian_prefix_check_digit(account_number) }

    let(:account_number) { '00001' }
    it { is_expected.to eq('9') }

    context 'with a non-numeric character' do
      let(:account_number) { '1BAD2014' }
      specify { expect { subject }.to raise_error(/non-numeric character/) }
    end
  end

  describe '.slovakian_basic_check_digit' do
    subject { described_class.slovakian_basic_check_digit(account_number) }

    let(:account_number) { '874263754' }
    it { is_expected.to eq('1') }

    context 'with a non-numeric character' do
      let(:account_number) { '1BAD2014' }
      specify { expect { subject }.to raise_error(/non-numeric character/) }
    end
  end

  describe '.lund_check_digit' do
    subject { described_class.lund_check_digit(account_number) }

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
end
