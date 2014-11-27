require 'spec_helper'

describe IBAN::IBAN do
  subject(:iban) { described_class.new(iban_code) }
  let(:iban_code) { "GB82WEST12345698765432" }

  its(:iban) { is_expected.to eq(iban_code) }

  context "with a poorly formatted IBAN" do
    let(:iban_code) { "  gb82 WeSt 1234 5698 7654 32\n" }
    its(:iban) { is_expected.to eq("GB82WEST12345698765432") }
  end

  describe "it decomposes the IBAN" do
    its(:country_code) { is_expected.to eq("GB") }
    its(:check_digits) { is_expected.to eq("82") }
    its(:bank_code) { is_expected.to eq("WEST") }
    its(:branch_code) { is_expected.to eq("123456") }
    its(:account_number) { is_expected.to eq("98765432") }
    its(:iban_national_id) { is_expected.to eq("WEST123456") }
  end

  describe "#pretty" do
    subject { iban.pretty }
    it { is_expected.to eq("GB82 WEST 1234 5698 7654 32")}
  end

  ###############
  # Validations #
  ###############

  describe "#valid_country_code?" do
    subject { iban.valid_country_code? }

    context "with valid details" do
      it { is_expected.to eq(true) }

      it "clears errors on the IBAN" do
        iban.instance_variable_set(:@errors, country_code: "error!")
        iban.valid_country_code?
        expect(iban.errors).to_not include(:country_code)
      end
    end

    context "with an unknown country code" do
      let(:iban_code) { "AA123456789123456" }
      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_country_code?
        expect(iban.errors).to include(:country_code)
      end
    end
  end

  describe "#valid_check_digits?" do
    subject { iban.valid_check_digits? }

    context "with valid details" do
      let(:iban_code) { "GB82WEST12345698765432" }
      it { is_expected.to eq(true) }

      it "clears errors on the IBAN" do
        iban.instance_variable_set(:@errors, check_digits: "error!")
        iban.valid_check_digits?
        expect(iban.errors).to_not include(:check_digits)
      end

      context "where the check digit is zero-padded" do
        let(:iban_code) { "GB06WEST12345698765442" }
        it { is_expected.to eq(true) }
      end
    end

    context "with invalid details" do
      let(:iban_code) { "GB12WEST12345698765432" }
      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_check_digits?
        expect(iban.errors).to include(:check_digits)
      end
    end

    context "with invalid characters" do
      let(:iban_code) { "AA82-EST123456987654" }
      it { is_expected.to be_nil }

      it "does not set errors on the IBAN" do
        iban.valid_check_digits?
        expect(iban.errors).to_not include(:check_digits)
      end
    end
  end

  describe "#valid_length?" do
    subject { iban.valid_length? }

    context "with valid details" do
      let(:iban_code) { "GB82WEST12345698765432" }
      it { is_expected.to eq(true) }

      it "clears errors on the IBAN" do
        iban.instance_variable_set(:@errors, length: "error!")
        iban.valid_length?
        expect(iban.errors).to_not include(:length)
      end
    end

    context "with invalid details" do
      let(:iban_code) { "GB82WEST123456987654" }
      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_length?
        expect(iban.errors).to include(:length)
      end
    end

    context "with an invalid country_code" do
      let(:iban_code) { "AA82WEST123456987654" }
      it { is_expected.to be_nil }

      it "does not set errors on the IBAN" do
        iban.valid_length?
        expect(iban.errors).to_not include(:length)
      end
    end
  end

  describe "#valid_characters?" do
    subject { iban.valid_characters? }

    context "with valid details" do
      let(:iban_code) { "GB82WEST12345698765432" }
      it { is_expected.to eq(true) }

      it "clears errors on the IBAN" do
        iban.instance_variable_set(:@errors, characters: "error!")
        iban.valid_characters?
        expect(iban.errors).to_not include(:characters)
      end
    end

    context "with invalid details" do
      let(:iban_code) { "GB-123ABCD" }
      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_characters?
        expect(iban.errors).to include(:characters)
      end
    end
  end

  describe "#valid?" do
    after { iban.valid? }

    specify { expect(iban).to receive(:valid_country_code?).at_least(1) }
    specify { expect(iban).to receive(:valid_characters?).at_least(1) }
    specify { expect(iban).to receive(:valid_check_digits?).at_least(1) }
    specify { expect(iban).to receive(:valid_length?).at_least(1) }
  end
end
