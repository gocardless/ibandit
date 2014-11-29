module IBAN
  module IBANBuilder
    SUPPORTED_COUNTRY_CODES = ['ES']

    def self.build(opts)
      country_code = opts.delete(:country_code)

      if country_code.nil?
        msg = "You must provide a country_code"
        raise ArgumentError.new(msg)
      elsif !SUPPORTED_COUNTRY_CODES.include?(country_code)
        msg = "Don't know how to build an IBAN for country code #{country_code}"
        raise ArgumentError.new(msg)
      else
        self.send(:"build_#{country_code.downcase}_iban", opts)
      end
    end

    def self.build_es_iban(opts)
      %i(bank_code branch_code account_number).each do |arg|
        msg = "#{arg} is a required field when building an ES IBAN"
        raise ArgumentError.new(msg) unless opts[arg]
      end

      bban = [
        opts[:bank_code],
        opts[:branch_code],
        mod_11_check_digit('00' + opts[:bank_code] + opts[:branch_code]),
        mod_11_check_digit(opts[:account_number]),
        opts[:account_number]
      ].join

      IBAN.new("ES#{iban_check_digits("ES", bban)}#{bban}")
    end

    ##########################
    # Check digit generation #
    ##########################

    def self.mod_11_check_digit(digits)
      scaled_values = digits.chars.map.with_index do |digit, i|
        digit.to_i * (2 ** i % 11)
      end
      result = 11 - scaled_values.inject(:+) % 11
      result < 10 ? result.to_s : (11 - result).to_s
    end

    def self.iban_check_digits(country_code, bban)
      iban_chars = bban + country_code + "00"
      iban_digits = iban_chars.bytes.map do |byte|
        case byte
        when 48..57 then byte.chr           # 0..9
        when 65..90 then (byte - 55).to_s   # A..Z
        else raise "Unexpected byte '#{byte}' in IBAN code"
        end
      end
      remainder = iban_digits.join.to_i % 97
      format('%02d', 98 - remainder)
    end
  end
end
