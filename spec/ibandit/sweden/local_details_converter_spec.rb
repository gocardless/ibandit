# frozen_string_literal: true

require "spec_helper"

describe Ibandit::Sweden::LocalDetailsConverter do
  subject(:converter) do
    described_class.new(account_number: account_number,
                        branch_code: branch_code)
  end

  let(:branch_code) { nil }

  describe ".convert" do
    subject { converter.convert }

    context "with a type-1 account number" do
      let(:account_number) { "12810105723" }

      its([:account_number]) { is_expected.to eq("0105723") }
      its([:branch_code]) { is_expected.to eq("1281") }
      its([:swift_bank_code]) { is_expected.to eq("120") }
      its([:swift_account_number]) { is_expected.to eq("00000012810105723") }

      context "that includes hyphens" do
        let(:account_number) { "1281-0105723" }

        its([:account_number]) { is_expected.to eq("0105723") }
        its([:branch_code]) { is_expected.to eq("1281") }
        its([:swift_bank_code]) { is_expected.to eq("120") }
        its([:swift_account_number]) { is_expected.to eq("00000012810105723") }
      end

      context "with a separate branch code" do
        let(:branch_code) { "1281" }
        let(:account_number) { "0105723" }

        its([:account_number]) { is_expected.to eq("0105723") }
        its([:branch_code]) { is_expected.to eq("1281") }
        its([:swift_bank_code]) { is_expected.to eq("120") }
        its([:swift_account_number]) { is_expected.to eq("00000012810105723") }
      end

      context "that includes spaces" do
        let(:account_number) { "1281 0105723" }

        its([:account_number]) { is_expected.to eq("0105723") }
        its([:branch_code]) { is_expected.to eq("1281") }
        its([:swift_bank_code]) { is_expected.to eq("120") }
        its([:swift_account_number]) { is_expected.to eq("00000012810105723") }
      end

      context "that includes full stops" do
        let(:account_number) { "1281.010.572.3" }

        its([:account_number]) { is_expected.to eq("0105723") }
        its([:branch_code]) { is_expected.to eq("1281") }
        its([:swift_bank_code]) { is_expected.to eq("120") }
        its([:swift_account_number]) { is_expected.to eq("00000012810105723") }
      end

      context "that needs the account number part to be zero-padded" do
        let(:account_number) { "1281-1" }

        its([:account_number]) { is_expected.to eq("1") }
        its([:branch_code]) { is_expected.to eq("1281") }
        its([:swift_bank_code]) { is_expected.to eq("120") }
        its([:swift_account_number]) { is_expected.to eq("00000000000012811") }
      end

      context "from SEB" do
        let(:account_number) { "5439-10 240 39" }

        its([:account_number]) { is_expected.to eq("1024039") }
        its([:branch_code]) { is_expected.to eq("5439") }
        its([:swift_bank_code]) { is_expected.to eq("500") }
        its([:swift_account_number]) { is_expected.to eq("00000054391024039") }

        context "with a separate branch code" do
          let(:branch_code) { "5439" }
          let(:account_number) { "1024039" }

          its([:account_number]) { is_expected.to eq("1024039") }
          its([:branch_code]) { is_expected.to eq("5439") }
          its([:swift_bank_code]) { is_expected.to eq("500") }

          its([:swift_account_number]) do
            is_expected.to eq("00000054391024039")
          end
        end
      end
    end

    context "with a clearing code that doesn't match any banks" do
      let(:account_number) { "1001-1" }

      its([:account_number]) { is_expected.to eq(nil) }
      its([:branch_code]) { is_expected.to eq(nil) }
      its([:swift_bank_code]) { is_expected.to eq(nil) }
      its([:swift_account_number]) { is_expected.to eq("00000000000010011") }
    end

    context "with a Swedbank clearing code" do
      let(:account_number) { "7507-1211203" }

      its([:account_number]) { is_expected.to eq("1211203") }
      its([:branch_code]) { is_expected.to eq("7507") }
      its([:swift_bank_code]) { is_expected.to eq("800") }
      its([:swift_account_number]) { is_expected.to eq("00000075071211203") }

      context "in the 8000s range" do
        let(:account_number) { "8327-9 33395390-9" }

        its([:account_number]) { is_expected.to eq("0333953909") }
        its([:branch_code]) { is_expected.to eq("83279") }
        its([:swift_bank_code]) { is_expected.to eq("800") }
        its([:swift_account_number]) { is_expected.to eq("00832790333953909") }
      end

      context "another in the 8000s range" do
        let(:account_number) { "8201-6 914357963-0" }

        its([:account_number]) { is_expected.to eq("9143579630") }
        its([:branch_code]) { is_expected.to eq("82016") }
        its([:swift_bank_code]) { is_expected.to eq("800") }
        its([:swift_account_number]) { is_expected.to eq("00820169143579630") }
      end

      context "with an explicit branch code" do
        let(:branch_code) { "8201-6" }
        let(:account_number) { "914357963-0" }

        its([:account_number]) { is_expected.to eq("9143579630") }
        its([:branch_code]) { is_expected.to eq("82016") }
        its([:swift_bank_code]) { is_expected.to eq("800") }
        its([:swift_account_number]) { is_expected.to eq("00820169143579630") }
      end

      context "in the 8000s range, with a very short input" do
        let(:account_number) { "8004" }
        let(:branch_code) { nil }

        its([:account_number]) { is_expected.to be_nil }
        its([:branch_code]) { is_expected.to eq("8004") }
        its([:swift_bank_code]) { is_expected.to eq("800") }
        its([:swift_account_number]) { is_expected.to be_nil }
      end
    end

    context "with a Sparbanken Öresund clearing code" do
      let(:account_number) { "9300-35299478" }

      its([:account_number]) { is_expected.to eq("35299478") }
      its([:branch_code]) { is_expected.to eq("9300") }
      its([:swift_bank_code]) { is_expected.to eq("930") }
      its([:swift_account_number]) { is_expected.to eq("00000000035299478") }

      context "with clearing number 9330 or above" do
        let(:account_number) { "9330-5930160535" }

        its([:account_number]) { is_expected.to eq("5930160535") }
        its([:branch_code]) { is_expected.to eq("9330") }
        its([:swift_bank_code]) { is_expected.to eq("933") }
        its([:swift_account_number]) { is_expected.to eq("00000005930160535") }
      end
    end

    context "with a Sparbanken Syd clearing code" do
      let(:account_number) { "9570-5250093407" }

      its([:account_number]) { is_expected.to eq("5250093407") }
      its([:branch_code]) { is_expected.to eq("9570") }
      its([:swift_bank_code]) { is_expected.to eq("957") }
      its([:swift_account_number]) { is_expected.to eq("00000005250093407") }
    end

    context "with a Handelsbanken clearing code" do
      let(:account_number) { "6000-806967498" }

      its([:account_number]) { is_expected.to eq("806967498") }
      its([:branch_code]) { is_expected.to eq("6000") }
      its([:swift_bank_code]) { is_expected.to eq("600") }
      its([:swift_account_number]) { is_expected.to eq("00000000806967498") }

      context "that has clearing code 6240" do
        let(:account_number) { "6240-219161038" }

        its([:account_number]) { is_expected.to eq("219161038") }
        its([:branch_code]) { is_expected.to eq("6240") }
        its([:swift_bank_code]) { is_expected.to eq("600") }
        its([:swift_account_number]) { is_expected.to eq("00000000219161038") }
      end

      context "that only has an 8 digit serial number" do
        let(:account_number) { "6240-21916103" }

        its([:account_number]) { is_expected.to eq("021916103") }
        its([:branch_code]) { is_expected.to eq("6240") }
        its([:swift_bank_code]) { is_expected.to eq("600") }
        its([:swift_account_number]) { is_expected.to eq("00000000021916103") }
      end
    end

    context "with a Nordea PlusGirot clearing code" do
      let(:account_number) { "9960-3401258276" }

      its([:account_number]) { is_expected.to eq("3401258276") }
      its([:branch_code]) { is_expected.to eq("9960") }
      its([:swift_bank_code]) { is_expected.to eq("950") }
      its([:swift_account_number]) { is_expected.to eq("00099603401258276") }
    end
  end
end
