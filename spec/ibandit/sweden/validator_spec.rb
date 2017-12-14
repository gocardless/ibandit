require "spec_helper"

describe Ibandit::Sweden::Validator do
  describe ".bank_code_exists_for_clearing_code?" do
    subject do
      described_class.bank_code_exists_for_clearing_code?(clearing_code)
    end

    context "without a clearing code" do
      let(:clearing_code) { nil }
      it { is_expected.to eq(false) }
    end

    context "with an impossible clearing code" do
      let(:clearing_code) { "1001" }
      it { is_expected.to eq(false) }
    end

    context "with a possible clearing code" do
      let(:clearing_code) { "1101" }
      it { is_expected.to eq(true) }
    end
  end

  describe ".valid_clearing_code_length?" do
    subject { described_class.valid_clearing_code_length?(clearing_code) }

    context "without a clearing code" do
      let(:clearing_code) { nil }
      it { is_expected.to eq(nil) }
    end

    context "with an impossible clearing code" do
      let(:clearing_code) { "1001" }
      it { is_expected.to eq(nil) }
    end

    context "with a correct length 4-digit clearing code" do
      let(:clearing_code) { "1101" }
      it { is_expected.to eq(true) }
    end

    context "with a correct length 5-digit clearing code" do
      let(:clearing_code) { "80001" }
      it { is_expected.to eq(true) }
    end

    context "with an incorrect length 5-digit clearing code" do
      let(:clearing_code) { "40001" }
      it { is_expected.to eq(false) }
    end
  end

  describe ".valid_serial_number_length?" do
    subject do
      described_class.valid_serial_number_length?(clearing_code: clearing_code,
                                                  serial_number: serial_number)
    end

    context "without a clearing code" do
      let(:clearing_code) { nil }
      let(:serial_number) { "1234567" }
      it { is_expected.to eq(nil) }
    end

    context "with an impossible clearing code" do
      let(:clearing_code) { "1001" }
      let(:serial_number) { "1234567" }
      it { is_expected.to eq(nil) }
    end

    context "with a correct length serial number" do
      let(:clearing_code) { "1101" }
      let(:serial_number) { "1234567" }
      it { is_expected.to eq(true) }
    end

    context "with an incorrect length serial number" do
      let(:clearing_code) { "1101" }
      let(:serial_number) { "123456" }
      it { is_expected.to eq(false) }
    end

    context "with a short serial number for a clearing code that zerofills" do
      let(:clearing_code) { "9960" }
      let(:serial_number) { "123456" }
      it { is_expected.to eq(true) }
    end

    context "with a long serial number for a clearing code that zerofills" do
      let(:clearing_code) { "9960" }
      let(:serial_number) { "12345678901" }
      it { is_expected.to eq(false) }
    end

    context "without a serial number" do
      let(:clearing_code) { "9960" }
      let(:serial_number) { nil }
      it { is_expected.to eq(false) }
    end
  end

  describe ".bank_code_exists?" do
    subject { described_class.bank_code_exists?(bank_code) }

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(false) }
    end

    context "with an impossible bank code" do
      let(:bank_code) { "123" }
      it { is_expected.to eq(false) }
    end

    context "with a possible bank code" do
      let(:bank_code) { "120" }
      it { is_expected.to eq(true) }
    end
  end

  describe ".bank_code_possible_for_account_number?" do
    subject do
      described_class.bank_code_possible_for_account_number?(
        bank_code: bank_code,
        account_number: account_number,
      )
    end

    context "without a bank code" do
      let(:account_number) { "12810105723" }
      let(:bank_code) { nil }
      it { is_expected.to eq(nil) }
    end

    context "with an impossible bank code" do
      let(:account_number) { "12810105723" }
      let(:bank_code) { "500" }
      it { is_expected.to eq(false) }
    end

    context "with a possible bank code" do
      let(:account_number) { "12810105723" }
      let(:bank_code) { "120" }
      it { is_expected.to eq(true) }
    end
  end

  describe ".account_number_length_valid_for_bank_code?" do
    subject do
      described_class.account_number_length_valid_for_bank_code?(
        bank_code: bank_code,
        account_number: account_number,
      )
    end

    context "without a bank code" do
      let(:account_number) { "12810105723" }
      let(:bank_code) { nil }
      it { is_expected.to eq(nil) }
    end

    context "with an impossible bank code" do
      let(:account_number) { "12810105723" }
      let(:bank_code) { "500" }
      it { is_expected.to eq(nil) }
    end

    context "with a normal type-1 account number" do
      let(:account_number) { "00000054391024039" }
      let(:bank_code) { "500" }
      it { is_expected.to eq(true) }

      context "that has a 6 digit serial number" do
        let(:account_number) { "00000005439102403" }
        let(:bank_code) { "500" }
        it { is_expected.to eq(false) }
      end

      context "that has an 8 digit serial number" do
        let(:account_number) { "00000543910240391" }
        let(:bank_code) { "500" }
        it { is_expected.to eq(false) }
      end
    end

    context "with a Danske bank account" do
      let(:account_number) { "12810105723" }
      let(:bank_code) { "120" }
      it { is_expected.to eq(true) }

      context "that has an 8 digit serial number" do
        let(:account_number) { "00000128101057231" }
        let(:bank_code) { "120" }
        it { is_expected.to eq(false) }
      end

      context "that has a 6 digit serial number" do
        let(:account_number) { "00000001281010572" }
        let(:bank_code) { "120" }
        # This passes because it could be a 10 digit account number from the
        # clearing code range 9180-9189.
        it { is_expected.to eq(true) }
      end
    end

    context "with a Handelsbanken account number" do
      let(:bank_code) { "600" }
      let(:account_number) { "00000000219161038" }
      it { is_expected.to eq(true) }

      context "that is only 8 characters long" do
        let(:account_number) { "00000000021916103" }
        it { is_expected.to eq(true) }
      end

      context "that is 10 characters long" do
        let(:account_number) { "00000002191610381" }
        it { is_expected.to eq(false) }
      end
    end

    context "without a Nordea PlusGirot account number" do
      let(:bank_code) { "950" }
      let(:account_number) { "00099603401258276" }
      it { is_expected.to eq(true) }
    end
  end
end
