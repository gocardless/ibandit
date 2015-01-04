# Ibandit

Ibandit is a Ruby library for manipulating and validating
[IBANs](http://en.wikipedia.org/wiki/International_Bank_Account_Number). It
allows you to:

1. Create an IBAN from national banking details
2. Deconstruct an IBAN into national banking details
3. Validate an IBAN's check digits and structure

Ibandit also provides helper methods for validating some countries' local
account details.

The gem is kept up to date using the IBAN structure file from SWIFT.

## Usage

### Installation

You don't need this source code unless you want to modify the gem. If you just
want to use it, you should run:

```ruby
gem install ibandit
```

### Creating IBANs

All functionality is based around `IBAN` objects. To create one, simply pass a
string to `Ibandit::IBAN.new`. Note that you don't need to worry about case and
whitespace:

```ruby
iban = Ibandit::IBAN.new("xq75 B a dCode 666")
iban.to_s                      # => "XQ75BADCODE666"
iban.to_s(:formatted)          # => "XQ75 BADC ODE6 66"
```

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
- `check_digits`
- `characters`
- `length`
- `format`

### Deconstructing an IBAN into national banking details

SWIFT define the following components for IBANs, and publish details of how each
county combines them:

`country_code`
:    The [ISO 3166-1](http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements) country code prefix

`check_digits`
:    Two digits calculated using part of the ISO/IEC 7064:2003 standard

`bank_code`
:    The SWIFT identifier for the bank to which the IBAN refers

`branch_code`
:    The SWIFT identifer for the branch to which the IBAN refers (not used in all countries)

`account_number`
:    The account number for the account

`iban_national_id`
:    The national ID for the bank / branch as documented by SWIFT

The SWIFT IBAN components are all available as methods on an `IBAN` object:

```ruby
iban = Ibandit::IBAN.new("GB82 WEST 1234 5698 7654 32")

iban.country_code              # => "GB"
iban.check_digits              # => "82"
iban.bank_code                 # => "WEST"
iban.branch_code               # => "123456"
iban.account_number            # => "98765432"
iban.iban_national_id          # => "WEST123456"
```

In addition, it is often useful to extract any local check digits from the IBAN.
These are available through a `local_check_digits` method:

```ruby
iban = Ibandit::IBAN.new("ES12 1234 5678 9112 3456 7890")

iban.local_check_digits        # => "91"
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
iban = Ibandit::IBANBuilder.build(
  country_code: 'AT',
  account_number: '234573201',
  bank_code: '19043'
)
iban.iban                     # => "AT611904300234573201"

# Belgium
iban = Ibandit::IBANBuilder.build(
  country_code: 'BE',
  account_number: '510-0075470-61'
)
iban.iban                     # => "BE62510007547061"

# Cyprus
iban = Ibandit::IBANBuilder.build(
  country_code: 'CY',
  account_number: '1200527600',
  bank_code: '002',
  branch_code: '00128'
)
iban.iban                     # => "CY17002001280000001200527600"

# Germany
iban = Ibandit::IBANBuilder.build(
  country_code: 'DE',
  bank_code: '37040044',
  account_number: '0532013000'
)
iban.iban                     # => "DE89370400440532013000"

# Estonia
iban = Ibandit::IBANBuilder.build(
  country_code: 'EE',
  account_number: '111020145685'
)
iban.iban                     # => "EE412200111020145685"

# Finland
iban = Ibandit::IBANBuilder.build(
  country_code: 'FI',
  bank_code: '123456'
  account_number: '785'
)
iban.iban                     # => "FI2112345600000785"

# France
iban = Ibandit::IBANBuilder.build(
  country_code: 'FR',
  bank_code: '20041',
  branch_code: '01005',
  account_number: '0500013M02606',
)
iban.iban                     # => "FR1420041010050500013M02606"

# United Kingdom
iban = Ibandit::IBANBuilder.build(
  country_code: 'GB',
  bank_code: 'BARC', # optional if a BIC finder is configured
  branch_code: '200000',
  account_number: '55779911'
)
iban.iban                     # => "GB60BARC20000055779911"

# Ireland
iban = Ibandit::IBANBuilder.build(
  country_code: 'IE',
  bank_code: 'AIBK', # optional if a BIC finder is configured
  branch_code: '931152',
  account_number: '12345678'
)
iban.iban                     # => "IE29AIBK93115212345678"

# Italy
iban = Ibandit::IBANBuilder.build(
  country_code: 'IT',
  bank_code: '05428',
  branch_code: '11101',
  account_number: '000000123456'
)
iban.iban                     # => "IT60X0542811101000000123456"

# Latvia
iban = Ibandit::IBANBuilder.build(
  country_code: 'LV',
  account_number: '1234567890123',
  bank_code: 'BANK'
)
iban.iban                     # => "LV72BANK1234567890123"

# Luxembourg
iban = Ibandit::IBANBuilder.build(
  country_code: 'LU',
  account_number: '1234567890123',
  bank_code: 'BANK'
)
iban.iban                     # => "LU75BANK1234567890123"

# Monaco
iban = Ibandit::IBANBuilder.build(
  country_code: 'MC',
  bank_code: '20041',
  branch_code: '01005',
  account_number: '0500013M026'
)
iban.iban                     # => "MC9320041010050500013M02606"

# The Netherlands
iban = Ibandit::IBANBuilder.build(
  country_code: 'NL',
  account_number: '0417164300',
  bank_code: 'ABNA'
)
iban.iban                     # => "NL91ABNA0417164300"

# Portugal
iban = Ibandit::IBANBuilder.build(
  country_code: 'PT',
  bank_code: '0002',
  branch_code: '0023',
  account_number: '0023843000578'
)
iban.iban                     # => "PT50000200230023843000578"

# Slovakia
iban = Ibandit::IBANBuilder.build(
  country_code: 'SK',
  bank_code: '1200',
  account_number_prefix: '19',
  account_number: '8742637541'
)
iban.iban                     # => "SK3112000000198742637541"

# Slovenia
iban = Ibandit::IBANBuilder.build(
  country_code: 'SI',
  bank_code: '19100',
  account_number: '1234'
)
iban.iban                     # => "SI56191000000123438"

# Spain
iban = Ibandit::IBANBuilder.build(
  country_code: 'ES',
  bank_code: '2310',
  branch_code: '0001',
  account_number: '180000012345'
)
iban.iban                     # => "ES8023100001180000012345"

# Spain with 20 digit account number
iban = Ibandit::IBANBuilder.build(
  country_code: 'ES',
  account_number: '23100001180000012345'
)
iban.iban                     # => "ES8023100001180000012345"

# San Marino
iban = Ibandit::IBANBuilder.build(
  country_code: 'SM',
  bank_code: '05428',
  branch_code: '11101',
  account_number: '000000123456'
)
iban.iban                     # => "SM88X0542811101000000123456"
```

Support for Greece and Malta is coming soon.

## Other libraries

Another gem, [iban-tools](https://github.com/alphasights/iban-tools), also
exists and is an excellent choice if you only require basic IBAN validation.
We built Ibandit because iban-tools doesn't provide a comprehensive, consistent
interface for the construction and deconstruction of IBANs into national
details.
