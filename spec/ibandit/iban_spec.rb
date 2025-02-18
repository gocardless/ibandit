# frozen_string_literal: true

require "spec_helper"

describe Ibandit::IBAN do
  subject(:iban) { described_class.new(arg) }

  let(:arg) { iban_code }
  let(:iban_code) { "GB82WEST12345698765432" }

  its(:iban) { is_expected.to eq(iban_code) }

  context "with locales" do
    all_keys = YAML.safe_load_file("config/locales/en.yml")["en"]["ibandit"].keys

    Ibandit::Constants::SUPPORTED_LOCALES.each do |locale|
      context "for #{locale}", locale: locale do
        all_keys.each do |error_key|
          it "has a translation for #{error_key}" do
            expect { Ibandit.translate(error_key) }.to_not raise_error
          end
        end
      end
    end
  end

  context "with a poorly formatted IBAN" do
    let(:iban_code) { "  gb82 WeSt 1234 5698 7654 32\n" }

    its(:iban) { is_expected.to eq("GB82WEST12345698765432") }
  end

  context "with nil" do
    let(:arg) { nil }

    specify { expect { iban }.to raise_error(TypeError) }
  end

  context "with an invalid pseudo IBAN" do
    let(:arg) { "dezzzz" }

    its(:iban) { is_expected.to eq("DEZZZZ") }
  end

  context "with local details" do
    let(:arg) do
      {
        country_code: "GB",
        bank_code: "WEST",
        branch_code: "123456",
        account_number: "98765432",
      }
    end

    its(:iban) { is_expected.to eq("GB82WEST12345698765432") }
  end

  context "with nil local details" do
    let(:arg) do
      {
        country_code: nil,
        bank_code: nil,
        branch_code: nil,
        account_number: nil,
      }
    end

    it { is_expected.to_not be_valid }
  end

  describe "it decomposes the IBAN" do
    its(:country_code) { is_expected.to eq("GB") }
    its(:check_digits) { is_expected.to eq("82") }
    its(:bank_code) { is_expected.to eq("WEST") }
    its(:branch_code) { is_expected.to eq("123456") }
    its(:account_number) { is_expected.to eq("98765432") }
    its(:account_number_suffix) { is_expected.to eq(nil) }
    its(:swift_bank_code) { is_expected.to eq("WEST") }
    its(:swift_branch_code) { is_expected.to eq("123456") }
    its(:swift_account_number) { is_expected.to eq("98765432") }
    its(:swift_national_id) { is_expected.to eq("WEST123456") }
    its(:local_check_digits) { is_expected.to be_nil }

    context "when the IBAN is blank" do
      let(:iban_code) { "" }

      its(:country_code) { is_expected.to be_nil }
      its(:check_digits) { is_expected.to be_nil }
      its(:bank_code) { is_expected.to be_nil }
      its(:branch_code) { is_expected.to be_nil }
      its(:account_number) { is_expected.to be_nil }
      its(:account_number_suffix) { is_expected.to be_nil }
      its(:swift_national_id) { is_expected.to be_nil }
      its(:bban) { is_expected.to be_nil }
      its(:local_check_digits) { is_expected.to be_nil }
    end

    context "when local details are not available" do
      let(:iban_code) { "SE2680000000075071211203" }

      its(:country_code) { is_expected.to eq("SE") }
      its(:check_digits) { is_expected.to eq("26") }
      its(:bank_code) { is_expected.to be_nil }
      its(:branch_code) { is_expected.to be_nil }
      its(:account_number) { is_expected.to be_nil }
      its(:account_number_suffix) { is_expected.to be_nil }
      its(:swift_bank_code) { is_expected.to eq("800") }
      its(:swift_branch_code) { is_expected.to be_nil }
      its(:swift_account_number) { is_expected.to eq("00000075071211203") }
      its(:swift_national_id) { is_expected.to eq("800") }
      its(:local_check_digits) { is_expected.to be_nil }
    end

    context "when the IBAN was created from a Slovenian IBAN" do
      let(:iban_code) { "SI56 1910 0000 0123 438" }

      its(:country_code) { is_expected.to eq("SI") }
      its(:bank_code) { is_expected.to eq("19100") }
      its(:branch_code) { is_expected.to be_nil }
      its(:account_number) { is_expected.to eq("0000123438") }
      its(:account_number_suffix) { is_expected.to be_nil }
      its(:swift_bank_code) { is_expected.to eq("19100") }
      its(:swift_branch_code) { is_expected.to be_nil }
      its(:swift_account_number) { is_expected.to eq("0000123438") }
      its(:swift_national_id) { is_expected.to eq("19100") }
      its(:local_check_digits) { is_expected.to be_nil }
    end

    context "when the IBAN was created from a Belgian IBAN" do
      let(:iban_code) { "BE68539007547034" }

      its(:country_code) { is_expected.to eq("BE") }
      its(:bank_code) { is_expected.to eq("539") }
      its(:branch_code) { is_expected.to be_nil }
      its(:account_number) { is_expected.to eq("539007547034") }
      its(:account_number_suffix) { is_expected.to be_nil }
      its(:swift_bank_code) { is_expected.to eq("539") }
      its(:swift_branch_code) { is_expected.to be_nil }
      its(:swift_account_number) { is_expected.to eq("539007547034") }
      its(:swift_national_id) { is_expected.to eq("539") }
      its(:local_check_digits) { is_expected.to eq("34") }
      its(:bban) { is_expected.to eq("539007547034") }
    end

    context "when the IBAN was created with local details" do
      let(:arg) do
        {
          country_code: "GB",
          bank_code: "WES",
          branch_code: "1234",
          account_number: "5678",
        }
      end

      its(:country_code) { is_expected.to eq(arg[:country_code]) }
      its(:bank_code) { is_expected.to eq(arg[:bank_code]) }
      its(:branch_code) { is_expected.to eq(arg[:branch_code]) }
      its(:account_number) { is_expected.to eq(arg[:account_number]) }
      its(:swift_bank_code) { is_expected.to eq(arg[:bank_code]) }
      its(:swift_branch_code) { is_expected.to eq(arg[:branch_code]) }
      its(:swift_account_number) { is_expected.to eq(arg[:account_number]) }
      its(:pseudo_iban) { is_expected.to be_nil }
      its(:iban) { is_expected.to eq("GB72WES12345678") }
      its(:to_s) { is_expected.to eq("GB72WES12345678") }
    end

    context "when the IBAN was created with local details for Sweden" do
      let(:arg) do
        {
          country_code: "SE",
          branch_code: "1281",
          account_number: "0105723",
        }
      end

      its(:country_code) { is_expected.to eq(arg[:country_code]) }
      its(:bank_code) { is_expected.to eq(arg[:bank_code]) }
      its(:branch_code) { is_expected.to eq(arg[:branch_code]) }
      its(:account_number) { is_expected.to eq(arg[:account_number]) }
      its(:swift_bank_code) { is_expected.to eq("120") }
      its(:swift_branch_code) { is_expected.to be_nil }
      its(:swift_account_number) { is_expected.to eq("00000012810105723") }
      its(:iban) { is_expected.to eq("SE5412000000012810105723") }
      its(:pseudo_iban) { is_expected.to eq("SEZZX1281XXX0105723") }
      its(:to_s) { is_expected.to eq("SE5412000000012810105723") }
      its(:valid?) { is_expected.to eq(true) }

      context "and the clearing code is not part of the IBAN" do
        context "and the branch code allows for zero-filling of short account numbers" do
          let(:arg) do
            {
              country_code: "SE",
              branch_code: "6000",
              account_number: "1234567",
            }
          end

          its(:country_code) { is_expected.to eq("SE") }
          its(:bank_code) { is_expected.to be_nil }
          its(:branch_code) { is_expected.to eq("6000") }
          its(:account_number) { is_expected.to eq("001234567") }
          its(:swift_bank_code) { is_expected.to eq("600") }
          its(:swift_branch_code) { is_expected.to be_nil }
          its(:swift_account_number) { is_expected.to eq("00000000001234567") }
          its(:iban) { is_expected.to eq("SE2260000000000001234567") }
          its(:pseudo_iban) { is_expected.to eq("SEZZX6000X001234567") }
          its(:to_s) { is_expected.to eq("SE2260000000000001234567") }
          its(:valid?) { is_expected.to eq(true) }
        end

        context "and the branch code does not allow for zero-filling of short account numbers" do
          let(:arg) do
            {
              country_code: "SE",
              branch_code: "3300",
              account_number: "1234567",
            }
          end

          its(:country_code) { is_expected.to eq("SE") }
          its(:bank_code) { is_expected.to be_nil }
          its(:branch_code) { is_expected.to eq("3300") }
          its(:account_number) { is_expected.to eq("1234567") }
          its(:swift_bank_code) { is_expected.to eq("300") }
          its(:swift_branch_code) { is_expected.to be_nil }
          its(:swift_account_number) { is_expected.to eq("00000000001234567") }
          its(:iban) { is_expected.to eq("SE4130000000000001234567") }
          its(:pseudo_iban) { is_expected.to eq("SEZZX3300XXX1234567") }
          its(:to_s) { is_expected.to eq("SE4130000000000001234567") }
          its(:valid?) { is_expected.to eq(false) }
        end
      end

      context "and the clearing code is part of the IBAN" do
        let(:arg) do
          {
            country_code: "SE",
            branch_code: "3410",
            account_number: "1234567",
          }
        end

        its(:country_code) { is_expected.to eq("SE") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("3410") }
        its(:account_number) { is_expected.to eq("1234567") }
        its(:swift_bank_code) { is_expected.to eq("300") }
        its(:swift_branch_code) { is_expected.to be_nil }
        its(:swift_account_number) { is_expected.to eq("00000034101234567") }
        its(:iban) { is_expected.to eq("SE1030000000034101234567") }
        its(:pseudo_iban) { is_expected.to eq("SEZZX3410XXX1234567") }
        its(:to_s) { is_expected.to eq("SE1030000000034101234567") }
        its(:valid?) { is_expected.to eq(true) }
      end
    end

    context "when the IBAN was created from a pseudo-IBAN" do
      let(:arg) { "SEZZX1281XXX0105723" }

      its(:country_code) { is_expected.to eq("SE") }
      its(:bank_code) { is_expected.to be_nil }
      its(:branch_code) { is_expected.to eq("1281") }
      its(:account_number) { is_expected.to eq("0105723") }
      its(:swift_bank_code) { is_expected.to eq("120") }
      its(:swift_branch_code) { is_expected.to be_nil }
      its(:swift_account_number) { is_expected.to eq("00000012810105723") }
      its(:iban) { is_expected.to eq("SE5412000000012810105723") }
      its(:pseudo_iban) { is_expected.to eq("SEZZX1281XXX0105723") }
      its(:to_s) { is_expected.to eq("SE5412000000012810105723") }
      its(:valid?) { is_expected.to eq(true) }
    end

    context "when the IBAN was created from a Swedish IBAN" do
      context "with check digits that make it look like a pseudo-IBAN" do
        let(:arg) { "SEZZ30000000031231234567" }

        its(:country_code) { is_expected.to eq("SE") }
        its(:valid?) { is_expected.to eq(false) }
      end

      context "where the clearing code is part of the account number" do
        let(:arg) { "SE4730000000031231234567" }

        its(:country_code) { is_expected.to eq("SE") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to be_nil }
        its(:account_number) { is_expected.to be_nil }
        its(:swift_bank_code) { is_expected.to eq("300") }
        its(:swift_branch_code) { is_expected.to be_nil }
        its(:swift_account_number) { is_expected.to eq("00000031231234567") }
        its(:iban) { is_expected.to eq("SE4730000000031231234567") }
        its(:pseudo_iban) { is_expected.to be_nil }
        its(:to_s) { is_expected.to eq("SE4730000000031231234567") }
        its(:valid?) { is_expected.to eq(true) }
      end

      context "where the clearing code is not part of the account number" do
        let(:arg) { "SE7160000000000123456789" }

        its(:country_code) { is_expected.to eq("SE") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to be_nil }
        its(:account_number) { is_expected.to be_nil }
        its(:swift_bank_code) { is_expected.to eq("600") }
        its(:swift_branch_code) { is_expected.to be_nil }
        its(:swift_account_number) { is_expected.to eq("00000000123456789") }
        its(:iban) { is_expected.to eq("SE7160000000000123456789") }
        its(:pseudo_iban) { is_expected.to be_nil }
        its(:to_s) { is_expected.to eq("SE7160000000000123456789") }
        its(:valid?) { is_expected.to eq(true) }
      end

      context "where the clearing code is 3300, and therefore the account number is the national ID" do
        context "where the person was born in the 1990s" do
          let(:arg) { "SE2130000000009308127392" }

          its(:country_code) { is_expected.to eq("SE") }
          its(:bank_code) { is_expected.to be_nil }
          its(:branch_code) { is_expected.to be_nil }
          its(:account_number) { is_expected.to be_nil }
          its(:swift_bank_code) { is_expected.to eq("300") }
          its(:swift_branch_code) { is_expected.to be_nil }
          its(:swift_account_number) { is_expected.to eq("00000009308127392") }
          its(:iban) { is_expected.to eq("SE2130000000009308127392") }
          its(:pseudo_iban) { is_expected.to be_nil }
          its(:to_s) { is_expected.to eq("SE2130000000009308127392") }
          its(:valid?) { is_expected.to eq(true) }
        end

        context "where the person was born in the 2000s" do
          let(:arg) { "SE9430000000000607274287" }

          its(:country_code) { is_expected.to eq("SE") }
          its(:bank_code) { is_expected.to be_nil }
          its(:branch_code) { is_expected.to be_nil }
          its(:account_number) { is_expected.to be_nil }
          its(:swift_bank_code) { is_expected.to eq("300") }
          its(:swift_branch_code) { is_expected.to be_nil }
          its(:swift_account_number) { is_expected.to eq("00000000607274287") }
          its(:iban) { is_expected.to eq("SE9430000000000607274287") }
          its(:pseudo_iban) { is_expected.to be_nil }
          its(:to_s) { is_expected.to eq("SE9430000000000607274287") }
          its(:valid?) { is_expected.to eq(true) }
        end

        context "where the person was born in the year 2000" do
          let(:arg) { "SE3830000000000007134937" }

          its(:country_code) { is_expected.to eq("SE") }
          its(:bank_code) { is_expected.to be_nil }
          its(:branch_code) { is_expected.to be_nil }
          its(:account_number) { is_expected.to be_nil }
          its(:swift_bank_code) { is_expected.to eq("300") }
          its(:swift_branch_code) { is_expected.to be_nil }
          its(:swift_account_number) { is_expected.to eq("00000000007134937") }
          its(:iban) { is_expected.to eq("SE3830000000000007134937") }
          its(:pseudo_iban) { is_expected.to be_nil }
          its(:to_s) { is_expected.to eq("SE3830000000000007134937") }
          its(:valid?) { is_expected.to eq(true) }
        end
      end
    end

    context "when the IBAN was created with local details for Australia" do
      let(:arg) do
        {
          country_code: "AU",
          branch_code: "123-456",
          account_number: account_number,
        }
      end

      context "and a 9 digit account number" do
        let(:account_number) { "123456789" }

        its(:country_code) { is_expected.to eq("AU") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("123456") }
        its(:account_number) { is_expected.to eq("123456789") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("123456789") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ123456_123456789") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 5 digit account number" do
        let(:account_number) { "12345" }

        its(:country_code) { is_expected.to eq("AU") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("123456") }
        its(:account_number) { is_expected.to eq("12345") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("12345") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ123456_____12345") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 6 digit account number" do
        let(:account_number) { "123456" }

        its(:country_code) { is_expected.to eq("AU") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("123456") }
        its(:account_number) { is_expected.to eq("123456") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("123456") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ123456____123456") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 10 characters account number" do
        let(:account_number) { "ABC1234567" }

        its(:country_code) { is_expected.to eq("AU") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("123456") }
        its(:account_number) { is_expected.to eq("ABC1234567") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("ABC1234567") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ123456ABC1234567") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 9 characters account number starting with X" do
        let(:account_number) { "XX1234567" }

        its(:country_code) { is_expected.to eq("AU") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("123456") }
        its(:account_number) { is_expected.to eq("XX1234567") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("XX1234567") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ123456_XX1234567") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 10 characters account number starting with X" do
        let(:account_number) { "XX12345678" }

        its(:country_code) { is_expected.to eq("AU") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("123456") }
        its(:account_number) { is_expected.to eq("XX12345678") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("XX12345678") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ123456XX12345678") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and an account number that is all zero" do
        let(:account_number) { "000000" }

        its(:country_code) { is_expected.to eq("AU") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("123456") }
        its(:account_number) { is_expected.to eq("000000") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("000000") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ123456____000000") }
        its(:valid?) { is_expected.to eq(false) }
        its(:to_s) { is_expected.to eq("") }
      end
    end

    context "when the IBAN was created from an Australian pseudo-IBAN" do
      let(:arg) { "AUZZ123456123456789" }

      its(:country_code) { is_expected.to eq("AU") }
      its(:bank_code) { is_expected.to be_nil }
      its(:branch_code) { is_expected.to eq("123456") }
      its(:account_number) { is_expected.to eq("123456789") }
      its(:swift_bank_code) { is_expected.to be_nil }
      its(:swift_branch_code) { is_expected.to eq("123456") }
      its(:swift_account_number) { is_expected.to eq("123456789") }
      its(:swift_national_id) { is_expected.to eq("123456") }
      its(:iban) { is_expected.to be_nil }
      its(:pseudo_iban) { is_expected.to eq("AUZZ123456_123456789") }
      its(:valid?) { is_expected.to eq(true) }
      its(:to_s) { is_expected.to eq("") }

      context "with a leading X on the account number" do
        let(:arg) { "AUZZ123456XABCD12345" }

        its(:country_code) { is_expected.to eq("AU") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("123456") }
        its(:account_number) { is_expected.to eq("XABCD12345") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("XABCD12345") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ123456XABCD12345") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end
    end

    context "when the input is an invalid Australian pseudo-IBAN" do
      let(:arg) { "AUZZ1234561234567899999" }

      its(:iban) { is_expected.to be_nil }
      its(:pseudo_iban) { is_expected.to eq(arg) }

      it "is invalid and has the correct errors" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors).
          to eq(account_number: "is the wrong length (should be 5..10 characters)")
      end
    end

    context "when the input is an account number too short for Australia" do
      let(:arg) do
        {
          country_code: "AU",
          branch_code: "123456",
          account_number: "1234",
        }
      end

      its(:iban) { is_expected.to be_nil }
      its(:pseudo_iban) { is_expected.to eq("AUZZ123456______1234") }

      it "is invalid and has the correct errors" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors).to eq(
          account_number: "is the wrong length (should be 5..10 characters)",
        )
      end
    end

    context "when the input is invalid local details for Australia" do
      let(:arg) do
        {
          country_code: "AU",
          branch_code: "123-4XX",
          account_number: "123456789:",
        }
      end

      its(:iban) { is_expected.to be_nil }
      its(:pseudo_iban) { is_expected.to eq("AUZZ1234XX123456789:") }

      it "is invalid and has the correct errors" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors).to eq(account_number: "format is invalid",
                                     branch_code: "format is invalid")
      end
    end

    context "when the IBAN was created with local details for Canada" do
      let(:arg) do
        {
          country_code: "CA",
          bank_code: bank_code,
          branch_code: branch_code,
          account_number: account_number,
        }
      end
      let(:branch_code) { "00063" }

      context "and a 5 digit branch code" do
        let(:account_number) { "0123456" }
        let(:bank_code) { "036" }
        let(:branch_code) { "00063" }

        its(:country_code) { is_expected.to eq("CA") }
        its(:bank_code) { is_expected.to eq("0036") }
        its(:branch_code) { is_expected.to eq("00063") }
        its(:account_number) { is_expected.to eq("0123456") }
        its(:swift_bank_code) { is_expected.to eq("0036") }
        its(:swift_branch_code) { is_expected.to eq("00063") }
        its(:swift_account_number) { is_expected.to eq("0123456") }
        its(:swift_national_id) { is_expected.to eq("003600063") }
        its(:pseudo_iban) { is_expected.to eq("CAZZ003600063_____0123456") }

        its(:iban) { is_expected.to be_nil }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "for an all zero transit number" do
        let(:account_number) { "0123456" }
        let(:bank_code) { "036" }
        let(:branch_code) { "00000" }

        it "is invalid and has the correct errors" do
          expect(subject.valid?).to eq(false)
          expect(subject.errors).
            to eq(branch_code: "format is invalid")
        end
      end

      context "and a 4 digit branch code" do
        let(:account_number) { "0123456" }
        let(:bank_code) { "036" }
        let(:branch_code) { "0063" }

        it "is invalid and has the correct errors" do
          expect(subject.valid?).to eq(false)
          expect(subject.errors).
            to eq(branch_code: "is the wrong length (should be 5 characters)")
        end
      end

      context "and a 3 digit bank code" do
        let(:account_number) { "0123456" }
        let(:bank_code) { "036" }

        its(:country_code) { is_expected.to eq("CA") }
        its(:bank_code) { is_expected.to eq("0036") }
        its(:branch_code) { is_expected.to eq("00063") }
        its(:account_number) { is_expected.to eq("0123456") }
        its(:swift_bank_code) { is_expected.to eq("0036") }
        its(:swift_branch_code) { is_expected.to eq("00063") }
        its(:swift_account_number) { is_expected.to eq("0123456") }
        its(:swift_national_id) { is_expected.to eq("003600063") }
        its(:pseudo_iban) { is_expected.to eq("CAZZ003600063_____0123456") }

        its(:iban) { is_expected.to be_nil }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 2 digit bank code" do
        let(:account_number) { "0123456" }
        let(:bank_code) { "36" }

        its(:country_code) { is_expected.to eq("CA") }
        its(:bank_code) { is_expected.to eq("36") }
        its(:branch_code) { is_expected.to eq("00063") }
        its(:account_number) { is_expected.to eq("0123456") }
        its(:swift_bank_code) { is_expected.to eq("36") }
        its(:swift_branch_code) { is_expected.to eq("00063") }
        its(:swift_account_number) { is_expected.to eq("0123456") }
        its(:swift_national_id) { is_expected.to eq("3600063") }
        its(:pseudo_iban) { is_expected.to eq("CAZZ__3600063_____0123456") }

        its(:iban) { is_expected.to be_nil }
        its(:valid?) { is_expected.to eq(false) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 7 digit account number" do
        let(:account_number) { "0123456" }
        let(:bank_code) { "0036" }

        its(:country_code) { is_expected.to eq("CA") }
        its(:bank_code) { is_expected.to eq("0036") }
        its(:branch_code) { is_expected.to eq("00063") }
        its(:account_number) { is_expected.to eq("0123456") }
        its(:swift_bank_code) { is_expected.to eq("0036") }
        its(:swift_branch_code) { is_expected.to eq("00063") }
        its(:swift_account_number) { is_expected.to eq("0123456") }
        its(:swift_national_id) { is_expected.to eq("003600063") }
        its(:pseudo_iban) { is_expected.to eq("CAZZ003600063_____0123456") }

        its(:iban) { is_expected.to be_nil }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and account number has invalid characters in" do
        let(:account_number) { "123456XX789" }
        let(:bank_code) { "0036" }

        its(:valid?) { is_expected.to be false }
      end

      context "and account number has only zeroes in it" do
        let(:account_number) { "0000000" }
        let(:bank_code) { "0036" }

        it "is invalid and has the correct errors" do
          expect(subject.valid?).to eq(false)
          expect(subject.errors).
            to eq(account_number: "format is invalid")
        end
      end

      context "and a 12 digit account number" do
        let(:account_number) { "012345678900" }
        let(:bank_code) { "0036" }

        its(:country_code) { is_expected.to eq("CA") }
        its(:bank_code) { is_expected.to eq("0036") }
        its(:branch_code) { is_expected.to eq("00063") }
        its(:account_number) { is_expected.to eq("012345678900") }
        its(:swift_bank_code) { is_expected.to eq("0036") }
        its(:swift_branch_code) { is_expected.to eq("00063") }
        its(:swift_account_number) { is_expected.to eq("012345678900") }
        its(:swift_national_id) { is_expected.to eq("003600063") }
        its(:pseudo_iban) { is_expected.to eq("CAZZ003600063012345678900") }

        its(:iban) { is_expected.to be_nil }
        its(:valid?) { is_expected.to be true }
        its(:to_s) { is_expected.to eq("") }
      end
    end

    context "when the IBAN was created from an Canadian pseudo-IBAN" do
      let(:arg) { "CAZZ0036000630123456" }

      its(:country_code) { is_expected.to eq("CA") }
      its(:bank_code) { is_expected.to eq("0036") }
      its(:branch_code) { is_expected.to eq("00063") }
      its(:account_number) { is_expected.to eq("0123456") }
      its(:swift_bank_code) { is_expected.to eq("0036") }
      its(:swift_branch_code) { is_expected.to eq("00063") }
      its(:swift_account_number) { is_expected.to eq("0123456") }
      its(:pseudo_iban) { is_expected.to eq("CAZZ003600063_____0123456") }

      its(:iban) { is_expected.to be_nil }
      its(:valid?) { is_expected.to be true }
      its(:to_s) { is_expected.to eq("") }
    end

    context "when the input is an invalid Canadian pseudo-IBAN" do
      let(:arg) { "CAZZ00360006301234" }

      it "is invalid and has the correct errors" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors).
          to eq(account_number: "is the wrong length (should be 7..12 characters)")
      end
    end

    context "when the IBAN was created with local details for New Zealand" do
      let(:arg) do
        {
          country_code: "NZ",
          bank_code: "11",
          branch_code: "2222",
          account_number: account_number,
        }
      end

      context "with a 3 digit account number suffix" do
        let(:account_number) { "3333333-944" }

        its(:country_code) { is_expected.to eq("NZ") }
        its(:bank_code) { is_expected.to eq("11") }
        its(:branch_code) { is_expected.to eq("2222") }
        its(:account_number) { is_expected.to eq("3333333") }
        its(:account_number_suffix) { is_expected.to eq("944") }
        its(:swift_bank_code) { is_expected.to eq("11") }
        its(:swift_branch_code) { is_expected.to eq("2222") }
        its(:swift_account_number) { is_expected.to eq("3333333944") }
        its(:swift_national_id) { is_expected.to eq("112222") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("NZZZ1122223333333944") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "with a 2 digit account number suffix" do
        let(:account_number) { "3333333-44" }

        its(:country_code) { is_expected.to eq("NZ") }
        its(:bank_code) { is_expected.to eq("11") }
        its(:branch_code) { is_expected.to eq("2222") }
        its(:account_number) { is_expected.to eq("3333333") }
        its(:account_number_suffix) { is_expected.to eq("044") }
        its(:swift_bank_code) { is_expected.to eq("11") }
        its(:swift_branch_code) { is_expected.to eq("2222") }
        its(:swift_account_number) { is_expected.to eq("3333333044") }
        its(:swift_national_id) { is_expected.to eq("112222") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("NZZZ1122223333333044") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "with bank and branch code embedded in account_number field" do
        let(:arg) do
          {
            country_code: "NZ",
            account_number: "11-2222-3333333-44",
          }
        end

        its(:country_code) { is_expected.to eq("NZ") }
        its(:bank_code) { is_expected.to eq("11") }
        its(:branch_code) { is_expected.to eq("2222") }
        its(:account_number) { is_expected.to eq("3333333") }
        its(:account_number_suffix) { is_expected.to eq("044") }
        its(:swift_bank_code) { is_expected.to eq("11") }
        its(:swift_branch_code) { is_expected.to eq("2222") }
        its(:swift_account_number) { is_expected.to eq("3333333044") }
        its(:swift_national_id) { is_expected.to eq("112222") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("NZZZ1122223333333044") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "with a bank code embedded in account_number field" do
        let(:arg) do
          {
            country_code: "NZ",
            account_number: "11-3333333-44",
            branch_code: "2222",
          }
        end

        it "is invalid and has the correct errors" do
          expect(subject.valid?).to eq(false)
          expect(subject.errors).to eq(
            account_number: "is the wrong length (should be 10 characters)",
          )
        end
      end
    end

    context "when the IBAN was created from a New Zealand pseudo-IBAN" do
      let(:arg) { "NZZZ1122223333333044" }

      its(:country_code) { is_expected.to eq("NZ") }
      its(:bank_code) { is_expected.to eq("11") }
      its(:branch_code) { is_expected.to eq("2222") }
      its(:account_number) { is_expected.to eq("3333333") }
      its(:account_number_suffix) { is_expected.to eq("044") }
      its(:swift_bank_code) { is_expected.to eq("11") }
      its(:swift_branch_code) { is_expected.to eq("2222") }
      its(:swift_account_number) { is_expected.to eq("3333333044") }
      its(:swift_national_id) { is_expected.to eq("112222") }
      its(:iban) { is_expected.to be_nil }
      its(:pseudo_iban) { is_expected.to eq("NZZZ1122223333333044") }
      its(:valid?) { is_expected.to eq(true) }
      its(:to_s) { is_expected.to eq("") }
    end

    context "when the input is an invalid New Zealand pseudo-IBAN" do
      let(:arg) { "NZZZ11222233333330444" }

      its(:iban) { is_expected.to be_nil }
      its(:pseudo_iban) { is_expected.to eq(arg) }

      it "is invalid and has the correct errors" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors).
          to eq(account_number: "is the wrong length (should be 10 characters)")
      end
    end

    context "when the IBAN was created with local details for US" do
      let(:arg) do
        {
          country_code: "US",
          bank_code: bank_code,
          account_number: account_number,
        }
      end

      context "and a 9 digit bank code" do
        let(:bank_code) { "026073150" }
        let(:account_number) { "01234567890123456" }

        its(:country_code) { is_expected.to eq("US") }
        its(:bank_code) { is_expected.to eq(bank_code) }
        its(:account_number) { is_expected.to eq(account_number) }
        its(:swift_bank_code) { is_expected.to eq(bank_code) }
        its(:swift_branch_code) { is_expected.to eq(nil) }
        its(:swift_account_number) { is_expected.to eq(account_number) }
        its(:swift_national_id) { is_expected.to eq(bank_code) }

        its(:pseudo_iban) do
          is_expected.to eq("USZZ02607315001234567890123456")
        end

        its(:iban) { is_expected.to be_nil }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 7 digit bank code" do
        let(:bank_code) { "0123456" }
        let(:account_number) { "01234567890123456" }

        its(:country_code) { is_expected.to eq("US") }
        its(:bank_code) { is_expected.to eq(bank_code) }
        its(:account_number) { is_expected.to eq(account_number) }
        its(:swift_bank_code) { is_expected.to eq(bank_code) }
        its(:swift_branch_code) { is_expected.to eq(nil) }
        its(:swift_account_number) { is_expected.to eq(account_number) }
        its(:swift_national_id) { is_expected.to eq(bank_code) }

        its(:pseudo_iban) do
          is_expected.to eq("USZZ__012345601234567890123456")
        end

        its(:iban) { is_expected.to be_nil }
        its(:valid?) { is_expected.to eq(false) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and bank code that doesn't pass checksum test" do
        let(:bank_code) { "900000000" }
        let(:account_number) { "01234567890123456" }

        its(:iban) { is_expected.to be_nil }

        it "returns an error on bank_code attribute" do
          expect(subject.valid?).to eq(false)
          expect(subject.errors).to eq(bank_code: "did not pass checksum test")
        end
      end

      context "and a 7 digit account number" do
        let(:account_number) { "0123456" }
        let(:bank_code) { "026073150" }

        its(:country_code) { is_expected.to eq("US") }
        its(:bank_code) { is_expected.to eq(bank_code) }
        its(:account_number) { is_expected.to eq("0123456") }
        its(:swift_bank_code) { is_expected.to eq(bank_code) }
        its(:swift_branch_code) { is_expected.to eq(nil) }
        its(:swift_account_number) { is_expected.to eq("0123456") }
        its(:swift_national_id) { is_expected.to eq(bank_code) }

        its(:pseudo_iban) do
          is_expected.to eq("USZZ026073150__________0123456")
        end

        its(:iban) { is_expected.to be_nil }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and bank code that is nil" do
        let(:bank_code) { nil }
        let(:account_number) { "01234567890123456" }

        its(:iban) { is_expected.to be_nil }

        it "returns an error on bank_code attribute" do
          expect(subject.valid?).to eq(false)
          expect(subject.errors).to eq(bank_code: "is required")
        end
      end

      context "and a 17 digit account number" do
        let(:account_number) { "01234567890123456" }
        let(:bank_code) { "026073150" }

        its(:country_code) { is_expected.to eq("US") }
        its(:bank_code) { is_expected.to eq(bank_code) }
        its(:account_number) { is_expected.to eq("01234567890123456") }
        its(:swift_bank_code) { is_expected.to eq(bank_code) }
        its(:swift_branch_code) { is_expected.to eq(nil) }
        its(:swift_account_number) { is_expected.to eq(account_number) }
        its(:swift_national_id) { is_expected.to eq(bank_code) }

        its(:pseudo_iban) do
          is_expected.to eq("USZZ02607315001234567890123456")
        end

        its(:iban) { is_expected.to be_nil }
        its(:valid?) { is_expected.to be true }
        its(:to_s) { is_expected.to eq("") }
      end
    end

    context "when the IBAN was created from a US pseudo-IBAN" do
      let(:arg) { "USZZ02607315001234567890123456" }

      its(:country_code) { is_expected.to eq("US") }
      its(:bank_code) { is_expected.to eq("026073150") }
      its(:branch_code) { is_expected.to be_nil }
      its(:account_number) { is_expected.to eq("01234567890123456") }
      its(:swift_bank_code) { is_expected.to eq("026073150") }
      its(:swift_branch_code) { is_expected.to eq(nil) }
      its(:swift_account_number) { is_expected.to eq("01234567890123456") }
      its(:swift_national_id) { is_expected.to eq("026073150") }

      its(:pseudo_iban) do
        is_expected.to eq("USZZ02607315001234567890123456")
      end

      its(:iban) { is_expected.to be_nil }
      its(:valid?) { is_expected.to be true }
      its(:to_s) { is_expected.to eq("") }
    end

    context "when the input pseudo-IBAN has an invalid US bank_code" do
      let(:arg) { "USZZ__012345601234567890123456" }

      it "is invalid and has the correct errors" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors).
          to eq(bank_code: "is the wrong length (should be 9 characters)")
      end
    end

    context "when the input pseudo-IBAN has an invalid US account_number" do
      let(:arg) { "USZZ026073150ABC01234567890123" }

      it "is invalid and has an error populated" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors).to eq(account_number: "format is invalid")
      end
    end

    # Spanish IBANs have recently switched to 8 character national IDs
    context "with a Spanish IBAN" do
      let(:iban_code) { "ES9121000418450200051332" }

      its(:country_code) { is_expected.to eq("ES") }
      its(:bank_code) { is_expected.to eq("2100") }
      its(:branch_code) { is_expected.to eq("0418") }
      its(:account_number) { is_expected.to eq("450200051332") }
      its(:account_number_suffix) { is_expected.to be_nil }
      its(:swift_bank_code) { is_expected.to eq("2100") }
      its(:swift_branch_code) { is_expected.to eq("0418") }
      its(:swift_account_number) { is_expected.to eq("450200051332") }
      its(:swift_national_id) { is_expected.to eq("21000418") }
      its(:local_check_digits) { is_expected.to eq("45") }
      its(:bban) { is_expected.to eq("21000418450200051332") }
    end
  end

  describe "#to_s" do
    specify { expect(iban.to_s).to eq("GB82WEST12345698765432") }
    specify { expect(iban.to_s(:compact)).to eq("GB82WEST12345698765432") }

    it "returns a prettified string when passed :formatted" do
      expect(iban.to_s(:formatted)).to eq("GB82 WEST 1234 5698 7654 32")
    end

    specify { expect { iban.to_s(:russian) }.to raise_error ArgumentError }

    context "with the IBAN is nil" do
      let(:arg) { { country_code: "GB" } }

      its(:to_s) { is_expected.to_not be_nil }
      specify { expect(iban.to_s(:formatted)).to be_empty }
    end

    context "with Swedish local details" do
      let(:arg) do
        {
          country_code: "SE",
          branch_code: "1281",
          account_number: "0105723",
        }
      end

      specify { expect(iban.to_s).to eq("SE5412000000012810105723") }
    end

    context "with a Swedish pseudo-IBAN" do
      let(:arg) { "SEZZX1281XXX0105723" }

      specify { expect(iban.to_s).to eq("SE5412000000012810105723") }
    end
  end

  ###############
  # Validations #
  ###############

  describe "#valid_country_code?" do
    subject { iban.valid_country_code? }

    context "with valid details" do
      it { is_expected.to eq(true) }
    end

    context "with an unknown country code" do
      before { iban.valid_country_code? }

      let(:iban_code) { "AA123456789123456" }

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_country_code?
        expect(iban.errors).to include(
          country_code: "'AA' is not a valid ISO 3166-1 IBAN country code",
        )
      end
    end
  end

  describe "#valid_check_digits?" do
    subject { iban.valid_check_digits? }

    context "with valid details" do
      let(:iban_code) { "GB82WEST12345698765432" }

      it { is_expected.to eq(true) }

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
        expect(iban.errors).to include(
          check_digits: "Check digits failed modulus check. " \
                        "Expected '82', received '12'.",
        )
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

    context "with an empty IBAN" do
      let(:iban_code) { "" }

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
      it { is_expected.to eq(true) }
    end

    context "with invalid details" do
      let(:iban_code) { "GB82WEST123456987654" }

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_length?
        expect(iban.errors).to include(
          length: "Length doesn't match SWIFT specification " \
                  "(expected 22 characters, received 20)",
        )
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

  describe "#valid_bank_code_length?" do
    subject { iban.valid_bank_code_length? }

    context "with valid details" do
      it { is_expected.to eq(true) }
    end

    context "with invalid details" do
      before { allow(iban).to receive(:swift_bank_code).and_return("WES") }

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_bank_code_length?
        expect(iban.errors).to include(
          bank_code: "is the wrong length (should be 4 characters)",
        )
      end
    end

    context "with an invalid country_code" do
      before { allow(iban).to receive(:country_code).and_return("AA") }

      it { is_expected.to be_nil }

      it "does not set errors on the IBAN" do
        iban.valid_bank_code_length?
        expect(iban.errors).to_not include(:bank_code)
      end
    end
  end

  describe "#valid_branch_code_length?" do
    subject { iban.valid_branch_code_length? }

    context "with valid details" do
      it { is_expected.to eq(true) }
    end

    context "with invalid details" do
      before { allow(iban).to receive(:swift_branch_code).and_return("12345") }

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_branch_code_length?
        expect(iban.errors).to include(
          branch_code: "is the wrong length (should be 6 characters)",
        )
      end
    end

    context "without a branch code" do
      before { allow(iban).to receive(:swift_branch_code).and_return(nil) }

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_branch_code_length?
        expect(iban.errors).to include(branch_code: "is required")
      end
    end

    context "with an invalid country_code" do
      before { allow(iban).to receive(:country_code).and_return("AA") }

      it { is_expected.to be_nil }

      it "does not set errors on the IBAN" do
        iban.valid_branch_code_length?
        expect(iban.errors).to_not include(:branch_code)
      end
    end
  end

  describe "#valid_account_number_length?" do
    subject { iban.valid_account_number_length? }

    context "with valid details" do
      it { is_expected.to eq(true) }
    end

    context "with an invalid account_number" do
      before do
        allow(iban).to receive(:swift_account_number).and_return("1234567")
      end

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_account_number_length?
        expect(iban.errors).to include(
          account_number: "is the wrong length (should be 8 characters)",
        )
      end
    end

    context "with an invalid country_code" do
      before { allow(iban).to receive(:country_code).and_return("AA") }

      it { is_expected.to be_nil }

      it "does not set errors on the IBAN" do
        iban.valid_account_number_length?
        expect(iban.errors).to_not include(:account_number)
      end
    end
  end

  describe "#valid_characters?" do
    subject { iban.valid_characters? }

    context "with valid details" do
      let(:iban_code) { "GB82WEST12345698765432" }

      it { is_expected.to eq(true) }
    end

    context "with invalid details" do
      let(:iban_code) { "GB-123ABCD" }

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_characters?
        expect(iban.errors).to include(
          characters: "Non-alphanumeric characters found: -",
        )
      end
    end
  end

  describe "#valid_format?" do
    subject { iban.valid_format? }

    context "with valid details" do
      let(:iban_code) { "GB82WEST12345698765432" }

      it { is_expected.to eq(true) }
    end

    context "with invalid details" do
      let(:iban_code) { "GB82WEST12AAAAAA7654" }

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_format?
        expect(iban.errors).to include(format: "Unexpected format for a GB IBAN.")
      end
    end

    context "with an invalid country_code" do
      let(:iban_code) { "AA82WEST12AAAAAA7654" }

      it { is_expected.to be_nil }

      it "does not set errors on the IBAN" do
        iban.valid_format?
        expect(iban.errors).to_not include(:format)
      end
    end
  end

  describe "#valid_bank_code_format?" do
    subject { iban.valid_bank_code_format? }

    context "GB numeric bank code" do
      let(:arg) do
        {
          country_code: "GB",
          bank_code: "1234",
          branch_code: "200000",
          account_number: "55779911",
        }
      end

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_bank_code_format?
        expect(iban.errors).to include(bank_code: "format is invalid")
      end
    end

    context "with an invalid country code" do
      let(:iban_code) { "AA821234BANK121234567B" }

      it { is_expected.to be_nil }
    end

    context "with a wrong-length bank code" do
      let(:arg) do
        {
          country_code: "FR",
          bank_code: "1234",
          branch_code: "12345",
          account_number: "123456789123",
        }
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#valid_branch_code_format?" do
    subject { iban.valid_branch_code_format? }

    context "IT non-numeric branch code" do
      let(:arg) do
        {
          country_code: "IT",
          bank_code: "12345",
          branch_code: "ABCDE",
          account_number: "123456789012",
        }
      end

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_branch_code_format?
        expect(iban.errors).to include(branch_code: "format is invalid")
      end
    end

    context "with an invalid country code" do
      let(:iban_code) { "AA821234BANK121234567B" }

      it { is_expected.to be_nil }
    end

    context "with a wrong-length branch code" do
      let(:arg) do
        {
          country_code: "PT",
          bank_code: "1234",
          branch_code: "ABC",
          account_number: "123456789123",
        }
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#valid_account_number_format?" do
    subject { iban.valid_account_number_format? }

    context "DE non-numeric account number" do
      let(:arg) do
        {
          country_code: "DE",
          bank_code: "12345678",
          account_number: "55779911AA",
        }
      end

      it { is_expected.to eq(false) }

      it "sets errors on the IBAN" do
        iban.valid_account_number_format?
        expect(iban.errors).to include(account_number: "format is invalid")
      end
    end

    context "with an invalid country code" do
      let(:iban_code) { "AA821234BANK121234567B" }

      it { is_expected.to be_nil }
    end

    context "with a wrong-length account number" do
      let(:arg) do
        {
          country_code: "NL",
          bank_code: "ABCD",
          account_number: nil,
        }
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#valid_local_modulus_check?" do
    subject(:valid_local_modulus_check?) { iban.valid_local_modulus_check? }

    context "without a modulus checker defined" do
      it { is_expected.to be(true) }
    end

    context "with a modulus checker defined" do
      before do
        Ibandit.modulus_checker = double(
          valid_bank_code?: valid_bank_code,
          valid_branch_code?: valid_branch_code,
          valid_account_number?: valid_account_number,
        )
        iban.valid_local_modulus_check?
      end

      after { Ibandit.modulus_checker = nil }

      context "with an invalid bank code" do
        let(:iban_code) { "AT611904300234573201" }
        let(:valid_bank_code) { false }
        let(:valid_branch_code) { true }
        let(:valid_account_number) { true }

        it "calls valid_bank_code? with an IBAN object" do
          expect(Ibandit.modulus_checker).
            to receive(:valid_bank_code?).
            with(instance_of(described_class))

          iban.valid_local_modulus_check?
        end

        it { is_expected.to be(false) }

        it "sets the errors on the IBAN" do
          expect(iban.errors).to include(bank_code: "bank code does not exist")
        end
      end

      context "with an invalid branch code" do
        let(:iban_code) { "GB60BARC20000055779911" }
        let(:valid_bank_code) { true }
        let(:valid_branch_code) { false }
        let(:valid_account_number) { true }

        before do
          Ibandit.bic_finder = double(call: "BARCGB22XXX")
          iban.valid_local_modulus_check?
        end

        after { Ibandit.bic_finder = nil }

        it "calls valid_branch_code? with an IBAN object" do
          expect(Ibandit.modulus_checker).
            to receive(:valid_branch_code?).
            with(instance_of(described_class))

          iban.valid_local_modulus_check?
        end

        it { is_expected.to be(false) }

        it "sets the errors on the IBAN" do
          expect(iban.errors).to include(branch_code: "branch code does not exist")
        end
      end

      context "with an invalid account number" do
        let(:valid_bank_code) { true }
        let(:valid_branch_code) { true }
        let(:valid_account_number) { false }

        it "calls valid_account_number? with an IBAN object" do
          expect(Ibandit.modulus_checker).
            to receive(:valid_account_number?).
            with(instance_of(described_class))

          iban.valid_local_modulus_check?
        end

        it { is_expected.to be(false) }

        it "sets the errors on the IBAN" do
          expect(iban.errors).to include(account_number: "did not pass modulus check")
        end
      end
    end

    describe "supports_iban_determination?" do
      subject { iban.supports_iban_determination? }

      context "with unsupported account details" do
        let(:arg) do
          {
            country_code: "DE",
            bank_code: "20000000",
            account_number: "7955791111",
          }
        end

        it { is_expected.to eq(false) }

        it "sets the errors on the IBAN" do
          iban.supports_iban_determination?
          expect(iban.errors).
            to include(account_number: "does not support payments")
        end
      end
    end

    describe "valid_swedish_details?" do
      subject { iban.valid_swedish_details? }

      context "with SWIFT details" do
        context "with an account number that is too long" do
          let(:arg) do
            {
              country_code: "SE",
              bank_code: "500",
              account_number: "00000543910240391",
            }
          end

          it { is_expected.to eq(false) }

          it "sets the errors on the IBAN" do
            iban.valid_swedish_details?
            expect(iban.errors).to eq(account_number: "length is invalid")
          end
        end

        context "with an account number that doesn't have a bank code" do
          let(:arg) do
            {
              country_code: "SE",
              bank_code: nil,
              account_number: "00000000000010011",
            }
          end

          it { is_expected.to eq(false) }

          it "sets the errors on the IBAN" do
            iban.valid?
            expect(iban.errors).to include(
              account_number: "bank code does not exist",
              format: "Unexpected format for a SE IBAN.",
            )
            expect(iban.errors).to_not include(:bank_code)
          end
        end

        context "with a bank code that does not match" do
          let(:arg) do
            {
              country_code: "SE",
              bank_code: "902",
              account_number: "00000054391024039",
            }
          end

          it { is_expected.to eq(false) }

          it "sets the errors on the IBAN" do
            iban.valid_swedish_details?
            expect(iban.errors).to eq(account_number: "length is invalid")
          end
        end
      end

      context "with local details" do
        context "with good details" do
          let(:arg) do
            {
              country_code: "SE",
              account_number: "5439-0240391",
            }
          end

          it { is_expected.to eq(true) }
        end

        context "with a clearing code that is too long" do
          let(:arg) do
            {
              country_code: "SE",
              branch_code: "54391",
              account_number: "0240391",
            }
          end

          it { is_expected.to eq(false) }

          it "sets the errors on the IBAN" do
            iban.valid_swedish_details?
            expect(iban.errors).to eq(branch_code: "clearing code length is invalid")
          end
        end

        context "with a serial number that is too long" do
          let(:arg) do
            {
              country_code: "SE",
              branch_code: "5439",
              account_number: "024039111",
            }
          end

          it { is_expected.to eq(false) }

          it "sets the errors on the IBAN" do
            iban.valid_swedish_details?
            expect(iban.errors).to eq(account_number: "serial number is invalid")
          end
        end
      end
    end
  end

  describe "valid_australian_details" do
    subject { iban.valid_australian_details? }

    context "with non-Australian details" do
      let(:arg) do
        {
          country_code: "GB",
          bank_code: "1234",
          branch_code: "200000",
          account_number: "55779911",
        }
      end

      it { is_expected.to be(true) }
    end

    context "with Australian details" do
      let(:arg) do
        {
          country_code: "AU",
          branch_code: "123-456",
          account_number: "123456789",
        }
      end

      context "without a modulus checker defined" do
        it { is_expected.to be(true) }
      end

      context "with a modulus checker defined" do
        before do
          Ibandit.modulus_checker = double(
            valid_branch_code?: valid_branch_code,
          )
          iban.valid_australian_details?
        end

        after { Ibandit.modulus_checker = nil }

        let(:valid_branch_code) { true }

        it "calls valid_branch_code? with an IBAN object" do
          expect(Ibandit.modulus_checker).
            to receive(:valid_branch_code?).
            with(instance_of(described_class))

          iban.valid_australian_details?
        end

        it { is_expected.to be(true) }

        context "with an invalid bsb" do
          let(:valid_branch_code) { false }

          it { is_expected.to be(false) }

          it "sets the errors on the IBAN" do
            expect(iban.errors).to include(branch_code: "branch code does not exist")
          end
        end
      end
    end
  end

  describe "valid_nz_details" do
    subject { iban.valid_nz_details? }

    context "with non-NewZealand details" do
      let(:arg) do
        {
          country_code: "GB",
          bank_code: "1234",
          branch_code: "200000",
          account_number: "55779911",
        }
      end

      it { is_expected.to be(true) }
    end

    context "with NewZealand details" do
      let(:arg) do
        {
          country_code: "NZ",
          bank_code: "01",
          branch_code: "0004",
          account_number: "123456789",
        }
      end

      context "without a modulus checker defined" do
        it { is_expected.to be(true) }
      end

      context "with a modulus checker defined" do
        before do
          Ibandit.modulus_checker = double(
            valid_branch_code?: valid_branch_code,
          )
          iban.valid_nz_details?
        end

        after { Ibandit.modulus_checker = nil }

        let(:valid_branch_code) { true }

        it "calls valid_branch_code? with an IBAN object" do
          expect(Ibandit.modulus_checker).
            to receive(:valid_branch_code?).
            with(instance_of(described_class))

          iban.valid_nz_details?
        end

        it { is_expected.to be(true) }

        context "with an invalid branch code" do
          let(:valid_branch_code) { false }

          it { is_expected.to be(false) }

          it "sets the errors on the IBAN" do
            expect(iban.errors).to include(branch_code: "branch code does not exist")
          end
        end
      end
    end
  end

  describe "valid_ca_details" do
    subject { iban.valid_ca_details? }

    context "with non-Canadian details" do
      let(:arg) do
        {
          country_code: "GB",
          bank_code: "1234",
          branch_code: "200000",
          account_number: "55779911",
        }
      end

      it { is_expected.to be(true) }
    end

    context "with Canadian details" do
      let(:arg) do
        {
          country_code: "CA",
          bank_code: "0036",
          branch_code: "00063",
          account_number: "0123456",
        }
      end

      context "without a modulus checker defined" do
        it { is_expected.to be(true) }
      end

      context "with a modulus checker defined" do
        before do
          Ibandit.modulus_checker = double(
            valid_branch_code?: valid_branch_code,
          )
          iban.valid_ca_details?
        end

        after { Ibandit.modulus_checker = nil }

        let(:valid_branch_code) { true }

        it "calls valid_branch_code? with an IBAN object" do
          expect(Ibandit.modulus_checker).
            to receive(:valid_branch_code?).
            with(instance_of(described_class))

          iban.valid_ca_details?
        end

        it { is_expected.to be(true) }

        context "with an invalid branch code" do
          let(:valid_branch_code) { false }

          it { is_expected.to be(false) }

          it "sets the errors on the IBAN" do
            expect(iban.errors).to include(branch_code: "branch code does not exist")
          end
        end
      end
    end
  end

  describe "Pseudo IBAN #valid?" do
    let(:country_code) { "CA" }
    let(:arg) do
      {
        country_code: country_code,
        bank_code: "0036",
        branch_code: "00063",
        account_number: "1234567",
      }
    end

    describe "validations called" do
      after { iban.valid? }

      specify { expect(iban).to receive(:valid_pseudo_iban?).at_least(1) }
      specify { expect(iban).to receive(:valid_pseudo_iban_check_digits?).at_least(1) }
      specify { expect(iban).to receive(:valid_country_code?).at_least(1) }
      specify { expect(iban).to receive(:valid_bank_code_length?).at_least(1) }
      specify { expect(iban).to receive(:valid_branch_code_length?).at_least(1) }
      specify { expect(iban).to receive(:valid_account_number_length?).at_least(1) }
      specify { expect(iban).to receive(:valid_bank_code_format?).at_least(1) }
      specify { expect(iban).to receive(:valid_branch_code_format?).at_least(1) }
      specify { expect(iban).to receive(:valid_account_number_format?).at_least(1) }
      specify { expect(iban).to receive(:passes_country_specific_checks?).at_least(1) }

      context "SE" do
        let(:country_code) { "SE" }

        specify { expect(iban).to receive(:valid_swedish_details?).at_least(1) }
      end

      context "AU" do
        let(:country_code) { "AU" }

        specify { expect(iban).to receive(:valid_australian_details?).at_least(1) }
      end

      context "NZ" do
        let(:country_code) { "NZ" }

        specify { expect(iban).to receive(:valid_nz_details?).at_least(1) }
      end

      context "CA" do
        let(:country_code) { "CA" }

        specify { expect(iban).to receive(:valid_ca_details?).at_least(1) }
      end

      context "US" do
        let(:country_code) { "US" }

        specify { expect(iban).to receive(:bank_code_passes_checksum_test?).at_least(1) }
      end
    end
  end

  describe "IBAN #valid?" do
    describe "validations called" do
      after { iban.valid? }

      specify { expect(iban).to receive(:valid_iban?).at_least(1) }
      specify { expect(iban).to receive(:valid_country_code?).at_least(1) }
      specify { expect(iban).to receive(:valid_characters?).at_least(1) }
      specify { expect(iban).to receive(:valid_check_digits?).at_least(1) }
      specify { expect(iban).to receive(:valid_length?).at_least(1) }
      specify { expect(iban).to receive(:valid_bank_code_length?).at_least(1) }
      specify { expect(iban).to receive(:valid_format?).at_least(1) }
      specify { expect(iban).to receive(:valid_bank_code_format?).at_least(1) }

      it "validates the branch code length" do
        expect(iban).to receive(:valid_branch_code_length?).at_least(1)
      end

      it "validates the account number length" do
        expect(iban).to receive(:valid_account_number_length?).at_least(1)
      end

      it "validates the branch code format" do
        expect(iban).to receive(:valid_branch_code_format?).at_least(1)
      end

      it "validates the account number format" do
        expect(iban).to receive(:valid_account_number_format?).at_least(1)
      end

      it "runs local modulus checks" do
        expect(iban).to receive(:valid_local_modulus_check?).at_least(1)
      end

      it "runs country specific checks" do
        expect(iban).to receive(:passes_country_specific_checks?).at_least(1)
      end

      context "DE" do
        let(:arg) do
          {
            country_code: "DE",
            bank_code: "20000000",
            account_number: "7955791111",
          }
        end

        specify { expect(iban).to receive(:supports_iban_determination?).at_least(1) }
      end
    end

    RSpec.shared_examples "a country's IBAN" do |country_code|
      context "for #{country_code}" do
        context "with a valid iban" do
          let(:iban_code) { valid_iban }

          it { is_expected.to be_valid }
        end

        context "with an invalid iban" do
          let(:iban_code) { invalid_iban }

          it { is_expected.to_not be_valid }
        end
      end
    end

    it_behaves_like "a country's IBAN", "AL" do
      let(:valid_iban) { "AL47 2121 1009 0000 0002 3569 8741" }
      let(:invalid_iban) { "ALXX47 2121 1009 0000 0002 3569 8741" }
    end

    it_behaves_like "a country's IBAN", "AD" do
      let(:valid_iban) { "AD12 0001 2030 2003 5910 0100" }
      let(:invalid_iban) { "ADXX12 0001 2030 2003 5910 0100" }
    end

    it_behaves_like "a country's IBAN", "AT" do
      let(:valid_iban) { "AT61 1904 3002 3457 3201" }
      let(:invalid_iban) { "ATXX61 1904 3002 3457 3201" }
    end

    it_behaves_like "a country's IBAN", "AU" do
      let(:valid_iban) { "AUZZ123456123456789" }
      let(:invalid_iban) { "AUXXZZ123456123456789" }
    end

    it_behaves_like "a country's IBAN", "AZ" do
      let(:valid_iban) { "AZ21 NABZ 0000 0000 1370 1000 1944" }
      let(:invalid_iban) { "AZXX21 NABZ 0000 0000 1370 1000 1944" }
    end

    it_behaves_like "a country's IBAN", "BH" do
      let(:valid_iban) { "BH67 BMAG 0000 1299 1234 56" }
      let(:invalid_iban) { "BHXX67 BMAG 0000 1299 1234 56" }
    end

    it_behaves_like "a country's IBAN", "BE" do
      let(:valid_iban) { "BE68 5390 0754 7034" }
      let(:invalid_iban) { "BEXX68 5390 0754 7034" }
    end

    it_behaves_like "a country's IBAN", "BA" do
      let(:valid_iban) { "BA39 1290 0794 0102 8494" }
      let(:invalid_iban) { "BAXX39 1290 0794 0102 8494" }
    end

    it_behaves_like "a country's IBAN", "BG" do
      let(:valid_iban) { "BG80 BNBG 9661 1020 3456 78" }
      let(:invalid_iban) { "BGXX80 BNBG 9661 1020 3456 78" }
    end

    it_behaves_like "a country's IBAN", "HR" do
      let(:valid_iban) { "HR12 1001 0051 8630 0016 0" }
      let(:invalid_iban) { "HRXX12 1001 0051 8630 0016 0" }
    end

    it_behaves_like "a country's IBAN", "CR" do
      let(:valid_iban) { "CR05 0152 0200 1026 2840 66" }
      let(:invalid_iban) { "CRXX05 0152 0200 1026 2840 66" }
    end

    it_behaves_like "a country's IBAN", "CY" do
      let(:valid_iban) { "CY17 0020 0128 0000 0012 0052 7600" }
      let(:invalid_iban) { "CYXX17 0020 0128 0000 0012 0052 7600" }
    end

    it_behaves_like "a country's IBAN", "CZ" do
      let(:valid_iban) { "CZ65 0800 0000 1920 0014 5399" }
      let(:invalid_iban) { "CZXX65 0800 0000 1920 0014 5399" }
    end

    it_behaves_like "a country's IBAN", "DK" do
      let(:valid_iban) { "DK50 0040 0440 1162 43" }
      let(:invalid_iban) { "DKXX50 0040 0440 1162 43" }
    end

    it_behaves_like "a country's IBAN", "DO" do
      let(:valid_iban) { "DO28 BAGR 0000 0001 2124 5361 1324" }
      let(:invalid_iban) { "DOXX28 BAGR 0000 0001 2124 5361 1324" }
    end

    it_behaves_like "a country's IBAN", "EE" do
      let(:valid_iban) { "EE38 2200 2210 2014 5685" }
      let(:invalid_iban) { "EEXX38 2200 2210 2014 5685" }
    end

    it_behaves_like "a country's IBAN", "FO" do
      let(:valid_iban) { "FO97 5432 0388 8999 44" }
      let(:invalid_iban) { "FOXX97 5432 0388 8999 44" }
    end

    it_behaves_like "a country's IBAN", "FI" do
      let(:valid_iban) { "FI21 1234 5600 0007 85" }
      let(:invalid_iban) { "FIXX21 1234 5600 0007 85" }
    end

    it_behaves_like "a country's IBAN", "FR" do
      let(:valid_iban) { "FR14 2004 1010 0505 0001 3M02 606" }
      let(:invalid_iban) { "FRXX14 2004 1010 0505 0001 3M02 606" }
    end

    it_behaves_like "a country's IBAN", "GE" do
      let(:valid_iban) { "GE29 NB00 0000 0101 9049 17" }
      let(:invalid_iban) { "GEXX29 NB00 0000 0101 9049 17" }
    end

    it_behaves_like "a country's IBAN", "DE" do
      let(:valid_iban) { "DE89 3704 0044 0532 0130 00" }
      let(:invalid_iban) { "DEXX89 3704 0044 0532 0130 00" }
    end

    it_behaves_like "a country's IBAN", "GI" do
      let(:valid_iban) { "GI75 NWBK 0000 0000 7099 453" }
      let(:invalid_iban) { "GIXX75 NWBK 0000 0000 7099 453" }
    end

    it_behaves_like "a country's IBAN", "GR" do
      let(:valid_iban) { "GR16 0110 1250 0000 0001 2300 695" }
      let(:invalid_iban) { "GRXX16 0110 1250 0000 0001 2300 695" }
    end

    it_behaves_like "a country's IBAN", "GL" do
      let(:valid_iban) { "GL56 0444 9876 5432 10" }
      let(:invalid_iban) { "GLXX56 0444 9876 5432 10" }
    end

    it_behaves_like "a country's IBAN", "HU" do
      let(:valid_iban) { "HU42 1177 3016 1111 1018 0000 0000" }
      let(:invalid_iban) { "HUXX42 1177 3016 1111 1018 0000 0000" }
    end

    it_behaves_like "a country's IBAN", "IS" do
      let(:valid_iban) { "IS14 0159 2600 7654 5510 7303 39" }
      let(:invalid_iban) { "ISXX14 0159 2600 7654 5510 7303 39" }
    end

    it_behaves_like "a country's IBAN", "IE" do
      let(:valid_iban) { "IE29 AIBK 9311 5212 3456 78" }
      let(:invalid_iban) { "IEXX29 AIBK 9311 5212 3456 78" }
    end

    it_behaves_like "a country's IBAN", "IL" do
      let(:valid_iban) { "IL62 0108 0000 0009 9999 999" }
      let(:invalid_iban) { "ILXX62 0108 0000 0009 9999 999" }
    end

    it_behaves_like "a country's IBAN", "IT" do
      let(:valid_iban) { "IT60 X054 2811 1010 0000 0123 456" }
      let(:invalid_iban) { "ITXX60 X054 2811 1010 0000 0123 456" }
    end

    it_behaves_like "a country's IBAN", "JO" do
      let(:valid_iban) { "JO94 CBJO 0010 0000 0000 0131 0003 02" }
      let(:invalid_iban) { "JOXX94 CBJO 0010 0000 0000 0131 0003 02" }
    end

    it_behaves_like "a country's IBAN", "KW" do
      let(:valid_iban) { "KW81 CBKU 0000 0000 0000 1234 5601 01" }
      let(:invalid_iban) { "KWXX81 CBKU 0000 0000 0000 1234 5601 01" }
    end

    it_behaves_like "a country's IBAN", "LV" do
      let(:valid_iban) { "LV80 BANK 0000 4351 9500 1" }
      let(:invalid_iban) { "LVXX80 BANK 0000 4351 9500 1" }
    end

    it_behaves_like "a country's IBAN", "LB" do
      let(:valid_iban) { "LB62 0999 0000 0001 0019 0122 9114" }
      let(:invalid_iban) { "LBXX62 0999 0000 0001 0019 0122 9114" }
    end

    it_behaves_like "a country's IBAN", "LI" do
      let(:valid_iban) { "LI21 0881 0000 2324 013A A" }
      let(:invalid_iban) { "LIXX21 0881 0000 2324 013A A" }
    end

    it_behaves_like "a country's IBAN", "LT" do
      let(:valid_iban) { "LT12 1000 0111 0100 1000" }
      let(:invalid_iban) { "LTXX12 1000 0111 0100 1000" }
    end

    it_behaves_like "a country's IBAN", "LU" do
      let(:valid_iban) { "LU28 0019 4006 4475 0000" }
      let(:invalid_iban) { "LUXX28 0019 4006 4475 0000" }
    end

    it_behaves_like "a country's IBAN", "MK" do
      let(:valid_iban) { "MK072 5012 0000 0589 84" }
      let(:invalid_iban) { "MKXX072 5012 0000 0589 84" }
    end

    it_behaves_like "a country's IBAN", "MT" do
      let(:valid_iban) { "MT84 MALT 0110 0001 2345 MTLC AST0 01S" }
      let(:invalid_iban) { "MTXX84 MALT 0110 0001 2345 MTLC AST0 01S" }
    end

    it_behaves_like "a country's IBAN", "MU" do
      let(:valid_iban) { "MU17 BOMM 0101 1010 3030 0200 000M UR" }
      let(:invalid_iban) { "MUXX17 BOMM 0101 1010 3030 0200 000M UR" }
    end

    it_behaves_like "a country's IBAN", "MD" do
      let(:valid_iban) { "MD24 AG00 0225 1000 1310 4168" }
      let(:invalid_iban) { "MDXX24 AG00 0225 1000 1310 4168" }
    end

    it_behaves_like "a country's IBAN", "MC" do
      let(:valid_iban) { "MC93 2005 2222 1001 1223 3M44 555" }
      let(:invalid_iban) { "MCXX93 2005 2222 1001 1223 3M44 555" }
    end

    it_behaves_like "a country's IBAN", "ME" do
      let(:valid_iban) { "ME25 5050 0001 2345 6789 51" }
      let(:invalid_iban) { "MEXX25 5050 0001 2345 6789 51" }
    end

    it_behaves_like "a country's IBAN", "NL" do
      let(:valid_iban) { "NL39 RABO 0300 0652 64" }
      let(:invalid_iban) { "NLXX39 RABO 0300 0652 64" }
    end

    it_behaves_like "a country's IBAN", "NO" do
      let(:valid_iban) { "NO93 8601 1117 947" }
      let(:invalid_iban) { "NOXX93 8601 1117 947" }
    end

    it_behaves_like "a country's IBAN", "NZ" do
      let(:valid_iban) { "NZZZ5566667777777088" }
      let(:invalid_iban) { "NZXXZZ5566667777777088" }
    end

    it_behaves_like "a country's IBAN", "PK" do
      let(:valid_iban) { "PK36 SCBL 0000 0011 2345 6702" }
      let(:invalid_iban) { "PKXX36 SCBL 0000 0011 2345 6702" }
    end

    it_behaves_like "a country's IBAN", "PL" do
      let(:valid_iban) { "PL60 1020 1026 0000 0422 7020 1111" }
      let(:invalid_iban) { "PLXX60 1020 1026 0000 0422 7020 1111" }
    end

    it_behaves_like "a country's IBAN", "PS" do
      let(:valid_iban) { "PS92 PALS 0000 0000 0400 1234 5670 2" }
      let(:invalid_iban) { "PSXX92 PALS 0000 0000 0400 1234 5670 2" }
    end

    it_behaves_like "a country's IBAN", "PT" do
      let(:valid_iban) { "PT50 0002 0123 1234 5678 9015 4" }
      let(:invalid_iban) { "PTXX50 0002 0123 1234 5678 9015 4" }
    end

    it_behaves_like "a country's IBAN", "QA" do
      let(:valid_iban) { "QA58 DOHB 0000 1234 5678 90AB CDEF G" }
      let(:invalid_iban) { "QAXX58 DOHB 0000 1234 5678 90AB CDEF G" }
    end

    it_behaves_like "a country's IBAN", "XK" do
      let(:valid_iban) { "XK05 1212 0123 4567 8906" }
      let(:invalid_iban) { "XKXX05 1212 0123 4567 8906" }
    end

    it_behaves_like "a country's IBAN", "TL" do
      let(:valid_iban) { "TL38 0080 0123 4567 8910 157" }
      let(:invalid_iban) { "TLXX38 0080 0123 4567 8910 157" }
    end

    it_behaves_like "a country's IBAN", "RO" do
      let(:valid_iban) { "RO49 AAAA 1B31 0075 9384 0000" }
      let(:invalid_iban) { "ROXX49 AAAA 1B31 0075 9384 0000" }
    end

    it_behaves_like "a country's IBAN", "SM" do
      let(:valid_iban) { "SM86 U032 2509 8000 0000 0270 100" }
      let(:invalid_iban) { "SMXX86 U032 2509 8000 0000 0270 100" }
    end

    it_behaves_like "a country's IBAN", "SA" do
      let(:valid_iban) { "SA03 8000 0000 6080 1016 7519" }
      let(:invalid_iban) { "SAXX03 8000 0000 6080 1016 7519" }
    end

    it_behaves_like "a country's IBAN", "RS" do
      let(:valid_iban) { "RS35 2600 0560 1001 6113 79" }
      let(:invalid_iban) { "RSXX35 2600 0560 1001 6113 79" }
    end

    it_behaves_like "a country's IBAN", "SK" do
      let(:valid_iban) { "SK31 1200 0000 1987 4263 7541" }
      let(:invalid_iban) { "SKXX31 1200 0000 1987 4263 7541" }
    end

    it_behaves_like "a country's IBAN", "SI" do
      let(:valid_iban) { "SI56 1910 0000 0123 438" }
      let(:invalid_iban) { "SIXX56 1910 0000 0123 438" }
    end

    it_behaves_like "a country's IBAN", "ES" do
      let(:valid_iban) { "ES80 2310 0001 1800 0001 2345" }
      let(:invalid_iban) { "ESXX80 2310 0001 1800 0001 2345" }
    end

    it_behaves_like "a country's IBAN", "SE" do
      let(:valid_iban) { "SE35 5000 0000 0549 1000 0003" }
      let(:invalid_iban) { "SEXX35 5000 0000 0549 1000 0003" }
    end

    it_behaves_like "a country's IBAN", "CH" do
      let(:valid_iban) { "CH93 0076 2011 6238 5295 7" }
      let(:invalid_iban) { "CHXX93 0076 2011 6238 5295 7" }
    end

    it_behaves_like "a country's IBAN", "TN" do
      let(:valid_iban) { "TN59 1000 6035 1835 9847 8831" }
      let(:invalid_iban) { "TNXX59 1000 6035 1835 9847 8831" }
    end

    it_behaves_like "a country's IBAN", "TR" do
      let(:valid_iban) { "TR33 0006 1005 1978 6457 8413 26" }
      let(:invalid_iban) { "TRXX33 0006 1005 1978 6457 8413 26" }
    end

    it_behaves_like "a country's IBAN", "AE" do
      let(:valid_iban) { "AE07 0331 2345 6789 0123 456" }
      let(:invalid_iban) { "AEXX07 0331 2345 6789 0123 456" }
    end

    it_behaves_like "a country's IBAN", "GB" do
      let(:valid_iban) { "GB82 WEST 1234 5698 7654 32" }
      let(:invalid_iban) { "GBXX82 WEST 1234 5698 7654 32" }
    end

    it_behaves_like "a country's IBAN", "LC" do
      let(:valid_iban) { "LC55 HEMM 0001 0001 0012 0012 0002 3015" }
      let(:invalid_iban) { "LCXX55 HEMM 0001 0001 0012 0012 0002 3015" }
    end

    it_behaves_like "a country's IBAN", "UA" do
      let(:valid_iban) { "UA21 3223 1300 0002 6007 2335 6600 1" }
      let(:invalid_iban) { "UAXX21 3223 1300 0002 6007 2335 6600 1" }
    end

    it_behaves_like "a country's IBAN", "ST" do
      let(:valid_iban) { "ST23 0001 0001 0051 8453 1014 6" }
      let(:invalid_iban) { "STXX23 0001 0001 0051 8453 1014 6" }
    end

    it_behaves_like "a country's IBAN", "SC" do
      let(:valid_iban) { "SC18 SSCB 1101 0000 0000 0000 1497 USD" }
      let(:invalid_iban) { "SCXX18 SSCB 1101 0000 0000 0000 1497 USD" }
    end

    it_behaves_like "a country's IBAN", "IQ" do
      let(:valid_iban) { "IQ98 NBIQ 8501 2345 6789 012" }
      let(:invalid_iban) { "IQXX98 NBIQ 8501 2345 6789 012" }
    end

    it_behaves_like "a country's IBAN", "SV" do
      let(:valid_iban) { "SV 62 CENR 00000000000000700025" }
      let(:invalid_iban) { "SVXX 62 CENR 00000000000000700025" }
    end

    it_behaves_like "a country's IBAN", "BY" do
      let(:valid_iban) { "BY13 NBRB 3600 9000 0000 2Z00 AB00" }
      let(:invalid_iban) { "BYXX13 NBRB 3600 9000 0000 2Z00 AB00" }
    end

    it_behaves_like "a country's IBAN", "VA" do
      let(:valid_iban) { "VA59 001 1230 0001 2345 678" }
      let(:invalid_iban) { "VAXX59 001 1230 0001 2345 678" }
    end

    it_behaves_like "a country's IBAN", "EG" do
      let(:valid_iban) { "EG380019000500000000263180002" }
      let(:invalid_iban) { "EGXX380019000500000000263180002" }
    end

    it_behaves_like "a country's IBAN", "LY" do
      let(:valid_iban) { "LY83002048000020100120361" }
      let(:invalid_iban) { "LYXX83002048000020100120361" }
    end

    it_behaves_like "a country's IBAN", "SD" do
      let(:valid_iban) { "SD2129010501234001" }
      let(:invalid_iban) { "SDXX2129010501234001" }
    end

    it_behaves_like "a country's IBAN", "BI" do
      let(:valid_iban) { "BI4210000100010000332045181" }
      let(:invalid_iban) { "BIXX4210000100010000332045181" }
    end

    it_behaves_like "a country's IBAN", "DJ" do
      let(:valid_iban) { "DJ2100010000000154000100186" }
      let(:invalid_iban) { "DJXX2100010000000154000100186" }
    end

    it_behaves_like "a country's IBAN", "RU" do
      let(:valid_iban) { "RU0204452560040702810412345678901" }
      let(:invalid_iban) { "RUXX0204452560040702810412345678901" }
    end

    it_behaves_like "a country's IBAN", "SO" do
      let(:valid_iban) { "SO211000001001000100141" }
      let(:invalid_iban) { "SO411000001001000100141" }
    end

    it_behaves_like "a country's IBAN", "NI" do
      let(:valid_iban) { "NI45BAPR00000013000003558124" }
      let(:invalid_iban) { "NI55BAPR00000013000003558124" }
    end

    it_behaves_like "a country's IBAN", "FK" do
      let(:valid_iban) { "FK88SC123456789012" }
      let(:invalid_iban) { "FK8SC123456789012" }
    end

    it_behaves_like "a country's IBAN", "OM" do
      let(:valid_iban) { "OM810180000001299123456" }
      let(:invalid_iban) { "OM10180000001299123456" }
    end

    it_behaves_like "a country's IBAN", "YE" do
      let(:valid_iban) { "YE15CBYE0001018861234567891234" }
      let(:invalid_iban) { "YE1CBYE0001018861234567891234" }
    end
  end

  describe "#local_check_digits" do
    context "with a Belgian IBAN" do
      let(:iban_code) { "BE62510007547061" }

      its(:local_check_digits) { is_expected.to eq("61") }
    end

    context "with a French IBAN" do
      let(:iban_code) { "FR1234567890123456789012345" }

      its(:local_check_digits) { is_expected.to eq("45") }
    end

    context "with a Monocan IBAN" do
      let(:iban_code) { "MC9320052222100112233M44555" }

      its(:local_check_digits) { is_expected.to eq("55") }
    end

    context "with a Spanish IBAN" do
      let(:iban_code) { "ES1212345678911234567890" }

      its(:local_check_digits) { is_expected.to eq("91") }
    end

    context "with an Italian IBAN" do
      let(:iban_code) { "IT12A1234567890123456789012" }

      its(:local_check_digits) { is_expected.to eq("A") }
    end

    context "with an Estonian IBAN" do
      let(:iban_code) { "EE382200221020145685" }

      its(:local_check_digits) { is_expected.to eq("5") }
    end

    context "with an Finnish IBAN" do
      let(:iban_code) { "FI2112345600000785" }

      its(:local_check_digits) { is_expected.to eq("5") }
    end

    context "with an Portuguese IBAN" do
      let(:iban_code) { "PT50000201231234567890154" }

      its(:local_check_digits) { is_expected.to eq("54") }
    end

    context "with a Norwegian IBAN" do
      let(:iban_code) { "NO9386011117947" }

      its(:local_check_digits) { is_expected.to eq("7") }
    end

    context "with an Icelandic IBAN" do
      let(:iban_code) { "IS250311260024684606972049" }

      its(:local_check_digits) { is_expected.to eq("4") }
    end

    context "with a Slovakian IBAN" do
      let(:iban_code) { "SK3112000000198742637541" }

      its(:local_check_digits) { is_expected.to eq("9") }
    end

    context "with a Dutch IBAN" do
      let(:iban_code) { "NL91ABNA0417164300" }

      its(:local_check_digits) { is_expected.to eq("0") }
    end
  end
end
