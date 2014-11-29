require 'spec_helper'

describe IBAN::IBANBuilder do
  describe ".build" do
    subject(:build) { described_class.build(args) }
    let(:args) { { country_code: "ES" } }

    context "without a country_code" do
      let(:args) { { bank_code: 1 } }

      it "raises a helpful error message" do
        expect { build }.to raise_error(ArgumentError, /provide a country_code/)
      end
    end

    context "with an unsupported country_code" do
      let(:args) { { country_code: 'FU' } }

      it "raises a helpful error message" do
        expect { build }.to raise_error(ArgumentError, /Don't know how/)
      end
    end

    context "with ES as the country_code" do
      let(:args) do
        {
          country_code: 'ES',
          bank_code: "2310",
          branch_code: '0001',
          account_number: '0000012345'
        }
      end

      context "with valid arguments" do
        it { is_expected.to be_a(IBAN::IBAN) }
        its(:iban) { is_expected.to eq("ES8023100001180000012345") }
      end

      context "without a bank_code" do
        before { args.delete(:bank_code) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context "without a branch_code" do
        before { args.delete(:branch_code) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context "without an account_number" do
        before { args.delete(:account_number) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context "with IT as the country_code" do
      let(:args) do
        {
          country_code: 'IT',
          bank_code: "05428",
          branch_code: '11101',
          account_number: '000000123456'
        }
      end

      context "with valid arguments" do
        it { is_expected.to be_a(IBAN::IBAN) }
        its(:iban) { is_expected.to eq("IT60X0542811101000000123456") }
      end

      context "without a bank_code" do
        before { args.delete(:bank_code) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context "without a branch_code" do
        before { args.delete(:branch_code) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context "without an account_number" do
        before { args.delete(:account_number) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context "with FR as the country_code" do
      let(:args) do
        {
          country_code: 'FR',
          bank_code: "20041",
          branch_code: '01005',
          account_number: '0500013M026'
        }
      end

      context "with valid arguments" do
        it { is_expected.to be_a(IBAN::IBAN) }
        its(:iban) { is_expected.to eq("FR1420041010050500013M02606") }
      end

      context "with a rib_key" do
        before { args[:rib_key] = "00" }
        it { is_expected.to be_a(IBAN::IBAN) }
        its(:iban) { is_expected.to eq("FR7920041010050500013M02600") }
      end

      context "without a bank_code" do
        before { args.delete(:bank_code) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context "without a branch_code" do
        before { args.delete(:branch_code) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context "without an account_number" do
        before { args.delete(:account_number) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context "with MC as the country_code" do
      let(:args) do
        {
          country_code: 'MC',
          bank_code: "20041",
          branch_code: '01005',
          account_number: '0500013M026'
        }
      end

      context "with valid arguments" do
        it { is_expected.to be_a(IBAN::IBAN) }
        its(:iban) { is_expected.to eq("MC9320041010050500013M02606") }
      end

      context "with a rib_key" do
        before { args[:rib_key] = "00" }
        it { is_expected.to be_a(IBAN::IBAN) }
        its(:iban) { is_expected.to eq("MC6120041010050500013M02600") }
      end

      context "without a bank_code" do
        before { args.delete(:bank_code) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context "without a branch_code" do
        before { args.delete(:branch_code) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context "without an account_number" do
        before { args.delete(:account_number) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end

    context "with PT as the country_code" do
      let(:args) do
        {
          country_code: 'PT',
          bank_code: '0002',
          branch_code: '0023',
          account_number: '00238430005'
        }
      end

      context "with valid arguments" do
        it { is_expected.to be_a(IBAN::IBAN) }
        its(:iban) { is_expected.to eq("PT50000200230023843000578") }
      end

      context "without a bank_code" do
        before { args.delete(:bank_code) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /bank_code is a required field/)
        end
      end

      context "without a branch_code" do
        before { args.delete(:branch_code) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /branch_code is a required field/)
        end
      end

      context "without an account_number" do
        before { args.delete(:account_number) }

        it "raises a helpful error message" do
          expect { build }.
            to raise_error(ArgumentError, /account_number is a required field/)
        end
      end
    end
  end
end
