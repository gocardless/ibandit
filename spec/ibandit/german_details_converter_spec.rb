require "spec_helper"

describe Ibandit::GermanDetailsConverter do
  shared_examples "json based fixture" do |json_fixture_file|
    json_fixture(json_fixture_file).each do |convertor|
      context "Rule #{convertor['convertor']}" do
        let(:klass) do
          described_class.const_get("Rule#{convertor['convertor']}")
        end

        subject { test_subject }

        before do
          expect_any_instance_of(klass).to receive(:converted_details).
            and_call_original
        end

        convertor.fetch("valid", []).each do |tuple|
          context "bank code: #{tuple['bank_code']} account number " \
            "#{tuple['account_number']}" do
            let(:bank_code) do
              tuple["bank_code"]
            end
            let(:account_number) do
              tuple["account_number"]
            end
            let(:converted_bank_code) do
              tuple["converted_bank_code"] || bank_code
            end
            let(:converted_account_number) do
              tuple["converted_account_number"] || account_number
            end
            it do
              is_expected.to eq(
                bank_code: converted_bank_code,
                account_number: converted_account_number,
              )
            end
          end
        end

        convertor.fetch("invalid", []).each do |tuple|
          context "bank code: #{tuple['bank_code']} account number " \
            "#{tuple['account_number']}" do
            let(:bank_code) { tuple["bank_code"] || "00000000" }
            let(:account_number) { tuple["account_number"] }
            it "raises UnsupportedAccountDetails" do
              expect { subject }.
                to raise_error(Ibandit::UnsupportedAccountDetails)
            end
          end
        end
      end
    end
  end

  describe "integration tests" do
    include_examples "json based fixture", "germany_integration_test_cases" do
      let(:test_subject) do
        described_class.
          convert(bank_code: bank_code, account_number: account_number)
      end
    end
  end

  describe "unit tests" do
    include_examples "json based fixture", "germany_unit_test_cases" do
      let(:test_subject) do
        klass.new(bank_code, account_number).converted_details
      end
    end
  end

  describe Ibandit::GermanDetailsConverter::Rule002002::Check63 do
    subject { described_class.new(account_number) }

    # Test cases taken from the IBAN Rules definitions document
    valid_account_numbers = %w[
      38150900 600103660 39101181 5600200 75269100 3700246 6723143
      5719083 571908300 8007759 800775900 350002200 900004300
    ]

    invalid_account_numbers = %w[
      370024600 672314300 3500022 9000043 123456700 94012341 94012341
      5073321010 1234517892 987614325
    ]

    valid_account_numbers.each do |number|
      context number.to_s do
        let(:account_number) { number }
        it { is_expected.to be_valid }
      end
    end

    invalid_account_numbers.each do |number|
      context number.to_s do
        let(:account_number) { number }
        it { is_expected.to_not be_valid }
      end
    end
  end
end
