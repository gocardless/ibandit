require 'spec_helper'

describe Ibandit::IBANBuilder do
  shared_examples_for 'allows round trips' do |iban_code|
    let(:iban) { Ibandit::IBAN.new(iban_code) }
    let(:args) do
      {
        country_code: iban.country_code,
        account_number: iban.account_number,
        branch_code: iban.branch_code,
        bank_code: iban.bank_code
      }
    end

    it 'successfully reconstructs the IBAN' do
      expect(described_class.build(args).iban).to eq(iban.iban)
    end
  end

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
        expect { build }.to raise_error(Ibandit::UnsupportedCountryError)
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

      its(:iban) { is_expected.to eq('AT611904300234573201') }

      it_behaves_like 'allows round trips', 'AT61 1904 3002 3457 3201'

      context "with an account number that hasn't been zero-padded" do
        before { args[:account_number] = '234573201' }
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
      let(:args) { { country_code: 'BE', account_number: '510007547061' } }

      its(:iban) { is_expected.to eq('BE62510007547061') }

      it_behaves_like 'allows round trips', 'BE62 5100 0754 7061'

      context 'with dashes' do
        before { args[:account_number] = '510-0075470-61' }
        its(:iban) { is_expected.to eq('BE62510007547061') }
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

      its(:iban) { is_expected.to eq('CY17002001280000001200527600') }

      it_behaves_like 'allows round trips', 'CY17 0020 0128 0000 0012 0052 7600'

      context "with an account number that hasn't been zero-padded" do
        before { args[:account_number] = '1200527600' }
        its(:iban) { is_expected.to eq('CY17002001280000001200527600') }
      end

      context 'without an branch_code' do
        before { args.delete(:branch_code) }
        its(:iban) { is_expected.to eq('CY040020000001200527600') }
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

    context 'with DE as the country_code' do
      let(:args) do
        { country_code: 'DE',
          bank_code: '37040044',
          account_number: '0532013000' }
      end

      its(:iban) { is_expected.to eq('DE89370400440532013000') }

      it_behaves_like 'allows round trips', 'DE89 3704 0044 0532 0130 00'

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

      context 'with a pseudo account number' do
        before { args[:bank_code] = '37080040' }
        before { args[:account_number] = '111' }

        its(:iban) { is_expected.to eq('DE69370800400215022000') }
      end
    end

    context 'with EE as the country_code' do
      let(:args) { { country_code: 'EE', account_number: '0221020145685' } }

      its(:iban) { is_expected.to eq('EE382200221020145685') }

      it_behaves_like 'allows round trips', 'EE38 2200 2210 2014 5685'

      context 'with an account number that needs translating' do
        before { args[:account_number] = '111020145685' }
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
          account_number: '180000012345'
        }
      end

      its(:iban) { is_expected.to eq('ES8023100001180000012345') }

      it_behaves_like 'allows round trips', 'ES80 2310 0001 1800 0001 2345'

      context 'without a bank_code or branch code' do
        before { args.delete(:bank_code) }
        before { args.delete(:branch_code) }
        before { args[:account_number] = '23100001180000012345' }

        its(:iban) { is_expected.to eq('ES8023100001180000012345') }
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
      let(:args) do
        { country_code: 'FI', bank_code: '123456', account_number: '785' }
      end

      its(:iban) { is_expected.to eq('FI2112345600000785') }

      it_behaves_like 'allows round trips', 'FI21 1234 5600 0007 85'

      context 'with a savings bank account_number in traditional format' do
        before { args[:account_number] = '78510' }
        before { args[:bank_code] = '423456' }

        its(:iban) { is_expected.to eq('FI3442345670008510') }
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

    context 'with FR as the country_code' do
      let(:args) do
        {
          country_code: 'FR',
          bank_code: '20041',
          branch_code: '01005',
          account_number: '0500013M02606'
        }
      end

      its(:iban) { is_expected.to eq('FR1420041010050500013M02606') }

      it_behaves_like 'allows round trips', 'FR14 2004 1010 0505 0001 3M02 606'

      context 'without the rib key in the account number' do
        before { args[:account_number] = '0500013M026' }
        its(:valid?) { is_expected.to be_falsey }
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

    context 'with GB as the country_code' do
      let(:args) do
        { country_code: 'GB',
          bank_code: 'BARC',
          branch_code: '200000',
          account_number: '579135' }
      end

      its(:iban) { is_expected.to eq('GB07BARC20000000579135') }

      it_behaves_like 'allows round trips', 'GB07 BARC 2000 0000 5791 35'

      context 'when the sort code is hyphenated' do
        before { args[:branch_code] = '20-00-00' }
        its(:iban) { is_expected.to eq('GB07BARC20000000579135') }
      end

      context 'when the sort code is spaced' do
        before { args[:branch_code] = '20 00 00' }
        its(:iban) { is_expected.to eq('GB07BARC20000000579135') }
      end

      context 'when the account number is spaced' do
        before { args[:account_number] = '579 135' }
        its(:iban) { is_expected.to eq('GB07BARC20000000579135') }
      end

      context 'when the account number is hyphenated' do
        before { args[:account_number] = '5577-9911' }
        its(:iban) { is_expected.to eq('GB60BARC20000055779911') }
      end

      context 'with the bank_code supplied manually' do
        before { args.merge!(bank_code: 'BARC') }
        its(:iban) { is_expected.to eq('GB07BARC20000000579135') }
      end

      context 'without a branch_code' do
        before { args.delete(:branch_code) }

        specify do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context 'without an account_number' do
        before { args.delete(:account_number) }

        specify do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        context 'when a bic_finder is not defined' do
          specify do
            expect { build }.
              to raise_error(ArgumentError, /bank_code is a required field/)
          end
        end

        context 'with a bic_finder' do
          let(:bic_finder) { double }
          before do
            allow(bic_finder).to receive(:find).with('GB', '200000').
              and_return('BARCGB22XXX')
            Ibandit.bic_finder = ->(cc, id) { bic_finder.find(cc, id) }
          end
          after { Ibandit.bic_finder = nil }

          its(:iban) { is_expected.to eq('GB07BARC20000000579135') }

          context "when the BIC can't be found" do
            before { Ibandit.bic_finder = ->(_cc, _id) { nil } }

            it 'raises an Ibandit::BicNotFoundError' do
              expect { build }.to raise_error(Ibandit::BicNotFoundError)
            end
          end
        end
      end

      context 'with both a bank_code and a bic_finder' do
        let(:bic_finder) { double }
        before do
          allow(bic_finder).to receive(:find).with('GB', '200000').
            and_return('BANKGB22XXX')
          Ibandit.bic_finder = ->(cc, id) { bic_finder.find(cc, id) }
        end
        after { Ibandit.bic_finder = nil }

        it 'uses the explicitly provided bank_code' do
          expect(subject.iban).to eq('GB07BARC20000000579135')
        end
      end
    end

    context 'with IE as the country_code' do
      let(:args) do
        { country_code: 'IE',
          bank_code: 'AIBK',
          branch_code: '931152',
          account_number: '12345678' }
      end

      its(:iban) { is_expected.to eq('IE29AIBK93115212345678') }

      it_behaves_like 'allows round trips', 'IE29 AIBK 9311 5212 3456 78'

      context 'with hyphens in the sort code' do
        before { args[:branch_code] = '93-11-52' }
        its(:iban) { is_expected.to eq('IE29AIBK93115212345678') }
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

      context 'without a bank_code' do
        before { args.delete(:bank_code) }

        context 'when a bic_finder is not defined' do
          specify do
            expect { build }.
              to raise_error(ArgumentError, /bank_code is a required field/)
          end
        end

        context 'with a bic_finder' do
          let(:bic_finder) { double }
          before do
            allow(bic_finder).to receive(:find).with('IE', '931152').
              and_return('AIBK1234XXX')
            Ibandit.bic_finder = ->(cc, id) { bic_finder.find(cc, id) }
          end
          after { Ibandit.bic_finder = nil }

          its(:iban) { is_expected.to eq('IE29AIBK93115212345678') }

          context "when the BIC can't be found" do
            before { Ibandit.bic_finder = ->(_cc, _id) { nil } }

            it 'raises an Ibandit::BicNotFoundError' do
              expect { build }.to raise_error(Ibandit::BicNotFoundError)
            end
          end
        end
      end

      context 'with both a bank_code and a bic_finder' do
        let(:bic_finder) { double }
        before do
          allow(bic_finder).to receive(:find).with('IE', '931152').
            and_return('BANK1234XXX')
          Ibandit.bic_finder = ->(cc, id) { bic_finder.find(cc, id) }
        end
        after { Ibandit.bic_finder = nil }

        it 'uses the explicitly provided bank_code' do
          expect(subject.iban).to eq('IE29AIBK93115212345678')
        end
      end
    end

    context 'with IT as the country_code' do
      let(:args) do
        {
          country_code: 'IT',
          bank_code: '05428',
          branch_code: '11101',
          account_number: '0000123456'
        }
      end

      its(:iban) { is_expected.to eq('IT60X0542811101000000123456') }

      it_behaves_like 'allows round trips', 'IT60 X054 2811 1010 0000 0123 456'

      context 'with an explicitly passed check digit' do
        before { args[:check_digit] = 'Y' }
        its(:iban) { is_expected.to eq('IT64Y0542811101000000123456') }
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
          account_number: '9400644750000',
          bank_code: '001'
        }
      end

      its(:iban) { is_expected.to eq('LU280019400644750000') }

      it_behaves_like 'allows round trips', 'LU28 0019 4006 4475 0000'

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

      its(:iban) { is_expected.to eq('LV72BANK1234567890123') }

      it_behaves_like 'allows round trips', 'LV72 BANK 1234 5678 9012 3'

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
          account_number: '0500013M02606'
        }
      end

      its(:iban) { is_expected.to eq('MC9320041010050500013M02606') }

      it_behaves_like 'allows round trips', 'MC93 2004 1010 0505 0001 3M02 606'

      context 'without the rib key in the account number' do
        before { args[:account_number] = '0500013M026' }
        its(:valid?) { is_expected.to be_falsey }
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

    context 'with NL as the country_code' do
      let(:args) do
        {
          country_code: 'NL',
          account_number: '0417164300',
          bank_code: 'ABNA'
        }
      end

      its(:iban) { is_expected.to eq('NL91ABNA0417164300') }

      it_behaves_like 'allows round trips', 'NL91 ABNA 0417 1643 00'

      context "with an account number that hasn't been zero-padded" do
        before { args[:account_number] = '417164300' }
        its(:iban) { is_expected.to eq('NL91ABNA0417164300') }
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

    context 'with PT as the country_code' do
      let(:args) do
        {
          country_code: 'PT',
          bank_code: '0002',
          branch_code: '0023',
          account_number: '0023843000578'
        }
      end

      its(:iban) { is_expected.to eq('PT50000200230023843000578') }

      it_behaves_like 'allows round trips', 'PT50 0002 0023 0023 8430 0057 8'

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
          account_number: '0000123438'
        }
      end

      its(:iban) { is_expected.to eq('SI56191000000123438') }

      it_behaves_like 'allows round trips', 'SI56 1910 0000 0123 438'

      context 'with an account number that needs padding' do
        before { args[:account_number] = '123438' }
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

      its(:iban) { is_expected.to eq('SK3112000000198742637541') }

      it_behaves_like 'allows round trips', 'SK31 1200 0000 1987 4263 7541'

      context 'with an account number prefix that needs padding' do
        before { args[:account_number_prefix] = '19' }
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

      its(:iban) { is_expected.to eq('SM88X0542811101000000123456') }

      it_behaves_like 'allows round trips', 'SM88 X054 2811 1010 0000 0123 456'

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
end
