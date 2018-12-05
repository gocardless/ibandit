require "spec_helper"

describe Ibandit::IBAN do
  subject(:iban) { described_class.new(arg) }
  let(:arg) { iban_code }
  let(:iban_code) { "GB82WEST12345698765432" }

  its(:iban) { is_expected.to eq(iban_code) }

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
        its(:account_number) { is_expected.to eq("0123456789") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("0123456789") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ1234560123456789") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 5 digit account number" do
        let(:account_number) { "12345" }

        its(:country_code) { is_expected.to eq("AU") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("123456") }
        its(:account_number) { is_expected.to eq("0000012345") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("0000012345") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ1234560000012345") }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 6 digit account number" do
        let(:account_number) { "123456" }

        its(:country_code) { is_expected.to eq("AU") }
        its(:bank_code) { is_expected.to be_nil }
        its(:branch_code) { is_expected.to eq("123456") }
        its(:account_number) { is_expected.to eq("0000123456") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("0000123456") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ1234560000123456") }
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
        its(:account_number) { is_expected.to eq("0XX1234567") }
        its(:swift_bank_code) { is_expected.to be_nil }
        its(:swift_branch_code) { is_expected.to eq("123456") }
        its(:swift_account_number) { is_expected.to eq("0XX1234567") }
        its(:swift_national_id) { is_expected.to eq("123456") }
        its(:iban) { is_expected.to be_nil }
        its(:pseudo_iban) { is_expected.to eq("AUZZ1234560XX1234567") }
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
    end

    context "when the IBAN was created from an Australian pseudo-IBAN" do
      let(:arg) { "AUZZ123456123456789" }

      its(:country_code) { is_expected.to eq("AU") }
      its(:bank_code) { is_expected.to be_nil }
      its(:branch_code) { is_expected.to eq("123456") }
      its(:account_number) { is_expected.to eq("0123456789") }
      its(:swift_bank_code) { is_expected.to be_nil }
      its(:swift_branch_code) { is_expected.to eq("123456") }
      its(:swift_account_number) { is_expected.to eq("0123456789") }
      its(:swift_national_id) { is_expected.to eq("123456") }
      its(:iban) { is_expected.to be_nil }
      its(:pseudo_iban) { is_expected.to eq("AUZZ1234560123456789") }
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
          to eq(account_number: "is the wrong length (should be 10 characters)")
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
          account_number: "is the wrong length (should be 10 characters)",
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
        expect(subject.errors).to eq(account_number: "is invalid",
                                     branch_code: "is invalid")
      end
    end

    context "when the IBAN was created with local details for Canada" do
      let(:arg) do
        {
          country_code: "CA",
          bank_code: "0036",
          branch_code: "00063",
          account_number: account_number,
        }
      end

      context "and a 7 digit account number" do
        let(:account_number) { "0123456" }

        its(:country_code) { is_expected.to eq("CA") }
        its(:bank_code) { is_expected.to eq("0036") }
        its(:branch_code) { is_expected.to eq("00063") }
        its(:account_number) { is_expected.to eq("000000123456") }
        its(:swift_bank_code) { is_expected.to eq("0036") }
        its(:swift_branch_code) { is_expected.to eq("00063") }
        its(:swift_account_number) { is_expected.to eq("000000123456") }
        its(:swift_national_id) { is_expected.to eq("0036") }
        its(:pseudo_iban) { is_expected.to eq("CAZZ003600063000000123456") }

        its(:iban) { is_expected.to be_nil }
        its(:valid?) { is_expected.to eq(true) }
        its(:to_s) { is_expected.to eq("") }
      end

      context "and a 12 digit account number" do
        let(:account_number) { "012345678900" }

        its(:country_code) { is_expected.to eq("CA") }
        its(:bank_code) { is_expected.to eq("0036") }
        its(:branch_code) { is_expected.to eq("00063") }
        its(:account_number) { is_expected.to eq("012345678900") }
        its(:swift_bank_code) { is_expected.to eq("0036") }
        its(:swift_branch_code) { is_expected.to eq("00063") }
        its(:swift_account_number) { is_expected.to eq("012345678900") }
        its(:swift_national_id) { is_expected.to eq("0036") }
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
      its(:account_number) { is_expected.to eq("000000123456") }
      its(:swift_bank_code) { is_expected.to eq("0036") }
      its(:swift_branch_code) { is_expected.to eq("00063") }
      its(:swift_account_number) { is_expected.to eq("000000123456") }
      its(:pseudo_iban) { is_expected.to eq("CAZZ003600063000000123456") }

      its(:iban) { is_expected.to be_nil }
      its(:valid?) { is_expected.to be true }
      its(:to_s) { is_expected.to eq("") }
    end

    context "when the input is an invalid Canadian pseudo-IBAN" do
      let(:arg) { "CAZZ00360006301234" }

      it "is invalid and has the correct errors" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors).
          to eq(account_number: "is the wrong length (should be 12 characters)")
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_country_code?
          expect(iban.errors).
            to include(country_code: "'AA' is not a valid ISO 3166-1 IBAN " \
                                     "country code")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_country_code?
          expect(iban.errors).
            to include(country_code: "'AA' ist kein gültiges " \
                                     "IBAN-Länderkennzeichen gemäß ISO 3166-1")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_country_code?
          expect(iban.errors).
            to include(country_code: "'AA' não corresponde a um código de " \
                                     "país do IBAN válido segundo a norma " \
                                     "ISO 3166-1")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_country_code?
          expect(iban.errors).
            to include(country_code: "'AA' is geen geldig ISO 3166-1 IBAN " \
                                     "landcode")
        end
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Check digits failed modulus check. " \
                                     "Expected '82', received '12'.")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Les chiffres de contrôle n'ont pas " \
                                     "satisfait au contrôle de validité. " \
                                     "Attendus '82', reçus '12'.")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Prüfziffer hat Betragsprüfung nicht " \
                                     "bestanden. (82 Zeichen erwartet, 12 " \
                                     "angegeben).")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Verifique os dígitos. A verificação " \
                                     "do módulo falhou. '82' esperados, '12'" \
                                     " recebidos.")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Los dígitos de verificación han " \
                                     "generado un error en la comprobación " \
                                     "del módulo. Se esperaba \"82\", pero " \
                                     "se ha recibido \"12\".")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Controllo del modulo non riuscito per " \
                                     "i caratteri. 82 caratteri previsti, 12 " \
                                     "immessi.")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Controlegetal mislukte modulus check. " \
                                     "Verwachte '82', ontvangen '12'.")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Tallkontrollen mislyktes i " \
                                     "moduluskontrollen. Forventet '82'" \
                                     ", mottok '12'.")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Številke čeka niso uspešno prestale " \
                                     "preverjanja modula. Pričakovano '82', " \
                                     "prejeto '12'.")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Kontrolcifre bestod ikke modulustjek. " \
                                     "Forventede '82'; modtog '12'.")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: "Kontrollera felaktiga siffror med " \
                                     "modulkontroll. Förväntade '82', " \
                                     "mottagna '12'.")
        end
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "Length doesn't match SWIFT specification " \
                       "(expected 22 characters, received 20)")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "La longueur ne correspond pas à la " \
                               "spécification SWIFT (22 caractères attendus," \
                               " 20 reçus)")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "Länge entspricht nicht der " \
                               "SWIFT-Spezifikation (22 Zeichen erwartet, " \
                               "20 angegeben)")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "O comprimento não corresponde à especificação" \
                               " do código SWIFT (22 caracteres esperados, 20" \
                               " recebidos)")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "La longitud no coincide con la especificación" \
                               " SWIFT (se esperaban 22 caracteres, pero se " \
                               "han recibido 20)")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "La lunghezza non corrisponde alla specifica " \
                               "SWIFT (22 caratteri previsti, 20 immessi)")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "Lengte komt niet overeen met SWIFT-" \
                               "specificatie (verwachte 22 karakters, " \
                               "ontvangen 20)")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "Lengden samsvarer ikke med " \
                               "SWIFT-spesifikasjonene (forventet 22 tegn, " \
                               "mottok 20)")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "Dolžina se ne ujema z opredelitvijo za " \
                               "kodo SWIFT (pričakovani znaki: 22, " \
                               "prejeti znaki: 20)")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "Længden modsvarer ikke SWIFT-specifikation" \
                               " (forventede 22 tegn, modtog 20)")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "Längd matchar inte förväntad " \
                               "SWIFT-specifikation (förväntade 22 tecken, " \
                               "mottagna 20)")
        end
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "is the wrong length (should be 4 " \
                                  "characters)")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "est une longueur incorrecte (doit " \
                                  "contenir 4 caractères)")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "hat nicht die richtige Länge (sollte " \
                                  "4 Zeichen haben)")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "não tem o comprimento correto (deve " \
                                  "ter 4 caracteres)")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "no tiene la longitud correcta (debe " \
                                  "tener 4 caracteres)")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "non ha la lunghezza richiesta (deve " \
                                  "essere di 4 caratteri)")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "heeft onjuiste lengte (moet 4 tekens " \
                                  "lang zijn)")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "har feil lengde (skal være 4 tegn)")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "je napačne dolžine (biti mora 4 znakov)")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "har forkert længde (skulle være 4 tegn)")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "har fel längd (bör vara 4 tecken)")
        end
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "is the wrong length (should be 6 " \
                       "characters)")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "est une longueur incorrecte (doit " \
                                    "contenir 6 caractères)")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "hat nicht die richtige Länge (sollte " \
                                    "6 Zeichen haben)")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "não tem o comprimento correto (deve " \
                                    "ter 6 caracteres)")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "no tiene la longitud correcta (debe " \
                                    "tener 6 caracteres)")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "non ha la lunghezza richiesta (deve " \
                                    "essere di 6 caratteri)")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "heeft onjuiste lengte (moet 6 tekens " \
                                    "lang zijn)")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "har feil lengde (skal være 6 tegn)")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "je napačne dolžine (biti mora 6 znakov)")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "har forkert længde (skulle være 6 tegn)")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "har fel längd (bör vara 6 tecken)")
        end
      end
    end

    context "without a branch code" do
      before { allow(iban).to receive(:swift_branch_code).and_return(nil) }
      it { is_expected.to eq(false) }

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "is required")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "est obligatoire")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "ist erforderlich")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "é obrigatório")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "es obligatorio")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "è obbligatorio")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "moet opgegeven zijn")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "er påkrevd")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "je obvezno")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "er påkrævet")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: "krävs")
        end
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "is the wrong length (should be 8 " \
                                       "characters)")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "est une longueur incorrecte (doit " \
                                       "contenir 8 caractères)")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "hat nicht die richtige Länge (sollte " \
                                       "8 Zeichen haben)")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "não tem o comprimento correto (deve " \
                                       "ter 8 caracteres)")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "no tiene la longitud correcta (debe " \
                                       "tener 8 caracteres)")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "non ha la lunghezza richiesta (deve " \
                                       "essere di 8 caratteri)")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "heeft onjuiste lengte (moet 8 " \
                                       "tekens lang zijn)")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "har feil lengde (skal være 8 tegn)")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "je napačne dolžine (biti mora 8" \
                                       " znakov)")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "har forkert længde (skulle være 8" \
                                       " tegn)")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "har fel längd (bör vara 8 tecken)")
        end
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Non-alphanumeric characters found: -")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Caractères non alphanumériques trouvés : -")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Nicht-alphanumerischen Zeichen gefunden: -")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Caracteres não alfanuméricos " \
                                   "encontrados: -")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Se han encontrado caracteres no " \
                                   "alfanuméricos: -")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Caratteri non alfanumerici trovati: -")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Niet-alfanumerieke tekens gevonden: -")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Ikke-alfanumeriske tegn funnet: -")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Najdeni ne-alfanumerični znaki: -")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Ikke-alfanumeriske tegn registreret: -")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: "Icke alfanumeriska tecken hittades: -")
        end
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Unexpected format for a GB IBAN.")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Format non attendu pour un IBAN GB.")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Unerwartetes Format für eine GB-IBAN.")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Formato inesperado para um IBAN GB.")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Formato inesperado para un IBAN de GB.")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Formato imprevisto per un IBAN GB.")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Onverwachte formaat voor een GB IBAN.")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Uventet format for IBAN for GB.")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Nepričakovana oblika zapisa GB v IBAN.")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Uventet format for en IBAN fra GB.")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Oväntat format för GB IBAN.")
        end
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "is invalid")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "n'est pas valide")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "ist ungültig")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "é inválido")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "no es válido")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "non è valido")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "is ongeldig")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "er ikke gyldig")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "ni veljavno")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "er ugyldig")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: "är ogiltig")
        end
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "is invalid")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "n'est pas valide")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "ist ungültig")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "é inválido")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "no es válido")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "non è valido")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "is ongeldig")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "er ikke gyldig")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "ni veljavno")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "er ugyldig")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: "är ogiltig")
        end
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

      context "locale en", locale: :en do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "is invalid")
        end
      end

      context "locale fr", locale: :fr do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "n'est pas valide")
        end
      end

      context "locale de", locale: :de do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "ist ungültig")
        end
      end

      context "locale pt", locale: :pt do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "é inválido")
        end
      end

      context "locale es", locale: :es do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "no es válido")
        end
      end

      context "locale it", locale: :it do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "non è valido")
        end
      end

      context "locale nl", locale: :nl do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "is ongeldig")
        end
      end

      context "locale nb", locale: :nb do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "er ikke gyldig")
        end
      end

      context "locale sl", locale: :sl do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "ni veljavno")
        end
      end

      context "locale da", locale: :da do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "er ugyldig")
        end
      end

      context "locale sv", locale: :sv do
        it "sets errors on the IBAN" do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: "är ogiltig")
        end
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
      end
      after { Ibandit.modulus_checker = nil }
      before { iban.valid_local_modulus_check? }

      context "with an invalid bank code" do
        let(:iban_code) { "AT611904300234573201" }
        let(:valid_bank_code) { false }
        let(:valid_branch_code) { true }
        let(:valid_account_number) { true }

        it "calls valid_bank_code? with an IBAN object" do
          expect(Ibandit.modulus_checker).
            to receive(:valid_bank_code?).
            with(instance_of(Ibandit::IBAN))

          iban.valid_local_modulus_check?
        end

        it { is_expected.to be(false) }

        context "locale en", locale: :en do
          specify { expect(iban.errors).to include(bank_code: "is invalid") }
        end

        context "locale fr", locale: :fr do
          specify do
            expect(iban.errors).to include(bank_code: "n'est pas valide")
          end
        end

        context "locale de", locale: :de do
          specify do
            expect(iban.errors).to include(bank_code: "ist ungültig")
          end
        end

        context "locale pt", locale: :pt do
          specify { expect(iban.errors).to include(bank_code: "é inválido") }
        end

        context "locale es", locale: :es do
          specify { expect(iban.errors).to include(bank_code: "no es válido") }
        end

        context "locale it", locale: :it do
          specify { expect(iban.errors).to include(bank_code: "non è valido") }
        end

        context "locale nl", locale: :nl do
          specify { expect(iban.errors).to include(bank_code: "is ongeldig") }
        end

        context "locale nb", locale: :nb do
          specify do
            expect(iban.errors).to include(bank_code: "er ikke gyldig")
          end
        end

        context "locale sl", locale: :sl do
          specify { expect(iban.errors).to include(bank_code: "ni veljavno") }
        end

        context "locale da", locale: :da do
          specify { expect(iban.errors).to include(bank_code: "er ugyldig") }
        end

        context "locale sv", locale: :sv do
          specify { expect(iban.errors).to include(bank_code: "är ogiltig") }
        end
      end

      context "with an invalid branch code" do
        let(:iban_code) { "GB60BARC20000055779911" }
        before { Ibandit.bic_finder = double(call: "BARCGB22XXX") }
        after { Ibandit.bic_finder = nil }
        before { iban.valid_local_modulus_check? }
        let(:valid_bank_code) { true }
        let(:valid_branch_code) { false }
        let(:valid_account_number) { true }

        it "calls valid_branch_code? with an IBAN object" do
          expect(Ibandit.modulus_checker).
            to receive(:valid_branch_code?).
            with(instance_of(Ibandit::IBAN))

          iban.valid_local_modulus_check?
        end

        it { is_expected.to be(false) }

        context "locale en", locale: :en do
          specify do
            expect(iban.errors).to include(branch_code: "is invalid")
          end
        end

        context "locale fr", locale: :fr do
          specify do
            expect(iban.errors).to include(branch_code: "n'est pas valide")
          end
        end

        context "locale de", locale: :de do
          specify do
            expect(iban.errors).to include(branch_code: "ist ungültig")
          end
        end

        context "locale pt", locale: :pt do
          specify do
            expect(iban.errors).to include(branch_code: "é inválido")
          end
        end

        context "locale es", locale: :es do
          specify do
            expect(iban.errors).to include(branch_code: "no es válido")
          end
        end

        context "locale it", locale: :it do
          specify do
            expect(iban.errors).to include(branch_code: "non è valido")
          end
        end

        context "locale nl", locale: :nl do
          specify do
            expect(iban.errors).to include(branch_code: "is ongeldig")
          end
        end

        context "locale nb", locale: :nb do
          specify do
            expect(iban.errors).to include(branch_code: "er ikke gyldig")
          end
        end

        context "locale sl", locale: :sl do
          specify do
            expect(iban.errors).to include(branch_code: "ni veljavno")
          end
        end

        context "locale da", locale: :da do
          specify do
            expect(iban.errors).to include(branch_code: "er ugyldig")
          end
        end

        context "locale sv", locale: :sv do
          specify do
            expect(iban.errors).to include(branch_code: "är ogiltig")
          end
        end
      end

      context "with an invalid account number" do
        let(:valid_bank_code) { true }
        let(:valid_branch_code) { true }
        let(:valid_account_number) { false }

        it "calls valid_account_number? with an IBAN object" do
          expect(Ibandit.modulus_checker).
            to receive(:valid_account_number?).
            with(instance_of(Ibandit::IBAN))

          iban.valid_local_modulus_check?
        end

        it { is_expected.to be(false) }

        context "locale en", locale: :en do
          specify do
            expect(iban.errors).to include(account_number: "is invalid")
          end
        end

        context "locale fr", locale: :fr do
          specify do
            expect(iban.errors).to include(account_number: "n'est pas valide")
          end
        end

        context "locale de", locale: :de do
          specify do
            expect(iban.errors).to include(account_number: "ist ungültig")
          end
        end

        context "locale pt", locale: :pt do
          specify do
            expect(iban.errors).to include(account_number: "é inválido")
          end
        end

        context "locale es", locale: :es do
          specify do
            expect(iban.errors).to include(account_number: "no es válido")
          end
        end

        context "locale it", locale: :it do
          specify do
            expect(iban.errors).to include(account_number: "non è valido")
          end
        end

        context "locale nl", locale: :nl do
          specify do
            expect(iban.errors).to include(account_number: "is ongeldig")
          end
        end

        context "locale nb", locale: :nb do
          specify do
            expect(iban.errors).to include(account_number: "er ikke gyldig")
          end
        end

        context "locale sl", locale: :sl do
          specify do
            expect(iban.errors).to include(account_number: "ni veljavno")
          end
        end

        context "locale da", locale: :da do
          specify do
            expect(iban.errors).to include(account_number: "er ugyldig")
          end
        end

        context "locale sv", locale: :sv do
          specify do
            expect(iban.errors).to include(account_number: "är ogiltig")
          end
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

        context "locale en", locale: :en do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "does not support payments")
          end
        end

        context "locale fr", locale: :fr do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "ne prend pas en charge les paiements")
          end
        end

        context "locale de", locale: :de do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "unterstützt keine Zahlungen")
          end
        end

        context "locale pt", locale: :pt do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "não suporta pagamentos")
          end
        end

        context "locale es", locale: :es do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "no admite pagos")
          end
        end

        context "locale it", locale: :it do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "non supporta i pagamenti")
          end
        end

        context "locale nl", locale: :nl do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "ondersteunt geen betalingen")
          end
        end

        context "locale nb", locale: :nb do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "støtter ikke betalinger")
          end
        end

        context "locale sl", locale: :sl do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "ne podpira plačil")
          end
        end

        context "locale da", locale: :da do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "understøtter ikke betalinger")
          end
        end

        context "locale sv", locale: :sv do
          specify do
            iban.supports_iban_determination?
            expect(iban.errors).
              to include(account_number: "stödjer inte betalningar")
          end
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

          context "locale en", locale: :en do
            specify do
              iban.valid_swedish_details?
              expect(iban.errors).to eq(account_number: "is invalid")
            end
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

          context "locale en", locale: :en do
            specify do
              iban.valid?
              expect(iban.errors).to include(account_number: "is invalid")
              expect(iban.errors).to_not include(:bank_code)
            end
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

          context "locale en", locale: :en do
            specify do
              iban.valid_swedish_details?
              expect(iban.errors).to eq(account_number: "is invalid")
            end
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

          context "locale en", locale: :en do
            specify do
              iban.valid_swedish_details?
              expect(iban.errors).to eq(branch_code: "is invalid")
            end
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

          context "locale en", locale: :en do
            specify do
              iban.valid_swedish_details?
              expect(iban.errors).to eq(account_number: "is invalid")
            end
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
            with(instance_of(Ibandit::IBAN))

          iban.valid_australian_details?
        end

        it { is_expected.to be(true) }

        context "with an invalid bsb" do
          let(:valid_branch_code) { false }

          it { is_expected.to be(false) }

          context "locale en", locale: :en do
            specify do
              expect(iban.errors).to include(branch_code: "is invalid")
            end
          end

          context "locale fr", locale: :fr do
            specify do
              expect(iban.errors).to include(branch_code: "n'est pas valide")
            end
          end

          context "locale de", locale: :de do
            specify do
              expect(iban.errors).to include(branch_code: "ist ungültig")
            end
          end

          context "locale pt", locale: :pt do
            specify do
              expect(iban.errors).to include(branch_code: "é inválido")
            end
          end

          context "locale es", locale: :es do
            specify do
              expect(iban.errors).to include(branch_code: "no es válido")
            end
          end

          context "locale it", locale: :it do
            specify do
              expect(iban.errors).to include(branch_code: "non è valido")
            end
          end

          context "locale nl", locale: :nl do
            specify do
              expect(iban.errors).to include(branch_code: "is ongeldig")
            end
          end

          context "locale nb", locale: :nb do
            specify do
              expect(iban.errors).to include(branch_code: "er ikke gyldig")
            end
          end

          context "locale sl", locale: :sl do
            specify do
              expect(iban.errors).to include(branch_code: "ni veljavno")
            end
          end

          context "locale da", locale: :da do
            specify do
              expect(iban.errors).to include(branch_code: "er ugyldig")
            end
          end

          context "locale sv", locale: :sv do
            specify do
              expect(iban.errors).to include(branch_code: "är ogiltig")
            end
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
            with(instance_of(Ibandit::IBAN))

          iban.valid_nz_details?
        end

        it { is_expected.to be(true) }

        context "with an invalid branch code" do
          let(:valid_branch_code) { false }

          it { is_expected.to be(false) }

          context "locale en", locale: :en do
            specify do
              expect(iban.errors).to include(branch_code: "is invalid")
            end
          end

          context "locale fr", locale: :fr do
            specify do
              expect(iban.errors).to include(branch_code: "n'est pas valide")
            end
          end

          context "locale de", locale: :de do
            specify do
              expect(iban.errors).to include(branch_code: "ist ungültig")
            end
          end

          context "locale pt", locale: :pt do
            specify do
              expect(iban.errors).to include(branch_code: "é inválido")
            end
          end

          context "locale es", locale: :es do
            specify do
              expect(iban.errors).to include(branch_code: "no es válido")
            end
          end

          context "locale it", locale: :it do
            specify do
              expect(iban.errors).to include(branch_code: "non è valido")
            end
          end

          context "locale nl", locale: :nl do
            specify do
              expect(iban.errors).to include(branch_code: "is ongeldig")
            end
          end

          context "locale nb", locale: :nb do
            specify do
              expect(iban.errors).to include(branch_code: "er ikke gyldig")
            end
          end

          context "locale sl", locale: :sl do
            specify do
              expect(iban.errors).to include(branch_code: "ni veljavno")
            end
          end

          context "locale da", locale: :da do
            specify do
              expect(iban.errors).to include(branch_code: "er ugyldig")
            end
          end

          context "locale sv", locale: :sv do
            specify do
              expect(iban.errors).to include(branch_code: "är ogiltig")
            end
          end
        end
      end
    end
  end

  describe "#valid?" do
    describe "validations called" do
      after { iban.valid? }

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
    end

    context "for a valid Albanian IBAN" do
      let(:iban_code) { "AL47 2121 1009 0000 0002 3569 8741" }
      it { is_expected.to be_valid }
    end

    context "for a valid Andorran IBAN" do
      let(:iban_code) { "AD12 0001 2030 2003 5910 0100" }
      it { is_expected.to be_valid }
    end

    context "for a valid Austrian IBAN" do
      let(:iban_code) { "AT61 1904 3002 3457 3201" }
      it { is_expected.to be_valid }
    end

    context "for a valid Australian pseudo-IBAN" do
      let(:iban_code) { "AUZZ123456123456789" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Australian pseudo-IBAN" do
      let(:iban_code) { "AU99123456123456789" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Azerbaijanian IBAN" do
      let(:iban_code) { "AZ21 NABZ 0000 0000 1370 1000 1944" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Azerbaijanian IBAN" do
      let(:iban_code) { "AZ91 NABZ 0000 0000 1370 1000 1944" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Bahrainian IBAN" do
      let(:iban_code) { "BH67 BMAG 0000 1299 1234 56" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Bahrainian IBAN" do
      let(:iban_code) { "BH97 BMAG 0000 1299 1234 56" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Belgian IBAN" do
      let(:iban_code) { "BE62 5100 0754 7061" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Belgian IBAN" do
      let(:iban_code) { "BE92 5100 0754 7061" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Bosnian IBAN" do
      let(:iban_code) { "BA39 1290 0794 0102 8494" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Bosnian IBAN" do
      let(:iban_code) { "BA99 1290 0794 0102 8494" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Bulgarian IBAN" do
      let(:iban_code) { "BG80 BNBG 9661 1020 3456 78" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Bulgarian IBAN" do
      let(:iban_code) { "BG90 BNBG 9661 1020 3456 78" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Croatian IBAN" do
      let(:iban_code) { "HR12 1001 0051 8630 0016 0" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Croatian IBAN" do
      let(:iban_code) { "HR92 1001 0051 8630 0016 0" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Cypriot IBAN" do
      let(:iban_code) { "CY17 0020 0128 0000 0012 0052 7600" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Cypriot IBAN" do
      let(:iban_code) { "CY97 0020 0128 0000 0012 0052 7600" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Czech IBAN" do
      let(:iban_code) { "CZ65 0800 0000 1920 0014 5399" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Czech IBAN" do
      let(:iban_code) { "CZ95 0800 0000 1920 0014 5399" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Danish IBAN" do
      let(:iban_code) { "DK50 0040 0440 1162 43" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Danish IBAN" do
      let(:iban_code) { "DK90 0040 0440 1162 43" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Estonian IBAN" do
      let(:iban_code) { "EE38 2200 2210 2014 5685" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Estonian IBAN" do
      let(:iban_code) { "EE98 2200 2210 2014 5685" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Faroe Islands IBAN" do
      let(:iban_code) { "FO97 5432 0388 8999 44" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Faroe Islands IBAN" do
      let(:iban_code) { "FO27 5432 0388 8999 44" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Finnish IBAN" do
      let(:iban_code) { "FI21 1234 5600 0007 85" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Finnish IBAN" do
      let(:iban_code) { "FI91 1234 5600 0007 85" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid French IBAN" do
      let(:iban_code) { "FR14 2004 1010 0505 0001 3M02 606" }
      it { is_expected.to be_valid }
    end

    context "for an invalid French IBAN" do
      let(:iban_code) { "FR94 2004 1010 0505 0001 3M02 606" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Georgian IBAN" do
      let(:iban_code) { "GE29 NB00 0000 0101 9049 17" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Georgian IBAN" do
      let(:iban_code) { "GE99 NB00 0000 0101 9049 17" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid German IBAN" do
      let(:iban_code) { "DE89 3704 0044 0532 0130 00" }
      it { is_expected.to be_valid }
    end

    context "for an invalid German IBAN" do
      let(:iban_code) { "DE99 3704 0044 0532 0130 00" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Gibraltan IBAN" do
      let(:iban_code) { "GI75 NWBK 0000 0000 7099 453" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Gibraltan IBAN" do
      let(:iban_code) { "GI95 NWBK 0000 0000 7099 453" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Greek IBAN" do
      let(:iban_code) { "GR16 0110 1250 0000 0001 2300 695" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Greek IBAN" do
      let(:iban_code) { "GR96 0110 1250 0000 0001 2300 695" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Greenland IBAN" do
      let(:iban_code) { "GL56 0444 9876 5432 10" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Greenland IBAN" do
      let(:iban_code) { "GL96 0444 9876 5432 10" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Hungarian IBAN" do
      let(:iban_code) { "HU42 1177 3016 1111 1018 0000 0000" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Hungarian IBAN" do
      let(:iban_code) { "HU92 1177 3016 1111 1018 0000 0000" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Icelandic IBAN" do
      let(:iban_code) { "IS14 0159 2600 7654 5510 7303 39" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Icelandic IBAN" do
      let(:iban_code) { "IS94 0159 2600 7654 5510 7303 39" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Irish IBAN" do
      let(:iban_code) { "IE29 AIBK 9311 5212 3456 78" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Irish IBAN" do
      let(:iban_code) { "IE99 AIBK 9311 5212 3456 78" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Israeli IBAN" do
      let(:iban_code) { "IL62 0108 0000 0009 9999 999" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Israeli IBAN" do
      let(:iban_code) { "IL92 0108 0000 0009 9999 999" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Italian IBAN" do
      let(:iban_code) { "IT40 S054 2811 1010 0000 0123 456" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Italian IBAN" do
      let(:iban_code) { "IT90 S054 2811 1010 0000 0123 456" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Jordanian IBAN" do
      let(:iban_code) { "JO94 CBJO 0010 0000 0000 0131 0003 02" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Jordanian IBAN" do
      let(:iban_code) { "JO24 CBJO 0010 0000 0000 0131 0003 02" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Kuwaiti IBAN" do
      let(:iban_code) { "KW81 CBKU 0000 0000 0000 1234 5601 01" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Kuwaiti IBAN" do
      let(:iban_code) { "KW91 CBKU 0000 0000 0000 1234 5601 01" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Latvian IBAN" do
      let(:iban_code) { "LV80 BANK 0000 4351 9500 1" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Latvian IBAN" do
      let(:iban_code) { "LV90 BANK 0000 4351 9500 1" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Lebanese IBAN" do
      let(:iban_code) { "LB62 0999 0000 0001 0019 0122 9114" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Lebanese IBAN" do
      let(:iban_code) { "LB92 0999 0000 0001 0019 0122 9114" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Liechtensteinian IBAN" do
      let(:iban_code) { "LI21 0881 0000 2324 013A A" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Liechtensteinian IBAN" do
      let(:iban_code) { "LI91 0881 0000 2324 013A A" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Lithuanian IBAN" do
      let(:iban_code) { "LT12 1000 0111 0100 1000" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Lithuanian IBAN" do
      let(:iban_code) { "LT92 1000 0111 0100 1000" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Luxembourgian IBAN" do
      let(:iban_code) { "LU28 0019 4006 4475 0000" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Luxembourgian IBAN" do
      let(:iban_code) { "LU98 0019 4006 4475 0000" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Macedonian IBAN" do
      let(:iban_code) { "MK072 5012 0000 0589 84" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Macedonian IBAN" do
      let(:iban_code) { "MK972 5012 0000 0589 84" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Maltese IBAN" do
      let(:iban_code) { "MT84 MALT 0110 0001 2345 MTLC AST0 01S" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Maltese IBAN" do
      let(:iban_code) { "MT94 MALT 0110 0001 2345 MTLC AST0 01S" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Maurititanian IBAN" do
      let(:iban_code) { "MU17 BOMM 0101 1010 3030 0200 000M UR" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Maurititanian IBAN" do
      let(:iban_code) { "MU97 BOMM 0101 1010 3030 0200 000M UR" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Moldovan IBAN" do
      let(:iban_code) { "MD24 AG00 0225 1000 1310 4168" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Moldovan IBAN" do
      let(:iban_code) { "MD94 AG00 0225 1000 1310 4168" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Monocan IBAN" do
      let(:iban_code) { "MC93 2005 2222 1001 1223 3M44 555" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Monocan IBAN" do
      let(:iban_code) { "MC23 2005 2222 1001 1223 3M44 555" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Montenegrian IBAN" do
      let(:iban_code) { "ME25 5050 0001 2345 6789 51" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Montenegrian IBAN" do
      let(:iban_code) { "ME95 5050 0001 2345 6789 51" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Dutch IBAN" do
      let(:iban_code) { "NL39 RABO 0300 0652 64" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Dutch IBAN" do
      let(:iban_code) { "NL99 RABO 0300 0652 64" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Norwegian IBAN" do
      let(:iban_code) { "NO93 8601 1117 947" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Norwegian IBAN" do
      let(:iban_code) { "NO23 8601 1117 947" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid New Zealand pseudo-IBAN" do
      let(:iban_code) { "NZZZ5566667777777088" }
      it { is_expected.to be_valid }
    end

    context "for an invalid New Zealand pseudo-IBAN" do
      let(:iban_code) { "NZZZ55666677777770888" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Pakistani IBAN" do
      let(:iban_code) { "PK36 SCBL 0000 0011 2345 6702" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Pakistani IBAN" do
      let(:iban_code) { "PK96 SCBL 0000 0011 2345 6702" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Polish IBAN" do
      let(:iban_code) { "PL60 1020 1026 0000 0422 7020 1111" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Polish IBAN" do
      let(:iban_code) { "PL90 1020 1026 0000 0422 7020 1111" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Potuguese IBAN" do
      let(:iban_code) { "PT50 0002 0123 1234 5678 9015 4" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Potuguese IBAN" do
      let(:iban_code) { "PT90 0002 0123 1234 5678 9015 4" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Qatari IBAN" do
      let(:iban_code) { "QA58 DOHB 0000 1234 5678 90AB CDEF G" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Qatari IBAN" do
      let(:iban_code) { "QA98 DOHB 0000 1234 5678 90AB CDEF G" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Romanian IBAN" do
      let(:iban_code) { "RO49 AAAA 1B31 0075 9384 0000" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Romanian IBAN" do
      let(:iban_code) { "RO99 AAAA 1B31 0075 9384 0000" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid San Marinian IBAN" do
      let(:iban_code) { "SM86 U032 2509 8000 0000 0270 100" }
      it { is_expected.to be_valid }
    end

    context "for an invalid San Marinian IBAN" do
      let(:iban_code) { "SM96 U032 2509 8000 0000 0270 100" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Saudi IBAN" do
      let(:iban_code) { "SA03 8000 0000 6080 1016 7519" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Saudi IBAN" do
      let(:iban_code) { "SA93 8000 0000 6080 1016 7519" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Serbian IBAN" do
      let(:iban_code) { "RS35 2600 0560 1001 6113 79" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Serbian IBAN" do
      let(:iban_code) { "RS95 2600 0560 1001 6113 79" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Slovakian IBAN" do
      let(:iban_code) { "SK31 1200 0000 1987 4263 7541" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Slovakian IBAN" do
      let(:iban_code) { "SK91 1200 0000 1987 4263 7541" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Slovenian IBAN" do
      let(:iban_code) { "SI56 1910 0000 0123 438" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Slovenian IBAN" do
      let(:iban_code) { "SI96 1910 0000 0123 438" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Spanish IBAN" do
      let(:iban_code) { "ES80 2310 0001 1800 0001 2345" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Spanish IBAN" do
      let(:iban_code) { "ES90 2310 0001 1800 0001 2345" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Swedish IBAN" do
      let(:iban_code) { "SE35 5000 0000 0549 1000 0003" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Swedish IBAN" do
      let(:iban_code) { "SE95 5000 0000 0549 1000 0003" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Swiss IBAN" do
      let(:iban_code) { "CH93 0076 2011 6238 5295 7" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Swiss IBAN" do
      let(:iban_code) { "CH23 0076 2011 6238 5295 7" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Tunisian IBAN" do
      let(:iban_code) { "TN59 1000 6035 1835 9847 8831" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Tunisian IBAN" do
      let(:iban_code) { "TN99 1000 6035 1835 9847 8831" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid Turkish IBAN" do
      let(:iban_code) { "TR33 0006 1005 1978 6457 8413 26" }
      it { is_expected.to be_valid }
    end

    context "for an invalid Turkish IBAN" do
      let(:iban_code) { "TR93 0006 1005 1978 6457 8413 26" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid UAE IBAN" do
      let(:iban_code) { "AE07 0331 2345 6789 0123 456" }
      it { is_expected.to be_valid }
    end

    context "for an invalid UAE IBAN" do
      let(:iban_code) { "AE97 0331 2345 6789 0123 456" }
      it { is_expected.to_not be_valid }
    end

    context "for a valid UK IBAN" do
      let(:iban_code) { "GB82 WEST 1234 5698 7654 32" }
      it { is_expected.to be_valid }
    end

    context "for an invalid UK IBAN" do
      let(:iban_code) { "GB92 WEST 1234 5698 7654 32" }
      it { is_expected.to_not be_valid }
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
