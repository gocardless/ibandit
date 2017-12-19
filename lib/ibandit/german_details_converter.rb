# German bank details don't map directly to IBANs in the same way as in other
# countries - each bank has idiosyncracies for translating its cusomers' bank
# details. These idiosyncracies are described in a document from the Bundesbank:
# https://www.bundesbank.de/Redaktion/EN/Standardartikel/Tasks/Payment_systems/iban_rules.html?nn=26102

module Ibandit
  module GermanDetailsConverter
    def self.rules
      @rules ||= YAML.load_file(
        File.expand_path("../../../data/german_iban_rules.yml", __FILE__),
      )
    end

    def self.convert(opts)
      # Fetch the relevant rule number. Default to '000000'
      rule_num = rules.fetch(opts[:bank_code], {}).fetch(:iban_rule, "000000")

      # Convert the bank details using the relevant rule
      updated_bank_details = const_get("Rule#{rule_num}").new(
        opts[:bank_code],
        opts[:account_number],
      ).converted_details

      opts.merge(updated_bank_details)
    end

    ##############
    # IBAN Rules #
    ##############

    class BaseRule
      def initialize(bank_code, account_number)
        @bank_code = bank_code
        @account_number = account_number
      end

      def converted_details
        raise NotImplementedError, "Concrete RuleXXXXXX classes should " \
                                   "define a converted_details function"
      end
    end

    module PseudoAccountNumberBehaviour
      def self.included(o)
        o.extend(ClassMethods)
      end

      module ClassMethods
        attr_reader :pseudo_account_number_mapping
      end

      def converted_details
        updated_account_number =
          pseudo_account_number_mapping.fetch(
            @account_number.rjust(10, "0"),
            @account_number,
          )

        { bank_code: @bank_code, account_number: updated_account_number }
      end

      def pseudo_account_number_mapping
        self.class.pseudo_account_number_mapping.freeze
      end
    end

    class Rule000000 < BaseRule
      def converted_details
        { bank_code: @bank_code, account_number: @account_number }
      end
    end

    class Rule000100 < BaseRule
      def converted_details
        msg = "Bank code #{@bank_code} is not used for payment transactions"
        raise UnsupportedAccountDetails, msg
      end
    end

    class Rule000200 < BaseRule
      def converted_details
        if @account_number.rjust(10, "0")[7] == "6" ||
            @account_number.rjust(10, "0").slice(7, 2) == "86"
          msg = "Account does not support payment transactions"
          raise UnsupportedAccountDetails, msg
        else
          { bank_code: @bank_code, account_number: @account_number }
        end
      end
    end

    class Rule000300 < BaseRule
      def converted_details
        if @account_number == "6161604670"
          msg = "Account does not support payment transactions"
          raise UnsupportedAccountDetails, msg
        else
          { bank_code: @bank_code, account_number: @account_number }
        end
      end
    end

    class Rule000400 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = {
        "0000000135" => "0990021440",
        "0000001111" => "6600012020",
        "0000001900" => "0920019005",
        "0000007878" => "0780008006",
        "0000008888" => "0250030942",
        "0000009595" => "1653524703",
        "0000097097" => "0013044150",
        "0000112233" => "0630025819",
        "0000336666" => "6604058903",
        "0000484848" => "0920018963",
      }
    end

    class Rule000503 < BaseRule
      EXCEPTION_BANK_CODES = %w[
        10080900 25780022 42080082 54280023 65180005 79580099 12080000 25980027
        42680081 54580020 65380003 80080000 13080000 26080024 43080083 54680022
        66280053 81080000 14080000 26281420 44080055 55080065 66680013 82080000
        15080000 26580070 44080057 57080070 67280051 83080000 16080000 26880063
        44580070 58580074 69280035 84080000 17080000 26981062 45080060 59080090
        70080056 85080200 18080000 28280012 46080010 60080055 70080057 86080055
        20080055 29280011 47880031 60080057 70380006 86080057 20080057 30080055
        49080025 60380002 71180005 87080000 21080050 30080057 50080055 60480008
        72180002 21280002 31080015 50080057 61080006 73180011 21480003 32080010
        50080082 61281007 73380004 21580000 33080030 50680002 61480001 73480013
        22180000 34080031 50780006 62080012 74180009 22181400 34280032 50880050
        62280012 74380007 22280000 36280071 51380040 63080015 75080003 24080000
        36580072 52080080 64080014 76080053 24180001 40080040 53080030 64380011
        79080052 25480021 41280043 54080021 65080009 79380051￼￼￼￼
      ].freeze

      PSEUDO_ACCOUNT_NUMBER_MAPPING = {
        "30040000_0000000036" => "0261103600",
        "47880031_0000000050" => "0519899900",
        "47840065_0000000050" => "0150103000",
        "47840065_0000000055" => "0150103000",
        "70080000_0000000094" => "0928553201",
        "70040041_0000000094" => "0212808000",
        "47840065_0000000099" => "0150103000",
        "37080040_0000000100" => "0269100000",
        "38040007_0000000100" => "0119160000",
        "37080040_0000000111" => "0215022000",
        "51080060_0000000123" => "0012299300",
        "36040039_0000000150" => "0161620000",
        "68080030_0000000202" => "0416520200",
        "30040000_0000000222" => "0348010002",
        "38040007_0000000240" => "0109024000",
        "69240075_0000000444" => "0445520000",
        "60080000_0000000502" => "0901581400",
        "60040071_0000000502" => "0525950200",
        "55040022_0000000555" => "0211050000",
        "39080005_0000000556" => "0204655600",
        "39040013_0000000556" => "0106555600",
        "57080070_0000000661" => "0604101200",
        "26580070_0000000700" => "0710000000",
        "50640015_0000000777" => "0222222200",
        "30040000_0000000999" => "0123799900",
        "86080000_0000001212" => "0480375900",
        "37040044_0000001888" => "0212129101",
        "25040066_0000001919" => "0141919100",
        "10080000_0000001987" => "0928127700",
        "50040000_0000002000" => "0728400300",
        "20080000_0000002222" => "0903927200",
        "38040007_0000003366" => "0385333000",
        "37080040_0000004004" => "0233533500",
        "37080040_0000004444" => "0233000300",
        "43080083_0000004630" => "0825110100",
        "50080000_0000006060" => "0096736100",
        "10040000_0000007878" => "0267878700",
        "10080000_0000008888" => "0928126501",
        "50080000_0000009000" => "0026492100",
        "79080052_0000009696" => "0300021700",
        "79040047_0000009696" => "0680210200",
        "39080005_0000009800" => "0208457000",
        "50080000_0000042195" => "0900333200",
        "32040024_0000047800" => "0155515000",
        "37080040_0000055555" => "0263602501",
        "38040007_0000055555" => "0305555500",
        "50080000_0000101010" => "0090003500",
        "50040000_0000101010" => "0311011100",
        "37040044_0000102030" => "0222344400",
        "86080000_0000121200" => "0480375900",
        "66280053_0000121212" => "0625242400",
        "16080000_0000123456" => "0012345600",
        "29080010_0000124124" => "0107502000",
        "37080040_0000182002" => "0216603302",
        "12080000_0000212121" => "4050462200",
        "37080040_0000300000" => "0983307900",
        "37040044_0000300000" => "0300000700",
        "37080040_0000333333" => "0270330000",
        "38040007_0000336666" => "0105232300",
        "55040022_0000343434" => "0217900000",
        "85080000_0000400000" => "0459488501",
        "37080040_0000414141" => "0041414100",
        "38040007_0000414141" => "0108000100",
        "20080000_0000505050" => "0500100600",
        "37080040_0000555666" => "0055566600",
        "20080000_0000666666" => "0900732500",
        "30080000_0000700000" => "0800005000",
        "70080000_0000700000" => "0750055500",
        "70080000_0000900000" => "0319966601",
        "37080040_0000909090" => "0269100000",
        "38040007_0000909090" => "0119160000",
        "70080000_0000949494" => "0575757500",
        "70080000_0001111111" => "0448060000",
        "70040041_0001111111" => "0152140000",
        "10080000_0001234567" => "0920192001",
        "38040007_0001555555" => "0258266600",
        "76040061_0002500000" => "0482146800",
        "16080000_0003030400" => "4205227110",
        "37080040_0005555500" => "0263602501",
        "75040062_0006008833" => "0600883300",
        "12080000_0007654321" => "0144000700",
        "70080000_0007777777" => "0443540000",
        "70040041_0007777777" => "0213600000",
        "64140036_0008907339" => "0890733900",
        "70080000_0009000000" => "0319966601",
        "61080006_0009999999" => "0202427500",
        "12080000_0012121212" => "4101725100",
        "29080010_0012412400" => "0107502000",
        "34280032_0014111935" => "0645753800",
        "38040007_0043434343" => "0118163500",
        "30080000_0070000000" => "0800005000",
        "70080000_0070000000" => "0750055500",
        "44040037_0111111111" => "0320565500",
        "70040041_0400500500" => "0400500500",
        "60080000_0500500500" => "0901581400",
        "60040071_0500500500" => "0512700600",
      }.freeze

      def converted_details
        updated_account_number =
          if PSEUDO_ACCOUNT_NUMBER_MAPPING.key?(combined_bank_details)
            converted_pseudo_account_number
          else
            padded_account_number_for_validity
          end

        if EXCEPTION_BANK_CODES.include?(@bank_code) &&
            updated_account_number.to_i.between?(998000000, 999499999)
          msg = "Account does not support payment transactions"
          raise UnsupportedAccountDetails, msg
        end

        { bank_code: @bank_code, account_number: updated_account_number }
      end

      private

      def combined_bank_details
        "#{@bank_code}_#{@account_number.rjust(10, '0')}"
      end

      def converted_pseudo_account_number
        PSEUDO_ACCOUNT_NUMBER_MAPPING[combined_bank_details]
      end

      def padded_account_number_for_validity
        unpadded_account_number = @account_number.gsub(/\A0+/, "")

        case GermanDetailsConverter.rules[@bank_code][:check_digit_rule]
        when "13"
          if unpadded_account_number.size.between?(6, 7)
            unpadded_account_number + "00"
          else @account_number
          end
        when "76"
          case unpadded_account_number.size
          when 7..8
            if Check76.new(@account_number).valid? then @account_number
            else unpadded_account_number + "00"
            end
          when 5..6 then unpadded_account_number + "00"
          else @account_number
          end
        else @account_number
        end
      end

      class Check76
        def initialize(account_number)
          @account_number = account_number.rjust(10, "0")
        end

        def valid?
          return false unless valid_length? && valid_account_type?
          [master_number[-1].to_i, 10].include?(remainder)
        end

        private

        def master_number
          @account_number.slice(1, 7).gsub(/\A0+/, "")
        end

        def remainder
          sum_of_weighted_values % 11
        end

        def sum_of_weighted_values
          weighted_values.reduce(0, &:+)
        end

        def weighted_values
          weights = [2, 3, 4, 5, 6, 7, 8]

          master_number[0..-2].reverse.chars.map.with_index do |digit, i|
            digit.to_i * weights[i]
          end
        end

        def valid_account_type?
          [0, 4, 6, 7, 8, 9].include? @account_number[0].to_i
        end

        def valid_length?
          [5, 6, 7].include? master_number.size
        end
      end
    end

    class Rule000600 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = {
        "0001111111" => "0020228888",
        "0007777777" => "0903286003",
        "0034343434" => "1000506517",
        "0000070000" => "0018180018",
      }
    end

    class Rule000700 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = {
        "0000000111" => "0000001115",
        "0000000221" => "0023002157",
        "0000001888" => "0018882068",
        "0000002006" => "1900668508",
        "0000002626" => "1900730100",
        "0000003004" => "1900637016",
        "0000003636" => "0023002447",
        "0000004000" => "0000004028",
        "0000004444" => "0000017368",
        "0000005050" => "0000073999",
        "0000008888" => "1901335750",
        "0000030000" => "0009992959",
        "0000043430" => "1901693331",
        "0000046664" => "1900399856",
        "0000055555" => "0034407379",
        "0000102030" => "1900480466",
        "0000151515" => "0057762957",
        "0000222222" => "0002222222",
        "0000300000" => "0009992959",
        "0000333333" => "0000033217",
        "0000414141" => "0000092817",
        "0000606060" => "0000091025",
        "0000909090" => "0000090944",
        "0002602024" => "0005602024",
        "0003000000" => "0009992959",
        "0007777777" => "0002222222",
        "0008090100" => "0000038901",
        "0014141414" => "0043597665",
        "0015000023" => "0015002223",
        "0015151515" => "0057762957",
        "0022222222" => "0002222222",
        "0200820082" => "1901783868",
        "0222220022" => "0002222222",
      }
    end

    class Rule000800 < BaseRule
      def converted_details
        { bank_code: "50020200", account_number: @account_number }
      end
    end

    class Rule000900 < BaseRule
      def converted_details
        updated_account_number =
          if @account_number.rjust(10, "0").slice(0, 4) == "1116"
            "3047#{@account_number.rjust(10, '0').slice(4, 6)}"
          else
            @account_number
          end

        { bank_code: "68351557", account_number: updated_account_number }
      end
    end

    class Rule001001 < BaseRule
      PSEUDO_ACCOUNT_NUMBER_MAPPING = {
        "50050201_0000002000" => "0000222000",
        "50050201_0000800000" => "0000180802",
      }.freeze

      BANK_CODE_MAPPING = {
        "50050222" => "50050201",
      }.freeze

      def converted_details
        updated_account_number = PSEUDO_ACCOUNT_NUMBER_MAPPING.fetch(
          "#{@bank_code}_#{@account_number.rjust(10, '0')}",
          @account_number,
        )
        updated_bank_code = BANK_CODE_MAPPING.fetch(@bank_code, @bank_code)

        { bank_code: updated_bank_code, account_number: updated_account_number }
      end
    end

    class Rule001100 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = {
        "0000001000" => "0008010001",
        "0000047800" => "0000047803",
      }
    end

    class Rule001201 < BaseRule
      def converted_details
        { bank_code: "50050000", account_number: @account_number }
      end
    end

    class Rule001301 < BaseRule
      def converted_details
        { bank_code: "30050000", account_number: @account_number }
      end
    end

    class Rule001400 < BaseRule
      def converted_details
        { bank_code: "30060601", account_number: @account_number }
      end
    end

    class Rule001501 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = {
        "0000000094" => "3008888018",
        "0000000556" => "0000101010",
        "0000000888" => "0031870011",
        "0000004040" => "4003600101",
        "0000005826" => "1015826017",
        "0000025000" => "0025000110",
        "0000393393" => "0033013019",
        "0000444555" => "0032230016",
        "0000603060" => "6002919018",
        "0002120041" => "0002130041",
        "0080868086" => "4007375013",
        "0400569017" => "4000569017",
      }
    end

    class Rule001600 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = { "0000300000" => "0018128012" }
    end

    class Rule001700 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = {
        "0000000100" => "2009090013",
        "0000000111" => "2111111017",
        "0000000240" => "2100240010",
        "0000004004" => "2204004016",
        "0000004444" => "2044444014",
        "0000006060" => "2016060014",
        "0000102030" => "1102030016",
        "0000333333" => "2033333016",
        "0000909090" => "2009090013",
        "0050005000" => "5000500013",
      }
    end

    class Rule001800 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = {
        "0000000556" => "0120440110",
        "5435435430" => "0543543543",
        "0000002157" => "0121787016",
        "0000009800" => "0120800019",
        "0000202050" => "1221864014",
      }
    end

    class Rule001900 < BaseRule
      def converted_details
        { bank_code: "50120383", account_number: @account_number }
      end
    end

    class Rule002002 < BaseRule
      def converted_details
        unpadded_account_number = @account_number.gsub(/\A0+/, "")

        if unpadded_account_number == "9999" && @bank_code == "50070010"
          return { bank_code: "50070010", account_number: "92777202" }
        end

        updated_account_number =
          case unpadded_account_number.size
          when 5, 6 then unpadded_account_number + "00"
          when 7 then
            if Check63.new(unpadded_account_number + "00").valid?
              unpadded_account_number + "00"
            else
              unpadded_account_number
            end
          when 8, 9 then unpadded_account_number
          else
            msg = "Account does not support payment transactions"
            raise UnsupportedAccountDetails, msg
          end

        { bank_code: @bank_code, account_number: updated_account_number }
      end

      class Check63
        # A Deutsche Bank specific variant of Check 63
        def initialize(account_number)
          @account_number = account_number.dup.rjust(10, "0")
        end

        def valid?
          expected_check_digit = (10 - remainder) % 10
          expected_check_digit == @account_number[-3].to_i
        end

        private

        def remainder
          sum_of_weighted_digits % 10
        end

        def sum_of_weighted_digits
          weighted_digits.reduce(0, &:+)
        end

        def weighted_digits
          weighted_values.flat_map { |value| value.to_s.chars.map(&:to_i) }
        end

        def weighted_values
          weights = [2, 1, 2, 1, 2, 1]

          @account_number.slice(1, 6).reverse.chars.map.with_index do |digit, i|
            digit.to_i * weights[i]
          end
        end
      end
    end

    class Rule002101 < BaseRule
      def converted_details
        { bank_code: "36020030", account_number: @account_number }
      end
    end

    class Rule002200 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = { "0001111111" => "2222200000" }
    end

    class Rule002300 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = { "0000000700" => "1000700800" }
    end

    class Rule002400 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = {
        "0000000094" => "0000001694",
        "0000000248" => "0000017248",
        "0000000345" => "0000017345",
        "0000000400" => "0000014400",
      }
    end

    class Rule002500 < BaseRule
      def converted_details
        { bank_code: "60050101", account_number: @account_number }
      end
    end

    class Rule002600 < Rule000000
      # Rule 0026 is actually about modulus checking, not IBAN construction
    end

    class Rule002700 < Rule000000
      # Rule 0027 is actually about modulus checking, not IBAN construction
    end

    class Rule002800 < BaseRule
      def converted_details
        { bank_code: "25050180", account_number: @account_number }
      end
    end

    class Rule002900 < BaseRule
      def converted_details
        updated_account_number =
          if @account_number.size == 10 && @account_number[3] == "0"
            "0#{@account_number.slice(0, 3)}#{@account_number.slice(4, 6)}"
          else
            @account_number
          end

        { bank_code: @bank_code, account_number: updated_account_number }
      end
    end

    class Rule003000 < Rule000000
      # Rule 0030 is actually about modulus checking, not IBAN construction
    end

    class Rule003101 < BaseRule
      # This rule appears to be obsolete - no entries in the BLZ use it. The
      # table below, which maps old Hypo bank codes to new ones, is used by
      # other checks though.
      #
      BANK_CODE_MAPPING = {
        "100" => "76020070", "101" => "10020890", "102" => "78320076",
        "103" => "79320075", "104" => "76320072", "105" => "79020076",
        "106" => "79320075", "107" => "79320075", "108" => "77320072",
        "109" => "79320075", "110" => "76220073", "111" => "76020070",
        "112" => "79320075", "113" => "76020070", "114" => "76020070",
        "115" => "76520071", "117" => "77120073", "118" => "76020070",
        "119" => "75320075", "120" => "72120078", "121" => "76220073",
        "122" => "76320072", "123" => "76420080", "124" => "76320072",
        "125" => "79520070", "126" => "77320072", "127" => "78020070",
        "128" => "78020070", "129" => "77120073", "130" => "78020070",
        "131" => "78020070", "132" => "60020290", "134" => "78020070",
        "135" => "77020070", "136" => "79520070", "137" => "79320075",
        "138" => "61120286", "139" => "66020286", "140" => "79020076",
        "142" => "64020186", "143" => "60020290", "144" => "79020076",
        "145" => "66020286", "146" => "72120078", "147" => "72223182",
        "148" => "76520071", "149" => "79020076", "150" => "76020070",
        "151" => "76320072", "152" => "78320076", "154" => "70020270",
        "155" => "76520071", "156" => "76020070", "157" => "10020890",
        "158" => "70020270", "159" => "54520194", "160" => "70020270",
        "161" => "54520194", "162" => "70020270", "163" => "70020270",
        "164" => "70020270", "166" => "71120078", "167" => "74320073",
        "168" => "70320090", "169" => "79020076", "170" => "70020270",
        "172" => "70020270", "174" => "70020270", "175" => "72120078",
        "176" => "74020074", "177" => "74320073", "178" => "70020270",
        "181" => "77320072", "182" => "79520070", "183" => "70020270",
        "185" => "70020270", "186" => "79020076", "188" => "70020270",
        "189" => "70020270", "190" => "76020070", "191" => "77020070",
        "192" => "70025175", "193" => "85020086", "194" => "76020070",
        "196" => "72020070", "198" => "76320072", "199" => "70020270",
        "201" => "76020070", "202" => "76020070", "203" => "76020070",
        "204" => "76020070", "205" => "79520070", "206" => "79520070",
        "207" => "71120078", "208" => "73120075", "209" => "18020086",
        "210" => "10020890", "211" => "60020290", "212" => "51020186",
        "214" => "75020073", "215" => "63020086", "216" => "75020073",
        "217" => "79020076", "218" => "59020090", "219" => "79520070",
        "220" => "73322380", "221" => "73120075", "222" => "73421478",
        "223" => "74320073", "224" => "73322380", "225" => "74020074",
        "227" => "75020073", "228" => "71120078", "229" => "80020086",
        "230" => "72120078", "231" => "72020070", "232" => "75021174",
        "233" => "71020072", "234" => "71022182", "235" => "74320073",
        "236" => "71022182", "237" => "76020070", "238" => "63020086",
        "239" => "70020270", "240" => "75320075", "241" => "76220073",
        "243" => "72020070", "245" => "72120078", "246" => "74320073",
        "247" => "60020290", "248" => "85020086", "249" => "73321177",
        "250" => "73420071", "251" => "70020270", "252" => "70020270",
        "253" => "70020270", "254" => "10020890", "255" => "50820292",
        "256" => "71022182", "257" => "83020086", "258" => "79320075",
        "259" => "71120077", "260" => "10020890", "261" => "70025175",
        "262" => "72020070", "264" => "74020074", "267" => "63020086",
        "268" => "70320090", "269" => "71122183", "270" => "82020086",
        "271" => "75020073", "272" => "73420071", "274" => "63020086",
        "276" => "70020270", "277" => "74320073", "278" => "71120077",
        "279" => "10020890", "281" => "71120078", "282" => "70020270",
        "283" => "72020070", "284" => "79320075", "286" => "54520194",
        "287" => "70020270", "288" => "75220070", "291" => "77320072",
        "292" => "76020070", "293" => "72020070", "294" => "54520194",
        "295" => "70020270", "296" => "70020270", "299" => "72020070",
        "301" => "85020086", "302" => "54520194", "304" => "70020270",
        "308" => "70020270", "309" => "54520194", "310" => "72020070",
        "312" => "74120071", "313" => "76320072", "314" => "70020270",
        "315" => "70020270", "316" => "70020270", "317" => "70020270",
        "318" => "70020270", "320" => "71022182", "321" => "75220070",
        "322" => "79520070", "324" => "70020270", "326" => "85020086",
        "327" => "72020070", "328" => "72020070", "329" => "70020270",
        "330" => "76020070", "331" => "70020270", "333" => "70020270",
        "334" => "75020073", "335" => "70020270", "337" => "80020086",
        "341" => "10020890", "342" => "10020890", "344" => "70020270",
        "345" => "77020070", "346" => "76020070", "350" => "79320075",
        "351" => "79320075", "352" => "70020270", "353" => "70020270",
        "354" => "72223182", "355" => "72020070", "356" => "70020270",
        "358" => "54220091", "359" => "76220073", "360" => "80020087",
        "361" => "70020270", "362" => "70020270", "363" => "70020270",
        "366" => "72220074", "367" => "70020270", "368" => "10020890",
        "369" => "76520071", "370" => "85020086", "371" => "70020270",
        "373" => "70020270", "374" => "73120075", "375" => "70020270",
        "379" => "70020270", "380" => "70020270", "381" => "70020270",
        "382" => "79520070", "383" => "72020070", "384" => "72020070",
        "386" => "70020270", "387" => "70020270", "389" => "70020270",
        "390" => "67020190", "391" => "70020270", "392" => "70020270",
        "393" => "54520194", "394" => "70020270", "396" => "70020270",
        "398" => "66020286", "399" => "87020088", "401" => "30220190",
        "402" => "36020186", "403" => "38020090", "404" => "30220190",
        "405" => "68020186", "406" => "48020086", "407" => "37020090",
        "408" => "68020186", "409" => "10020890", "410" => "66020286",
        "411" => "60420186", "412" => "57020086", "422" => "70020270",
        "423" => "70020270", "424" => "76020070", "426" => "70025175",
        "427" => "50320191", "428" => "70020270", "429" => "85020086",
        "432" => "70020270", "434" => "60020290", "435" => "76020070",
        "436" => "76020070", "437" => "70020270", "438" => "70020270",
        "439" => "70020270", "440" => "70020270", "441" => "70020270",
        "442" => "85020086", "443" => "55020486", "444" => "50520190",
        "446" => "80020086", "447" => "70020270", "450" => "30220190",
        "451" => "44020090", "452" => "70020270", "453" => "70020270",
        "456" => "10020890", "457" => "87020086", "458" => "54520194",
        "459" => "61120286", "460" => "70020270", "461" => "70020270",
        "462" => "70020270", "463" => "70020270", "465" => "70020270",
        "466" => "10020890", "467" => "10020890", "468" => "70020270",
        "469" => "60320291", "470" => "65020186", "471" => "84020087",
        "472" => "76020070", "473" => "74020074", "476" => "78320076",
        "477" => "78320076", "478" => "87020088", "480" => "70020270",
        "481" => "70020270", "482" => "84020087", "484" => "70020270",
        "485" => "50320191", "486" => "70020270", "488" => "67220286",
        "489" => "10020890", "490" => "10020890", "491" => "16020086",
        "492" => "10020890", "494" => "79020076", "495" => "87020088",
        "497" => "87020087", "499" => "79020076", "502" => "10020890",
        "503" => "10020890", "505" => "70020270", "506" => "10020890",
        "507" => "87020086", "508" => "86020086", "509" => "83020087",
        "510" => "80020086", "511" => "83020086", "513" => "85020086",
        "515" => "17020086", "518" => "82020086", "519" => "83020086",
        "522" => "10020890", "523" => "70020270", "524" => "85020086",
        "525" => "70020270", "527" => "82020088", "528" => "10020890",
        "530" => "10020890", "531" => "10020890", "533" => "50320191",
        "534" => "70020270", "536" => "85020086", "538" => "82020086",
        "540" => "65020186", "541" => "80020087", "545" => "18020086",
        "546" => "10020890", "547" => "10020890", "548" => "10020890",
        "549" => "82020087", "555" => "79020076", "560" => "79320075",
        "567" => "86020086", "572" => "10020890", "580" => "70020270",
        "581" => "70020270", "601" => "74320073", "602" => "70020270",
        "603" => "70020270", "604" => "70020270", "605" => "70020270",
        "606" => "70020270", "607" => "74320073", "608" => "72020070",
        "609" => "72020070", "610" => "72020070", "611" => "72020070",
        "612" => "71120077", "613" => "70020270", "614" => "72020070",
        "615" => "70025175", "616" => "73420071", "617" => "68020186",
        "618" => "73120075", "619" => "60020290", "620" => "71120077",
        "621" => "71120077", "622" => "74320073", "623" => "72020070",
        "624" => "71020072", "625" => "71023173", "626" => "71020072",
        "627" => "71021270", "628" => "71120077", "629" => "73120075",
        "630" => "71121176", "631" => "71022182", "632" => "70020270",
        "633" => "74320073", "634" => "70020270", "635" => "70320090",
        "636" => "70320090", "637" => "72120078", "638" => "72120078",
        "640" => "70020270", "641" => "70020270", "643" => "74320073",
        "644" => "70020270", "645" => "70020270", "646" => "70020270",
        "647" => "70020270", "648" => "72120078", "649" => "72122181",
        "650" => "54520194", "652" => "71021270", "653" => "70020270",
        "654" => "70020270", "655" => "72120078", "656" => "71120078",
        "657" => "71020072", "658" => "68020186", "659" => "54520194",
        "660" => "54620093", "661" => "74320073", "662" => "73120075",
        "663" => "70322192", "664" => "72120078", "665" => "70321194",
        "666" => "73322380", "667" => "60020290", "668" => "60020290",
        "669" => "73320073", "670" => "75020073", "671" => "74220075",
        "672" => "74020074", "673" => "74020074", "674" => "74120071",
        "675" => "74020074", "676" => "74020074", "677" => "72020070",
        "678" => "72020070", "679" => "54520194", "680" => "71120077",
        "681" => "67020190", "682" => "78020070", "683" => "71020072",
        "684" => "70020270", "685" => "70020270", "686" => "70020270",
        "687" => "70020270", "688" => "70020270", "689" => "70020270",
        "690" => "76520071", "692" => "70020270", "693" => "73420071",
        "694" => "70021180", "695" => "70320090", "696" => "74320073",
        "697" => "54020090", "698" => "73320073", "710" => "30220190",
        "711" => "70020270", "712" => "10020890", "714" => "76020070",
        "715" => "75020073", "717" => "74320073", "718" => "87020086",
        "719" => "37020090", "720" => "30220190", "723" => "77320072",
        "733" => "83020087", "798" => "70020270"
      }.freeze
    end

    class Rule003200 < BaseRule
      def converted_details
        if @account_number.to_i.between?(800000000, 899999999)
          msg = "Account does not support payment transactions"
          raise UnsupportedAccountDetails, msg
        end

        updated_bank_code = Rule003101::BANK_CODE_MAPPING.fetch(
          @account_number.rjust(10, "0").slice(0, 3),
          @bank_code,
        )

        { bank_code: updated_bank_code, account_number: @account_number }
      end
    end

    class Rule003301 < BaseRule
      PSEUDO_ACCOUNT_NUMBER_MAPPING = {
        "0000022222" => "5803435253",
        "0001111111" => "0039908140",
        "0000000094" => "0002711931",
        "0007777777" => "5800522694",
        "0000055555" => "5801800000",
      }.freeze

      def converted_details
        updated_bank_code = Rule003101::BANK_CODE_MAPPING.fetch(
          @account_number.rjust(10, "0").slice(0, 3),
          @bank_code,
        )

        updated_account_number = PSEUDO_ACCOUNT_NUMBER_MAPPING.fetch(
          @account_number.rjust(10, "0"),
          @account_number,
        )

        { bank_code: updated_bank_code, account_number: updated_account_number }
      end
    end

    class Rule003400 < BaseRule
      PSEUDO_ACCOUNT_NUMBER_MAPPING = {
        "0500500500" => "4340111112",
        "0000000502" => "4340118001",
      }.freeze

      def converted_details
        if @account_number.to_i.between?(800000000, 899999999)
          msg = "Account does not support payment transactions"
          raise UnsupportedAccountDetails, msg
        end

        updated_bank_code = Rule003101::BANK_CODE_MAPPING.fetch(
          @account_number.rjust(10, "0").slice(0, 3),
          @bank_code,
        )

        updated_account_number = PSEUDO_ACCOUNT_NUMBER_MAPPING.fetch(
          @account_number.rjust(10, "0"),
          @account_number,
        )

        { bank_code: updated_bank_code, account_number: updated_account_number }
      end
    end

    class Rule003501 < BaseRule
      PSEUDO_ACCOUNT_NUMBER_MAPPING = { "0000009696" => "1490196966" }.freeze

      def converted_details
        if @account_number.to_i.between?(800000000, 899999999)
          msg = "Account does not support payment transactions"
          raise UnsupportedAccountDetails, msg
        end

        updated_bank_code = Rule003101::BANK_CODE_MAPPING.fetch(
          @account_number.rjust(10, "0").slice(0, 3),
          @bank_code,
        )

        updated_account_number = PSEUDO_ACCOUNT_NUMBER_MAPPING.fetch(
          @account_number.rjust(10, "0"),
          @account_number,
        )

        { bank_code: updated_bank_code, account_number: updated_account_number }
      end
    end

    class Rule003600 < BaseRule
      def converted_details
        updated_account_number =
          case @account_number.to_i
          when 100000..899999 then @account_number + "000"
          when 30000000..59999999 then @account_number
          when 100000000..899999999 then @account_number
          when 1000000000..1999999999 then @account_number
          when 3000000000..7099999999 then @account_number
          when 8500000000..8599999999 then @account_number
          when 9000000000..9999999999 then @account_number
          else disallow
          end

        { bank_code: "20050000", account_number: updated_account_number }
      end

      private

      def disallow
        msg = "Account does not support payment transactions"
        raise UnsupportedAccountDetails, msg
      end
    end

    class Rule003700 < BaseRule
      def converted_details
        { bank_code: "30010700", account_number: @account_number }
      end
    end

    class Rule003800 < BaseRule
      def converted_details
        { bank_code: "28590075", account_number: @account_number }
      end
    end

    class Rule003900 < BaseRule
      def converted_details
        { bank_code: "28020050", account_number: @account_number }
      end
    end

    class Rule004001 < BaseRule
      def converted_details
        { bank_code: "68052328", account_number: @account_number }
      end
    end

    class Rule004100 < BaseRule
      def converted_details
        { bank_code: "50060400", account_number: "0000011404" }
      end
    end

    class Rule004200 < BaseRule
      def converted_details
        unpadded_account_number = @account_number.gsub(/\A0+/, "")

        if @account_number.to_i.between?(50462000, 50463999) ||
            @account_number.to_i.between?(50469000, 50469999)
          { bank_code: @bank_code, account_number: @account_number }
        elsif unpadded_account_number.size != 8 ||
            unpadded_account_number[3] != "0" ||
            %w[00000 00999].include?(unpadded_account_number.slice(3, 5))
          msg = "Account does not support payment transactions"
          raise UnsupportedAccountDetails, msg
        else
          { bank_code: @bank_code, account_number: @account_number }
        end
      end
    end

    class Rule004301 < BaseRule
      def converted_details
        { bank_code: "66650085", account_number: @account_number }
      end
    end

    class Rule004400 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = { "0000000202" => "0002282022" }
    end

    class Rule004501 < Rule000000
      # Rule 004501 is actually about BICs, and the BIC details are already
      # included correctly in the Bankleitzahl file and SWIFT databases
    end

    class Rule004600 < BaseRule
      def converted_details
        { bank_code: "31010833", account_number: @account_number }
      end
    end

    class Rule004700 < BaseRule
      def converted_details
        unpadded_account_number = @account_number.gsub(/\A0+/, "")

        updated_account_number =
          if unpadded_account_number.size == 8
            unpadded_account_number.ljust(10, "0")
          else
            unpadded_account_number.rjust(10, "0")
          end

        { bank_code: @bank_code, account_number: updated_account_number }
      end
    end

    class Rule004800 < BaseRule
      def converted_details
        { bank_code: "36010200", account_number: @account_number }
      end
    end

    class Rule004900 < BaseRule
      PSEUDO_ACCOUNT_NUMBER_MAPPING = {
        "0000000036" => "0002310113",
        "0000000936" => "0002310113",
        "0000000999" => "0001310113",
        "0000006060" => "0000160602",
      }.freeze

      def converted_details
        padded_account_number = @account_number.rjust(10, "0")

        updated_account_number =
          if padded_account_number[4] == "9"
            "#{padded_account_number[4, 6]}#{padded_account_number[0, 4]}"
          else
            @account_number
          end

        updated_account_number = PSEUDO_ACCOUNT_NUMBER_MAPPING.fetch(
          updated_account_number.rjust(10, "0"),
          updated_account_number,
        )

        { bank_code: @bank_code, account_number: updated_account_number }
      end
    end

    class Rule005000 < BaseRule
      def converted_details
        { bank_code: "28550000", account_number: @account_number }
      end
    end

    class Rule005100 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = {
        "0000000333" => "7832500881",
        "0000000502" => "0001108884",
        "0500500500" => "0005005000",
        "0502502502" => "0001108884",
      }
    end

    class Rule005200 < BaseRule
      PSEUDO_ACCOUNT_NUMBER_MAPPING = {
        "67220020_5308810004" => "0002662604",
        "67220020_5308810000" => "0002659600",
        "67020020_5203145700" => "7496510994",
        "69421020_6208908100" => "7481501341",
        "66620020_4840404000" => "7498502663",
        "64120030_1201200100" => "7477501214",
        "64020030_1408050100" => "7469534505",
        "63020130_1112156300" => "0004475655",
        "62030050_7002703200" => "7406501175",
        "69220020_6402145400" => "7485500252",
      }.freeze

      def converted_details
        updated_account_number = PSEUDO_ACCOUNT_NUMBER_MAPPING.fetch(
          "#{@bank_code}_#{@account_number.rjust(10, '0')}",
          nil,
        )

        if updated_account_number.nil?
          msg = "Bank code #{@bank_code} is not used for payment transactions"
          raise UnsupportedAccountDetails, msg
        end

        { bank_code: "60050101", account_number: updated_account_number }
      end
    end

    class Rule005300 < BaseRule
      PSEUDO_ACCOUNT_NUMBER_MAPPING = {
        "55050000_0000035000" => "7401555913",
        "55050000_0119345106" => "7401555906",
        "55050000_0000000908" => "7401507480",
        "55050000_0000000901" => "7401507497",
        "55050000_0000000910" => "7401507466",
        "55050000_0000035100" => "7401555913",
        "55050000_0000000902" => "7401507473",
        "55050000_0000044000" => "7401555872",
        "55050000_0110132511" => "7401550530",
        "55050000_0110024270" => "7401501266",
        "55050000_0000003500" => "7401555913",
        "55050000_0110050002" => "7401502234",
        "55050000_0055020100" => "7401555872",
        "55050000_0110149226" => "7401512248",
        "60020030_1047444300" => "7871538395",
        "60020030_1040748400" => "0001366705",
        "60020030_1000617900" => "0002009906",
        "60020030_1003340500" => "0002001155",
        "60020030_1002999900" => "0002588991",
        "60020030_1004184600" => "7871513509",
        "60020030_1000919900" => "7871531505",
        "60020030_1054290000" => "7871521216",
        "60050000_0000001523" => "0001364934",
        "60050000_0000002811" => "0001367450",
        "60050000_0000002502" => "0001366705",
        "60050000_0000250412" => "7402051588",
        "60050000_0000003009" => "0001367924",
        "60050000_0000004596" => "0001372809",
        "60050000_0000003080" => "0002009906",
        "60050000_0001029204" => "0002782254",
        "60050000_0000003002" => "0001367924",
        "60050000_0000123456" => "0001362826",
        "60050000_0000002535" => "0001119897",
        "60050000_0000005500" => "0001375703",
        "66020020_4002401000" => "7495500967",
        "66020020_4000604100" => "0002810030",
        "66020020_4002015800" => "7495530102",
        "66020020_4003746700" => "7495501485",
        "66050000_0000086567" => "0001364934",
        "66050000_0000086345" => "7402046641",
        "66050000_0000085304" => "7402045439",
        "66050000_0000085990" => "7402051588",
        "86050000_0000001016" => "7461500128",
        "86050000_0000003535" => "7461505611",
        "86050000_0000002020" => "7461500018",
        "86050000_0000004394" => "7461505714",
      }.freeze

      def converted_details
        updated_account_number = PSEUDO_ACCOUNT_NUMBER_MAPPING.fetch(
          "#{@bank_code}_#{@account_number.rjust(10, '0')}",
          nil,
        )

        {
          bank_code: updated_account_number.nil? ? @bank_code : "60050101",
          account_number: updated_account_number || @account_number,
        }
      end
    end

    class Rule005401 < BaseRule
      include PseudoAccountNumberBehaviour

      @pseudo_account_number_mapping = {
        "0000000500" => "0000500500",
        "0000000502" => "0000502502",
        "0000018067" => "0000180670",
        "0000484848" => "0000484849",
        "0000636306" => "0000063606",
        "0000760440" => "0000160440",
        "0001018413" => "0010108413",
        "0002601577" => "0026015776",
        "0005005000" => "0000500500",
        "0010796740" => "0010796743",
        "0011796740" => "0011796743",
        "0012796740" => "0012796743",
        "0013796740" => "0013796743",
        "0014796740" => "0014796743",
        "0015796740" => "0015796743",
        "0016307000" => "0163107000",
        "0016610700" => "0166107000",
        "0016796740" => "0016796743",
        "0017796740" => "0017796743",
        "0018796740" => "0018796743",
        "0019796740" => "0019796743",
        "0020796740" => "0020796743",
        "0021796740" => "0021796743",
        "0022796740" => "0022796743",
        "0023796740" => "0023796743",
        "0024796740" => "0024796743",
        "0025796740" => "0025796743",
        "0026610700" => "0266107000",
        "0026796740" => "0026796743",
        "0027796740" => "0027796743",
        "0028796740" => "0028796743",
        "0029796740" => "0029796743",
        "0045796740" => "0045796743",
        "0050796740" => "0050796743",
        "0051796740" => "0051796743",
        "0052796740" => "0052796743",
        "0053796740" => "0053796743",
        "0054796740" => "0054796743",
        "0055796740" => "0055796743",
        "0056796740" => "0056796743",
        "0057796740" => "0057796743",
        "0058796740" => "0058796743",
        "0059796740" => "0059796743",
        "0060796740" => "0060796743",
        "0061796740" => "0061796743",
        "0062796740" => "0062796743",
        "0063796740" => "0063796743",
        "0064796740" => "0064796743",
        "0065796740" => "0065796743",
        "0066796740" => "0066796743",
        "0067796740" => "0067796743",
        "0068796740" => "0068796743",
        "0069796740" => "0069796743",
        "1761070000" => "0176107000",
        "2210531180" => "0201053180",
      }
    end

    class Rule005500 < BaseRule
      def converted_details
        { bank_code: "25410200", account_number: @account_number }
      end
    end

    class Rule005600 < BaseRule
      EXCEPTION_BANK_CODES = %w[
        10010111 26510111 36210111 48010111 59010111 70010111 13010111 27010111
        37010111 50010111 60010111 72010111 16010111 28010111 38010111 50510111
        63010111 75010111 20010111 29010111 39010111 51010111 65310111 76010111
        21010111 29210111 40010111 51310111 66010111 79010111 21210111 30010111
        41010111 51410111 66610111 79510111 23010111 31010111 42010111 52010111
        67010111 81010111 25010111 33010111 42610112 54210111 67210111 82010111
        25410111 35010111 43010111 55010111 68010111 86010111 25910111 35211012
        44010111 57010111 68310111 26010111 36010111 46010111 58510111 69010111
      ].freeze

      PSEUDO_ACCOUNT_NUMBER_MAPPING = {
        "0000000036" => "1010240003",
        "0000000050" => "1328506100",
        "0000000099" => "1826063000",
        "0000000110" => "1015597802",
        "0000000240" => "1010240000",
        "0000000333" => "1011296100",
        "0000000555" => "1600220800",
        "0000000556" => "1000556100",
        "0000000606" => "1967153801",
        "0000000700" => "1070088000",
        "0000000777" => "1006015200",
        "0000000999" => "1010240001",
        "0000001234" => "1369152400",
        "0000001313" => "1017500000",
        "0000001888" => "1241113000",
        "0000001953" => "1026500901",
        "0000001998" => "1547620500",
        "0000002007" => "1026500907",
        "0000004004" => "1635100100",
        "0000004444" => "1304610900",
        "0000005000" => "1395676000",
        "0000005510" => "1611754300",
        "0000006060" => "1000400200",
        "0000006800" => "1296401301",
        "0000055555" => "1027758200",
        "0000060000" => "1005007001",
        "0000066666" => "1299807801",
        "0000102030" => "1837501600",
        "0000121212" => "1249461502",
        "0000130500" => "1413482100",
        "0000202020" => "1213431002",
        "0000414141" => "1010555101",
        "0000666666" => "1798758900",
        "0005000000" => "1403124100",
        "0500500500" => "1045720000",
      }.freeze

      def converted_details
        updated_account_number = PSEUDO_ACCOUNT_NUMBER_MAPPING.fetch(
          @account_number.rjust(10, "0"),
          @account_number,
        )

        if updated_account_number.gsub(/\A0+/, "").size < 10 &&
            EXCEPTION_BANK_CODES.include?(@bank_code)
          msg = "Account does not support payment transactions"
          raise UnsupportedAccountDetails, msg
        end

        { bank_code: @bank_code, account_number: updated_account_number }
      end
    end

    class Rule005700 < BaseRule
      def converted_details
        { bank_code: "66010200", account_number: @account_number }
      end
    end
  end
end
