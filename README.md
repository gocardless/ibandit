Ibandit [![CircleCI](https://circleci.com/gh/gocardless/business.svg?style=svg)](https://circleci.com/gh/gocardless/business)
=======

Ibandit is a Ruby library for manipulating and validating
[IBANs](http://en.wikipedia.org/wiki/International_Bank_Account_Number).

The primary objective is to provide an interface that enables the storage and retrieval of national banking details as a single value. This may be an IBAN, if a country fully and unambiguously supports it, or a combination of IBAN and/or pseudo-IBAN.

Therefore, there are three distinct modes:

1. For countries that support any form of IBAN: construct and validate IBAN from national banking details
2. For countries that have unambiguous IBANs: deconstruct an IBAN into national banking details
3. For countries where either of the above is not possible: a pseudo-IBAN as a substitute for the above.

For storage, you should always try to use the `pseudo_iban`, falling back to `iban` if it is not available.

For example:
- Sweden does support IBANs (**1.**) but the format is ambiguous due to variable length account numbers so they cannot be deconstructed (**2.**). For persistence, we therefore recommend using pseudo-IBANs (**3.**) because the national banking details can be recovered from them.
- Australia does not support IBANs (**1.** & **2.**), therefore pseudo-IBANs (**3.**) can be created from national banking details for storage. To get back the national banking details, you can pass the pseudo-IBAN to Ibandit and it will parse out the national banking details again for use.

# Supported Countries

| Country         | Construct and Validate IBANs | Deconstruct IBANs  | Pseudo IBANs       |
|-----------------|:----------------------------:|:------------------:|:------------------:|
| Australia       |                              |                    | :white_check_mark: |
| Austria         | :white_check_mark:           | :white_check_mark: |                    |
| Belgium         | :white_check_mark:           | :white_check_mark: |                    |
| Bulgaria        | :white_check_mark:           | :white_check_mark: |                    |
| Croatia         | :white_check_mark:           | :white_check_mark: |                    |
| Canada          |                              |                    | :white_check_mark: |
| Cyprus          | :white_check_mark:           | :white_check_mark: |                    |
| Czech Republic  | :white_check_mark:           | :white_check_mark: |                    |
| Denmark         | :white_check_mark:           | :white_check_mark: |                    |
| Estonia         | :white_check_mark:           | :white_check_mark: |                    |
| Finland         | :white_check_mark:           | :white_check_mark: |                    |
| France          | :white_check_mark:           | :white_check_mark: |                    |
| Germany         | :white_check_mark:           | :white_check_mark: |                    |
| Greece          | :white_check_mark:           | :white_check_mark: |                    |
| Hungary         | :white_check_mark:           | :white_check_mark: |                    |
| Ireland         | :white_check_mark:           | :white_check_mark: |                    |
| Iceland         | :white_check_mark:           | :white_check_mark: |                    |
| Italy           | :white_check_mark:           | :white_check_mark: |                    |
| Latvia          | :white_check_mark:           | :white_check_mark: |                    |
| Lithuania       | :white_check_mark:           | :white_check_mark: |                    |
| Luxembourg      | :white_check_mark:           | :white_check_mark: |                    |
| Monaco          | :white_check_mark:           | :white_check_mark: |                    |
| Malta           | :white_check_mark:           | :white_check_mark: |                    |
| Netherlands     | :white_check_mark:           | :white_check_mark: |                    |
| Norway          | :white_check_mark:           | :white_check_mark: |                    |
| New Zealand     |                              |                    | :white_check_mark: |
| Poland          | :white_check_mark:           | :white_check_mark: |                    |
| Portugal        | :white_check_mark:           | :white_check_mark: |                    |
| Romania         | :white_check_mark:           | :white_check_mark: |                    |
| San Marino      | :white_check_mark:           | :white_check_mark: |                    |
| Slovakia        | :white_check_mark:           | :white_check_mark: |                    |
| Slovenia        | :white_check_mark:           | :white_check_mark: |                    |
| Spain           | :white_check_mark:           | :white_check_mark: |                    |
| Sweden          | :white_check_mark:           |                    | :white_check_mark: |
| United Kingdom  | :white_check_mark:           | :white_check_mark: |                    |
| USA             |                              |                    | :white_check_mark: |

## Usage

### Installation

You don't need this source code unless you want to modify the gem. If you just
want to use it, you should run:

```ruby
gem install ibandit
```

### Creating IBANs

All functionality is based around `IBAN` objects. To create one, simply pass a
string to `Ibandit::IBAN.new`:

```ruby
iban = Ibandit::IBAN.new("xq75 B a dCode 666")
iban.to_s                      # => "XQ75BADCODE666"
iban.to_s(:formatted)          # => "XQ75 BADC ODE6 66"
```

Alternatively, you can [create an IBAN from national banking details](#creating-an-iban-from-national-banking-details).

### Validating an IBAN

IBANs are validated based on their structure and check-digits:

```ruby
iban = Ibandit::IBAN.new("XQ75 BADCODE 666")

iban.valid?                    # => false
```

After validations, you can fetch details of any errors:

```ruby
iban.errors                    # => { country_code: "'XQ' is not a valid..." }
```

The following error keys may be set:
- `country_code`
- `bank_code`
- `branch_code`
- `account_number`
- `check_digits`
- `characters`
- `length`
- `format`

Ibandit will also apply local modulus checks if you set a modulus checker:

```ruby
module ModulusChecker
  def self.valid_bank_code?(iban)
    # some_codes
  end

  def self.valid_branch_code?(iban)
    # some_codes
  end

  def self.valid_account_number?(iban)
    # some_codes
  end
end

Ibandit.modulus_checker = ModulusChecker
```

All three of the `valid_bank_code?`, `valid_branch_code?` and `valid_account_number?` methods will receive an `IBAN` object.
`valid_bank_code?` and `valid_branch_code?` should return true unless it is known that the bank/branch code in this IBAN
are invalid in the country specified. `valid_account_number?` should return true unless it is known that the account number
in this IBAN cannot be valid due to local modulus checking rules.

### Deconstructing an IBAN into national banking details

SWIFT define the following components for IBANs, and publish details of how each
country combines them:

`country_code`
:    The [ISO 3166-1](http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements) country code prefix

`check_digits`
:    Two digits calculated using part of the ISO/IEC 7064:2003 standard

`swift_bank_code`
:    The SWIFT identifier for the bank to which the IBAN refers

`swift_branch_code`
:    The SWIFT identifer for the branch to which the IBAN refers (not used in all countries)

`swift_account_number`
:    The account number for the account

`swift_national_id`
:    The national ID for the bank / branch as documented by SWIFT

The SWIFT IBAN components are all available as methods on an `IBAN` object:

```ruby
iban = Ibandit::IBAN.new("GB82 WEST 1234 5698 7654 32")

iban.country_code              # => "GB"
iban.check_digits              # => "82"
iban.swift_bank_code           # => "WEST"
iban.swift_branch_code         # => "123456"
iban.swift_account_number      # => "98765432"
iban.swift_national_id         # => "WEST123456"
```

In addition, it is often useful to extract any local check digits from the IBAN.
These are available through a `local_check_digits` method:

```ruby
iban = Ibandit::IBAN.new("ES12 1234 5678 9112 3456 7890")

iban.local_check_digits        # => "91"
```

In some countries, the SWIFT-defined details differ from the local details that
customers are familiar with.  For this reason, there are also `bank_code`,
`branch_code` and `account_number` methods on an `IBAN` object.  At present,
these only differ from the `swift_` equivalents for Swedish bank accounts.

```ruby
iban = Ibandit::IBAN.new(
  country_code: 'SE',
  account_number: '7507-1211203'
)
iban.swift_account_number      # => "75071211203"
iban.account_number            # => "1211203"

iban.swift_branch_code         # => nil
iban.branch_code               # => "7507"
```

### Initializing Ibandit

The UK and Ireland both use part of the BIC as the `bank_code` in their IBANs.
If you wish to construct UK or Irish IBANs you will either need to pass the
`bank_code` explicitly, or configure Ibandit with a BIC finder:

```ruby
# config/initializers/ibandit.rb
Ibandit.bic_finder = -> (country_code, national_id) do
  # This assumes you have `BankDirectoryPlus` set up to access the data provided
  # by SWIFTRef in their Bank Directory Plus product. The `national_id` is the
  # local national ID, not the "IBAN National ID" referred to in the IBAN Plus
  # file (since that is the `bank_code` and the `branch_code`).
 BankDirectoryPlus.find_by(country_code: country_code,
                           national_id: national_id).
                   try(:bic)
end
```

### Creating an IBAN from national banking details

In many countries customers are familiar with national details rather than
their IBAN. For example, in the UK customers use their Account Number and Sort
Code.

To build an IBAN from local details:

```ruby
# Austria
iban = Ibandit::IBAN.new(
  country_code: 'AT',
  account_number: '234573201',
  bank_code: '19043'
)
iban.iban                     # => "AT611904300234573201"

# Belgium
iban = Ibandit::IBAN.new(
  country_code: 'BE',
  account_number: '510-0075470-61'
)
iban.iban                     # => "BE62510007547061"

# Bulgaria
iban = Ibandit::IBAN.new(
  country_code: 'BG',
  bank_code: 'BNBG',
  branch_code: '9661'
  account_number: '1020345678'
)
iban.iban                     # => "BG80BNBG96611020345678"

# Croatia
iban = Ibandit::IBAN.new(
  country_code: 'HR',
  account_number: '1001005-1863000160',
)
iban.iban                     # => "HR1210010051863000160"

# Cyprus
iban = Ibandit::IBAN.new(
  country_code: 'CY',
  account_number: '1200527600',
  bank_code: '002',
  branch_code: '00128'
)
iban.iban                     # => "CY17002001280000001200527600"

# Czech Republic
iban = Ibandit::IBAN.new(
  country_code: 'CZ',
  bank_code: '0800',
  account_number_prefix: '19',
  account_number: '2000145399'
)
iban.iban                     # => "CZ6508000000192000145399"

# Denmark
iban = Ibandit::IBAN.new(
  country_code: 'DK',
  account_number: '345-3179681',
)
iban.iban                     # => "DK8003450003179681"

# Estonia
iban = Ibandit::IBAN.new(
  country_code: 'EE',
  account_number: '111020145685'
)
iban.iban                     # => "EE412200111020145685"

# Finland
iban = Ibandit::IBAN.new(
  country_code: 'FI',
  bank_code: '123456'
  account_number: '785'
)
iban.iban                     # => "FI2112345600000785"

# France
iban = Ibandit::IBAN.new(
  country_code: 'FR',
  bank_code: '20041',
  branch_code: '01005',
  account_number: '0500013M02606',
)
iban.iban                     # => "FR1420041010050500013M02606"

# Germany
iban = Ibandit::IBAN.new(
  country_code: 'DE',
  bank_code: '37040044',
  account_number: '0532013000'
)
iban.iban                     # => "DE89370400440532013000"

# Greece
iban = Ibandit::IBAN.new(
  country_code: 'GR',
  bank_code: '011',
  branch_code: '0125',
  account_number: '0000000012300695'
)
iban.iban                     # => "GR16011012500000000012300695"

# Hungary
iban = Ibandit::IBAN.new(
  country_code: 'HU',
  account_number: '11773016-11111018'
)
iban.iban                     # => "HU42117730161111101800000000"

# Ireland
iban = Ibandit::IBAN.new(
  country_code: 'IE',
  bank_code: 'AIBK', # optional if a BIC finder is configured
  branch_code: '931152',
  account_number: '12345678'
)
iban.iban                     # => "IE29AIBK93115212345678"

# Iceland
iban = Ibandit::IBAN.new(
  country_code: 'IS',
  bank_code: '1175'
  account_number: '26-19530-670269-6399'
)
iban.iban                     # => "IS501175260195306702696399"

# Italy
iban = Ibandit::IBAN.new(
  country_code: 'IT',
  bank_code: '05428',
  branch_code: '11101',
  account_number: '000000123456'
)
iban.iban                     # => "IT60X0542811101000000123456"

# Latvia
iban = Ibandit::IBAN.new(
  country_code: 'LV',
  account_number: '1234567890123',
  bank_code: 'BANK'
)
iban.iban                     # => "LV72BANK1234567890123"

# Lithuania
iban = Ibandit::IBAN.new(
  country_code: 'LT',
  account_number: '11101001000',
  bank_code: '10000'
)
iban.iban                     # => "LT1000011101001000"

# Luxembourg
iban = Ibandit::IBAN.new(
  country_code: 'LU',
  account_number: '1234567890123',
  bank_code: 'BANK'
)
iban.iban                     # => "LU75BANK1234567890123"

# Monaco
iban = Ibandit::IBAN.new(
  country_code: 'MC',
  bank_code: '20041',
  branch_code: '01005',
  account_number: '0500013M026'
)
iban.iban                     # => "MC9320041010050500013M02606"

# Malta
iban = Ibandit::IBAN.new(
  country_code: 'MT',
  bank_code: 'MMEB', # optional if a BIC finder is configured
  branch_code: '44093',
  account_number: '9027293051'
)
iban.iban                     # => "MT98MMEB44093000000009027293051"

# The Netherlands
iban = Ibandit::IBAN.new(
  country_code: 'NL',
  account_number: '0417164300',
  bank_code: 'ABNA'
)
iban.iban                     # => "NL91ABNA0417164300"

# Norway
iban = Ibandit::IBAN.new(
  country_code: 'NO',
  account_number: '8601.1117947',
)
iban.iban                     # => "NO9386011117947"

# Poland
iban = Ibandit::IBAN.new(
  country_code: 'PL',
  account_number: '60102010260000042270201111',
)
iban.iban                     # => "PL60102010260000042270201111"

# Portugal
iban = Ibandit::IBAN.new(
  country_code: 'PT',
  bank_code: '0002',
  branch_code: '0023',
  account_number: '0023843000578'
)
iban.iban                     # => "PT50000200230023843000578"

# Romania
iban = Ibandit::IBAN.new(
  country_code: 'RO',
  bank_code: 'AAAA',
  account_number: '1B31007593840000'
)
iban.iban                     # => "RO49AAAA1B31007593840000"

# San Marino
iban = Ibandit::IBAN.new(
  country_code: 'SM',
  bank_code: '05428',
  branch_code: '11101',
  account_number: '000000123456'
)
iban.iban                     # => "SM88X0542811101000000123456"

# Slovakia
iban = Ibandit::IBAN.new(
  country_code: 'SK',
  bank_code: '1200',
  account_number_prefix: '19',
  account_number: '8742637541'
)
iban.iban                     # => "SK3112000000198742637541"

# Slovenia
iban = Ibandit::IBAN.new(
  country_code: 'SI',
  bank_code: '19100',
  account_number: '1234'
)
iban.iban                     # => "SI56191000000123438"

# Spain
iban = Ibandit::IBAN.new(
  country_code: 'ES',
  account_number: '23100001180000012345'
)
iban.iban                     # => "ES8023100001180000012345"

# Sweden
iban = Ibandit::IBAN.new(
  country_code: 'SE',
  account_number: '7507-1211203'
)
iban.iban                     # => "SE2680000000075071211203"

# United Kingdom
iban = Ibandit::IBAN.new(
  country_code: 'GB',
  bank_code: 'BARC', # optional if a BIC finder is configured
  branch_code: '200000',
  account_number: '55779911'
)
iban.iban                     # => "GB60BARC20000055779911"
```

### Pseudo-IBANs

Pseudo-IBANs can be recognized by the fact that they have `ZZ`
as the third and fourth characters (these would be check digits for a regular
IBAN). Note: pseudo-IBANs can be used in conjunction with IBANs depending on the country. See [Supported Countries](#supported-countries).

```ruby
iban = Ibandit::IBAN.new(
  country_code: 'SE',
  branch_code: '7507',
  account_number: '1211203'
)
iban.pseudo_iban              # => "SEZZX7507XXX1211203"
iban.iban                     # => "SE2680000000075071211203"

iban = Ibandit::IBAN.new('SEZZX7507XXX1211203')
iban.country_code             # => "SE"
iban.branch_code              # => "7507"
iban.account_number           # => "1211203"
iban.iban                     # => "SE2680000000075071211203"

# Australia
iban = Ibandit::IBAN.new(
  country_code: 'AU',
  branch_code: '123-456', # 6 digit BSB number
  account_number: '123456789' # 9 digit account number
)
iban.pseudo_iban              # => "AUZZ123456123456789"
iban.iban                     # => nil

iban = Ibandit::IBAN.new('AUZZ123456123456789')
iban.country_code             # => "AU"
iban.branch_code              # => "123456"
iban.account_number           # => "123456789"
iban.iban                     # => nil

# Canada
iban = Ibandit::IBAN.new(
  country_code: 'CA',
  bank_code: '0036',          # 3 or 4 digit Financial Institution number
  branch_code: '00063',       # 5 digit Branch Transit number
  account_number: '0123456'   # 7 to 12 digits
)
iban.pseudo_iban              # => "CAZZ003600063000000123456"
iban.iban                     # => nil

iban = Ibandit::IBAN.new('CAZZ003600063000000123456')
iban.country_code             # => "CA"
iban.bank_code                # => "0036"
iban.branch_code              # => "00063"
iban.account_number           # => "000000123456"
iban.iban                     # => nil

# New Zealand
iban = Ibandit::IBAN.new(
  country_code: 'NZ',
  bank_code: '01',
  branch_code: '0004',
  account_number: '3333333-44' # 7 digit account number and 2/3-digit account suffix
)
iban.pseudo_iban            # => "NZZZ0100043333333044"
iban.iban                   # => nil

iban = Ibandit::IBAN.new(
  country_code: 'NZ',
  account_number: '01-0004-3333333-44'
)
iban.pseudo_iban          # => "NZZZ0100043333333044"
iban.bank_code            # => "01"
iban.branch_code          # => "0004"
iban.account_number       # => "3333333044"

iban = Ibandit::IBAN.new('NZZZ0100043333333044')
iban.country_code         # => "NZ"
iban.bank_code            # => "01"
iban.branch_code          # => "0004"
iban.account_number       # => "3333333044"

# USA
iban = Ibandit::IBAN.new(
  country_code: 'US',
  bank_code: '026073150',      # 9-digit routing number
  account_number: '2715500356' # 1 to 17 digits
)
iban.pseudo_iban               # => "USZZ026073150_______2715500356"
iban.iban                      # => nil

iban = Ibandit::IBAN.new('USZZ026073150_______2715500356')
iban.country_code              # => "US"
iban.bank_code                 # => "026073150"
iban.account_number            # => "2715500356"
iban.iban                      # => nil
```

## Other libraries

Another gem, [iban-tools](https://github.com/alphasights/iban-tools), also
exists and is an excellent choice if you only require basic IBAN validation.
We built Ibandit because iban-tools doesn't provide a comprehensive, consistent
interface for the construction and deconstruction of IBANs into national
details.

---

GoCardless ♥ open source. If you do too, come [join us](https://gocardless.com/about/careers/).
