require "spec_helper"

describe Ibandit::LocalDetailsCleaner do
  subject(:cleaned) { described_class.clean(local_details) }
  let(:local_details) do
    {
      country_code:   country_code,
      bank_code:      bank_code,
      branch_code:    branch_code,
      account_number: account_number,
    }
  end

  let(:local_details_with_swift) do
    local_details.merge(
      swift_bank_code:      bank_code,
      swift_branch_code:    branch_code,
      swift_account_number: account_number,
    )
  end

  let(:country_code) { nil }
  let(:bank_code) { nil }
  let(:branch_code) { nil }
  let(:account_number) { nil }

  context "without country code" do
    it { is_expected.to eq(local_details_with_swift) }
  end

  context "with an unsupported country code" do
    let(:country_code) { "FU" }
    it { is_expected.to eq(local_details_with_swift) }
  end

  context "Austria" do
    let(:country_code) { "AT" }
    let(:bank_code) { "19043" }
    let(:account_number) { "00234573201" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with an account number which needs zero-padding" do
      let(:account_number) { "234573201" }
      its([:account_number]) { is_expected.to eq("00234573201") }
    end

    context "with an account number under 4 digits" do
      let(:account_number) { "123" }
      its([:account_number]) { is_expected.to eq("123") }
    end

    context "with a long account number" do
      let(:account_number) { "234573201999" }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "with a short bank code" do
      let(:bank_code) { "1904" }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "with a long bank code" do
      let(:bank_code) { "190430" }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Australia" do
    let(:country_code) { "AU" }
    let(:account_number) { "123456789" }

    context "with dashes" do
      let(:branch_code) { "123-456" }

      its([:country_code]) { is_expected.to eq(country_code) }
      its([:account_number]) { is_expected.to eq("0123456789") }
      its([:branch_code]) { is_expected.to eq("123456") }
    end

    context "without dashes" do
      let(:branch_code) { "123456" }

      its([:country_code]) { is_expected.to eq(country_code) }
      its([:account_number]) { is_expected.to eq("0123456789") }
      its([:branch_code]) { is_expected.to eq("123456") }
    end
  end

  context "Belgium" do
    let(:country_code) { "BE" }
    let(:account_number) { "510007547061" }

    its([:country_code]) { is_expected.to eq(country_code) }
    its([:account_number]) { is_expected.to eq(account_number) }
    its([:bank_code]) { is_expected.to eq("510") }

    context "with dashes" do
      let(:account_number) { "510-0075470-61" }
      its([:bank_code]) { is_expected.to eq("510") }
      its([:account_number]) { is_expected.to eq("510007547061") }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Bulgaria" do
    let(:country_code) { "BG" }
    let(:bank_code) { "BNBG" }
    let(:branch_code) { "9661" }
    let(:account_number) { "1020345678" }

    it { is_expected.to eq(local_details_with_swift) }

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Canada" do
    let(:country_code) { "CA" }
    let(:account_number) { "0123456" }
    let(:bank_code) { "0036" }
    let(:branch_code) { "00063" }

    its([:account_number]) { is_expected.to eq("000000123456") }
    its([:country_code]) { is_expected.to eq(country_code) }
    its([:bank_code]) { is_expected.to eq("0036") }
    its([:branch_code]) { is_expected.to eq("00063") }
  end

  context "Cyprus" do
    let(:country_code) { "CY" }
    let(:account_number) { "0000001200527600" }
    let(:bank_code) { "002" }
    let(:branch_code) { "00128" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with a short account number" do
      let(:account_number) { "1200527600" }
      its([:account_number]) { is_expected.to eq("0000001200527600") }
    end

    context "with a too-short account number" do
      let(:account_number) { "123456" }
      its([:account_number]) { is_expected.to eq(account_number) }
    end

    context "with a long account number" do
      let(:account_number) { "00000001200527600" }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "with the branch code in the bank code field" do
      let(:bank_code) { "002 00128" }
      let(:branch_code) { nil }
      its([:bank_code]) { is_expected.to eq("002") }
      its([:branch_code]) { is_expected.to eq("00128") }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Czech Republic" do
    let(:country_code) { "CZ" }
    let(:bank_code) { "0800" }
    let(:account_number) { "0000192000145399" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with an account number prefix" do
      let(:prefix) { "000019" }
      let(:account_number) { "2000145399" }
      before { local_details.merge!(account_number_prefix: prefix) }

      its([:account_number]) { is_expected.to eq("0000192000145399") }

      context "which needs zero-padding" do
        let(:prefix) { "19" }
        its([:account_number]) { is_expected.to eq("0000192000145399") }
      end
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Germany" do
    let(:country_code) { "DE" }
    let(:bank_code) { "37040044" }
    let(:account_number) { "0532013000" }

    it { is_expected.to eq(local_details_with_swift) }

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "with an excessively short account number" do
      let(:account_number) { "666" }
      its([:account_number]) { is_expected.to eq(account_number) }
    end

    context "with a pseudo account number" do
      let(:bank_code) { "37080040" }
      let(:account_number) { "111" }
      its([:bank_code]) { is_expected.to eq(bank_code) }
      its([:account_number]) { is_expected.to eq("0215022000") }
    end

    context "with unsupported account details" do
      let(:account_number) { "7955791111" }
      let(:bank_code) { "20000000" }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Denmark" do
    let(:country_code) { "DK" }
    let(:bank_code) { "40" }
    let(:account_number) { "440116243" }

    its([:bank_code]) { is_expected.to eq("0040") }
    its([:account_number]) { is_expected.to eq("0440116243") }

    context "with bank and branch codes in the account number" do
      let(:bank_code) { nil }
      let(:branch_code) { nil }
      let(:account_number) { "345-317-9681" }

      its([:bank_code]) { is_expected.to eq("0345") }
      its([:account_number]) { is_expected.to eq("0003179681") }
    end

    context "with a space-separated 14-digit account number" do
      let(:bank_code) { nil }
      let(:branch_code) { nil }
      let(:account_number) { "0345 0003179681" }

      its([:bank_code]) { is_expected.to eq("0345") }
      its([:account_number]) { is_expected.to eq("0003179681") }
    end

    context "with a space-separated 13-digit account number" do
      let(:bank_code) { nil }
      let(:branch_code) { nil }
      let(:account_number) { "0345 003179681" }

      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Estonia" do
    let(:country_code) { "EE" }
    let(:account_number) { "0221020145685" }

    its([:bank_code]) { is_expected.to eq("22") }
    its([:account_number]) { is_expected.to eq("00221020145685") }

    context "with an account number that needs translating" do
      let(:account_number) { "111020145685" }
      its([:bank_code]) { is_expected.to eq("22") }
      its([:account_number]) { is_expected.to eq("00111020145685") }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Spain" do
    let(:country_code) { "ES" }
    let(:bank_code) { "2310" }
    let(:branch_code) { "0001" }
    let(:account_number) { "180000012345" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with bank and branch codes in the account number" do
      let(:bank_code) { nil }
      let(:branch_code) { nil }
      let(:account_number) { "2310-0001-18-0000012345" }

      its([:bank_code]) { is_expected.to eq("2310") }
      its([:branch_code]) { is_expected.to eq("0001") }
      its([:account_number]) { is_expected.to eq("180000012345") }
    end

    context "with spaces in the account number" do
      let(:account_number) { "18 0000012345" }
      its([:account_number]) { is_expected.to eq("180000012345") }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Finland" do
    let(:country_code) { "FI" }
    let(:bank_code) { "123456" }
    let(:account_number) { "00000785" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with a shorter account number" do
      let(:account_number) { "785" }
      its([:account_number]) { is_expected.to eq("00000785") }
    end

    context "with a savings bank account_number in traditional format" do
      let(:account_number) { "78510" }
      let(:bank_code) { "423456" }

      its([:bank_code]) { is_expected.to eq(bank_code) }
      its([:account_number]) { is_expected.to eq("70008510") }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "France" do
    let(:country_code) { "FR" }
    let(:bank_code) { "20041" }
    let(:branch_code) { "01005" }
    let(:account_number) { "0500013M02606" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with the RIB key spaced in the account number" do
      let(:account_number) { "0500013M026 06" }
      its([:account_number]) { is_expected.to eq("0500013M02606") }
    end

    context "with the RIB key hyphenated in the account number" do
      let(:account_number) { "0500013M026-06" }
      its([:account_number]) { is_expected.to eq("0500013M02606") }
    end

    context "with the RIB key missing" do
      let(:account_number) { "0500013M026" }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "United Kingdom" do
    let(:country_code) { "GB" }
    let(:bank_code) { "BARC" }
    let(:branch_code) { "200000" }
    let(:account_number) { "55779911" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with the sort code is hyphenated" do
      let(:branch_code) { "20-00-00" }
      its([:branch_code]) { is_expected.to eq("200000") }
      its([:swift_branch_code]) { is_expected.to eq("200000") }
    end

    context "with the sort code spaced" do
      let(:branch_code) { "20 00 00" }
      its([:branch_code]) { is_expected.to eq("200000") }
    end

    context "with a short account number" do
      let(:account_number) { "579135" }
      its([:account_number]) { is_expected.to eq("00579135") }
      its([:swift_account_number]) { is_expected.to eq("00579135") }
    end

    context "with a too-short account number" do
      let(:account_number) { "5678" }
      its([:account_number]) { is_expected.to eq(account_number) }
    end

    context "with the account number spaced" do
      let(:account_number) { "5577 9911" }
      its([:account_number]) { is_expected.to eq("55779911") }
    end

    context "with the account number hyphenated" do
      let(:account_number) { "5577-9911" }
      its([:account_number]) { is_expected.to eq("55779911") }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }

      context "with a BIC finder set" do
        let(:bic_finder) { double }
        before do
          allow(bic_finder).to receive(:call).with("GB", "200000").
            and_return("BARCGB22XXX")
          Ibandit.bic_finder = bic_finder
        end
        after { Ibandit.bic_finder = nil }

        its([:bank_code]) { is_expected.to eq("BARC") }
        its([:swift_bank_code]) { is_expected.to eq("BARC") }
      end
    end

    context "with a bank code and BIC finder set" do
      let(:bank_code) { "OVERRIDE" }
      let(:bic_finder) { double }
      before do
        allow(bic_finder).to receive(:call).with("GB", "200000").
          and_return("BARCGB22XXX")
        Ibandit.bic_finder = bic_finder
      end
      after { Ibandit.bic_finder = nil }

      its([:bank_code]) { is_expected.to eq("OVERRIDE") }
    end
  end

  context "Greece" do
    let(:country_code) { "GR" }
    let(:bank_code) { "011" }
    let(:branch_code) { "0125" }
    let(:account_number) { "0000000012300695" }

    it { is_expected.to eq(local_details_with_swift) }

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Croatia" do
    let(:country_code) { "HR" }
    let(:bank_code) { "1001005" }
    let(:account_number) { "1863000160" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with bank code in the account number" do
      let(:bank_code) { nil }
      let(:branch_code) { nil }
      let(:account_number) { "1001005-1863000160" }

      its([:bank_code]) { is_expected.to eq("1001005") }
      its([:account_number]) { is_expected.to eq("1863000160") }

      context "with a badly formatted account number" do
        let(:account_number) { "1863000160" }
        it { is_expected.to eq(local_details_with_swift) }
      end
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Hungary" do
    let(:country_code) { "HU" }
    let(:bank_code) { "117" }
    let(:branch_code) { "7301" }
    let(:account_number) { "61111101800000000" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with bank and branch codes in the account number" do
      let(:bank_code) { nil }
      let(:branch_code) { nil }

      context "with a full account number" do
        let(:account_number) { "11773016-11111018-00000000" }

        its([:bank_code]) { is_expected.to eq("117") }
        its([:branch_code]) { is_expected.to eq("7301") }
        its([:account_number]) { is_expected.to eq("61111101800000000") }
      end

      context "with a short account number" do
        let(:account_number) { "11773016-11111018" }

        its([:bank_code]) { is_expected.to eq("117") }
        its([:branch_code]) { is_expected.to eq("7301") }
        its([:account_number]) { is_expected.to eq("61111101800000000") }
      end

      context "with an invalid length account number" do
        let(:account_number) { "11773016-1111101" }
        it { is_expected.to eq(local_details_with_swift) }
      end

      context "with a bank code, too" do
        let(:account_number) { "11773016-11111018" }
        let(:bank_code) { "117" }
        it { is_expected.to eq(local_details_with_swift) }
      end
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Ireland" do
    let(:country_code) { "IE" }
    let(:bank_code) { "AIBK" }
    let(:branch_code) { "931152" }
    let(:account_number) { "12345678" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with the sort code is hyphenated" do
      let(:branch_code) { "93-11-52" }
      its([:branch_code]) { is_expected.to eq("931152") }
    end

    context "with the sort code spaced" do
      let(:branch_code) { "93 11 52" }
      its([:branch_code]) { is_expected.to eq("931152") }
    end

    context "with a short account number" do
      let(:account_number) { "579135" }
      its([:account_number]) { is_expected.to eq("00579135") }
    end

    context "with a too-short account number" do
      let(:account_number) { "5678" }
      its([:account_number]) { is_expected.to eq(account_number) }
    end

    context "with the account number spaced" do
      let(:account_number) { "5577 9911" }
      its([:account_number]) { is_expected.to eq("55779911") }
    end

    context "with the account number hyphenated" do
      let(:account_number) { "5577-9911" }
      its([:account_number]) { is_expected.to eq("55779911") }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }

      context "with a BIC finder set" do
        let(:bic_finder) { double }
        before do
          allow(bic_finder).to receive(:call).with("IE", "931152").
            and_return("AIBKIE22XXX")
          Ibandit.bic_finder = bic_finder
        end
        after { Ibandit.bic_finder = nil }

        its([:bank_code]) { is_expected.to eq("AIBK") }
      end
    end

    context "with a bank code and BIC finder set" do
      let(:bank_code) { "OVERRIDE" }
      let(:bic_finder) { double }
      before do
        allow(bic_finder).to receive(:call).with("IE", "931152").
          and_return("AIBKIE22XXX")
        Ibandit.bic_finder = bic_finder
      end
      after { Ibandit.bic_finder = nil }

      its([:bank_code]) { is_expected.to eq("OVERRIDE") }
    end
  end

  context "Iceland" do
    let(:country_code) { "IS" }
    let(:bank_code) { "311" }
    let(:account_number) { "26-2468-460697-2049" }

    its([:bank_code]) { is_expected.to eq("0311") }
    its([:account_number]) { is_expected.to eq("260024684606972049") }

    context "with bank code in the account number" do
      let(:bank_code) { nil }
      let(:account_number) { "311-26-2468-460697-2049" }

      its([:bank_code]) { is_expected.to eq("0311") }
      its([:account_number]) { is_expected.to eq("260024684606972049") }

      context "and no hyphens" do
        let(:account_number) { "0311260024684606972049" }

        its([:bank_code]) { is_expected.to eq("0311") }
        its([:account_number]) { is_expected.to eq("260024684606972049") }
      end
    end

    context "with no hyphen in the kennitala" do
      let(:account_number) { "26-2468-4606972049" }

      its([:account_number]) { is_expected.to eq("260024684606972049") }
    end

    context "with a short kennitala" do
      let(:account_number) { "26-2468-60697-2049" }

      its([:account_number]) { is_expected.to eq("260024680606972049") }

      context "without a hyphen" do
        let(:account_number) { "26-2468-606972049" }
        its([:account_number]) { is_expected.to eq("260024680606972049") }
      end
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Italy" do
    let(:country_code) { "IT" }
    let(:bank_code) { "05428" }
    let(:branch_code) { "11101" }
    let(:account_number) { "000000123456" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with an explicit check digit" do
      before { local_details.merge!(check_digit: "Y") }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "with the account number not zero-padded" do
      let(:account_number) { "123456" }
      its([:account_number]) { is_expected.to eq("000000123456") }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Lithuania" do
    let(:country_code) { "LT" }
    let(:bank_code) { "10000" }
    let(:account_number) { "11101001000" }

    it { is_expected.to eq(local_details_with_swift) }

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Luxembourg" do
    let(:country_code) { "LU" }
    let(:bank_code) { "001" }
    let(:account_number) { "9400644750000" }

    it { is_expected.to eq(local_details_with_swift) }

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Latvia" do
    let(:country_code) { "LV" }
    let(:bank_code) { "BANK" }
    let(:account_number) { "1234567890123" }

    it { is_expected.to eq(local_details_with_swift) }

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Monaco" do
    let(:country_code) { "MC" }
    let(:bank_code) { "20041" }
    let(:branch_code) { "01005" }
    let(:account_number) { "0500013M02606" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with the RIB key spaced in the account number" do
      let(:account_number) { "0500013M026 06" }
      its([:account_number]) { is_expected.to eq("0500013M02606") }
    end

    context "with the RIB key hyphenated in the account number" do
      let(:account_number) { "0500013M026-06" }
      its([:account_number]) { is_expected.to eq("0500013M02606") }
    end

    context "with the RIB key missing" do
      let(:account_number) { "0500013M026" }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Malta" do
    let(:country_code) { "MT" }
    let(:bank_code) { "MMEB" }
    let(:branch_code) { "44093" }
    let(:account_number) { "000000009027293051" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with the account number spaced" do
      let(:account_number) { "9027 2930 51" }
      its([:account_number]) { is_expected.to eq("000000009027293051") }
    end

    context "with the account number hyphenated" do
      let(:account_number) { "9027-2930-51" }
      its([:account_number]) { is_expected.to eq("000000009027293051") }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }

      context "with a BIC finder set" do
        let(:bic_finder) { double }
        before do
          allow(bic_finder).to receive(:call).with("MT", "44093").
            and_return("MMEBMTMTXXX")
          Ibandit.bic_finder = bic_finder
        end
        after { Ibandit.bic_finder = nil }

        its([:bank_code]) { is_expected.to eq("MMEB") }
      end
    end

    context "with a bank code and BIC finder set" do
      let(:bank_code) { "OVERRIDE" }
      let(:bic_finder) { double }
      before do
        allow(bic_finder).to receive(:call).with("MT", "44093").
          and_return("MMEBMTMTXXX")
        Ibandit.bic_finder = bic_finder
      end
      after { Ibandit.bic_finder = nil }

      its([:bank_code]) { is_expected.to eq("OVERRIDE") }
    end
  end

  context "Netherlands" do
    let(:country_code) { "NL" }
    let(:bank_code) { "ABNA" }
    let(:account_number) { "0417164300" }

    it { is_expected.to eq(local_details_with_swift) }

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "with an account number that needs zero-padding" do
      let(:account_number) { "417164300" }
      its([:account_number]) { is_expected.to eq("0417164300") }
    end
  end

  context "Norway" do
    let(:country_code) { "NO" }
    let(:bank_code) { "8601" }
    let(:account_number) { "1117947" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with bank and branch codes in the account number" do
      let(:bank_code) { nil }
      let(:branch_code) { nil }
      let(:account_number) { "8601.1117947" }

      its([:bank_code]) { is_expected.to eq("8601") }
      its([:account_number]) { is_expected.to eq("1117947") }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "New Zealand" do
    let(:country_code) { "NZ" }
    let(:bank_code) { "11" }
    let(:branch_code) { "2222" }
    let(:account_number) { "3333333044" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with bank and branch codes in the account number" do
      let(:bank_code) { nil }
      let(:branch_code) { nil }
      let(:account_number) { "11-2222-3333333-044" }

      its([:bank_code]) { is_expected.to eq("11") }
      its([:branch_code]) { is_expected.to eq("2222") }
      its([:account_number]) { is_expected.to eq("3333333044") }

      context "with a 2-digit account number suffix" do
        let(:account_number) { "11-2222-3333333-44" }

        its([:bank_code]) { is_expected.to eq("11") }
        its([:branch_code]) { is_expected.to eq("2222") }
        its([:account_number]) { is_expected.to eq("3333333044") }
      end

      context "when the account number is shorter than 6 chars" do
        let(:account_number) { "12345" }
        its([:account_number]) { is_expected.to be_nil }
      end
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Poland" do
    let(:country_code) { "PL" }
    let(:bank_code) { "10201026" }
    let(:account_number) { "0000042270201111" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with a full length account number" do
      let(:bank_code) { nil }
      let(:branch_code) { nil }
      let(:account_number) { "60102010260000042270201111" }

      its([:bank_code]) { is_expected.to eq("10201026") }
      its([:account_number]) { is_expected.to eq("0000042270201111") }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Portugal" do
    let(:country_code) { "PT" }
    let(:bank_code) { "0002" }
    let(:branch_code) { "0023" }
    let(:account_number) { "0023843000578" }

    it { is_expected.to eq(local_details_with_swift) }

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Romania" do
    let(:country_code) { "RO" }
    let(:bank_code) { "AAAA" }
    let(:account_number) { "1B31007593840000" }

    it { is_expected.to eq(local_details_with_swift) }

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Sweden" do
    let(:country_code) { "SE" }
    let(:bank_code) { nil }
    let(:account_number) { "5013-1007270" }

    its([:account_number]) { is_expected.to eq("1007270") }
    its([:branch_code]) { is_expected.to eq("5013") }
    its([:swift_bank_code]) { is_expected.to eq("500") }
    its([:swift_account_number]) { is_expected.to eq("00000050131007270") }

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "with a bank code" do
      let(:bank_code) { "501" }

      # Doesn't do any conversion
      its([:swift_bank_code]) { is_expected.to eq("501") }
      its([:bank_code]) { is_expected.to eq("501") }
      its([:account_number]) { is_expected.to eq("5013-1007270") }
      its([:swift_account_number]) { is_expected.to eq("5013-1007270") }
    end
  end

  context "Slovenia" do
    let(:country_code) { "SI" }
    let(:bank_code) { "19100" }
    let(:account_number) { "0000123438" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with an account number which needs zero-padding" do
      let(:account_number) { "123438" }
      its([:account_number]) { is_expected.to eq("0000123438") }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "Slovak Republic" do
    let(:country_code) { "SK" }
    let(:bank_code) { "1200" }
    let(:account_number) { "0000198742637541" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with an account number prefix" do
      let(:prefix) { "000019" }
      let(:account_number) { "8742637541" }
      before { local_details.merge!(account_number_prefix: prefix) }

      its([:account_number]) { is_expected.to eq("0000198742637541") }

      context "which needs zero-padding" do
        let(:prefix) { "19" }
        its([:account_number]) { is_expected.to eq("0000198742637541") }
      end
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end

  context "San Marino" do
    let(:country_code) { "SM" }
    let(:bank_code) { "05428" }
    let(:branch_code) { "11101" }
    let(:account_number) { "000000123456" }

    it { is_expected.to eq(local_details_with_swift) }

    context "with an explicit check digit" do
      before { local_details.merge!(check_digit: "Y") }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "with the account number not zero-padded" do
      let(:account_number) { "123456" }
      its([:account_number]) { is_expected.to eq("000000123456") }
    end

    context "without a bank code" do
      let(:bank_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without a branch code" do
      let(:branch_code) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end

    context "without an account number" do
      let(:account_number) { nil }
      it { is_expected.to eq(local_details_with_swift) }
    end
  end
end
