# IBAN

IBAN is a Ruby library for manipulating and validating
[IBANs](http://en.wikipedia.org/wiki/International_Bank_Account_Number). It
allows you to:
1) Validate an IBAN's check digits and structure
2) Deconstruct an IBAN into national banking details
3) Create an IBAN from national banking details

The gem is kept up to date using the IBAN structure file from SWIFT.

## Usage

### Installation

You don't need this source code unless you want to modify the gem. If you just
want to use it, you should run:

```ruby
gem install iban-generator     # TODO: Give it a name!!
```

### Creating IBANs

All functionality is based around `IBAN` objects. To create one, simply pass a
string to `IBAN::IBAN.new`. Note that you don't need to worry about case and
whitespace:

```ruby
iban = IBAN::IBAN.new("xq75 B a dCode 666")
iban.formatted                 # => "XQ75 BADC ODE6 66"
```

### Validating an IBAN

IBANs are validated based on their structure and check-digits:

```ruby
iban = IBAN::IBAN.new("XQ75 BADCODE 666")

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

The SWIFT IBAN components are all available as methods on an `IBAN` object:

```ruby
iban = IBAN::IBAN.new("GB82 WEST 1234 5698 7654 32")

iban.country_code              # => "GB"
iban.bank_code                 # => "WEST"
iban.branch_code               # => "123456"
iban.account_number            # => "98765432"
iban.check_digits              # => "82"
```

### Creating an IBAN from national banking details

In many countries customers are familiar with national details rather than
their IBAN. For example, in the UK customers use their Account Number and Sort
Code.

To build an IBAN from local details:

```ruby
# Austria
iban = IBAN::IBANBuilder.build(
  country_code: 'AT',
  account_number: '234573201',
  bank_code: '19043'
)
iban.iban                     # => "AT611904300234573201"

# Belgium
iban = IBAN::IBANBuilder.build(
  country_code: 'BE',
  bank_code: '510',
  account_number: '007547061'
)
iban.iban                     # => "BE62510007547061"

# Cyprus
iban = IBAN::IBANBuilder.build(
  country_code: 'CY',
  account_number: '1200527600',
  bank_code: '002',
  branch_code: '00128'
)
iban.iban                     # => "CY17002001280000001200527600"

# Estonia
iban = IBAN::IBANBuilder.build(
  country_code: 'EE',
  account_number: '111020145685'
)
iban.iban                     # => "EE412200111020145685"

# Finland
iban = IBAN::IBANBuilder.build(
  country_code: 'FI',
  account_number: '123456-785'
)
iban.iban                     # => "FI2112345600000785"

# France
iban = IBAN::IBANBuilder.build(
  country_code: 'FR',
  bank_code: '20041',
  branch_code: '01005',
  account_number: '0500013M026',
  rib_key: '06'
)
iban.iban                     # => "FR1420041010050500013M02606"

# Italy
iban = IBAN::IBANBuilder.build(
  country_code: 'IT',
  bank_code: '05428',
  branch_code: '11101',
  account_number: '000000123456'
)
iban.iban                     # => "IT60X0542811101000000123456"

# Latvia
iban = IBAN::IBANBuilder.build(
  country_code: 'LV',
  account_number: '1234567890123',
  bank_code: 'BANK'
)
iban.iban                     # => "LV72BANK1234567890123"

# Luxembourg
iban = IBAN::IBANBuilder.build(
  country_code: 'LU',
  account_number: '1234567890123',
  bank_code: 'BANK'
)
iban.iban                     # => "LU75BANK1234567890123"

# Monaco
iban = IBAN::IBANBuilder.build(
  country_code: 'MC',
  bank_code: '20041',
  branch_code: '01005',
  account_number: '0500013M026'
)
iban.iban                     # => "MC9320041010050500013M02606"

# Portugal
iban = IBAN::IBANBuilder.build(
  country_code: 'PT',
  bank_code: '0002',
  branch_code: '0023',
  account_number: '00238430005'
)
iban.iban                     # => "PT50000200230023843000578"

# Slovakia
iban = IBAN::IBANBuilder.build(
  country_code: 'SK',
  bank_code: '1200',
  account_number_prefix: '19',
  account_number: '8742637541'
)
iban.iban                     # => "SK3112000000198742637541"

# Slovenia
iban = IBAN::IBANBuilder.build(
  country_code: 'SI',
  bank_code: '19100',
  account_number: '1234'
)
iban.iban                     # => "SI56191000000123438"

# Spain
iban = IBAN::IBANBuilder.build(
  country_code: 'ES',
  bank_code: '2310',
  branch_code: '0001',
  account_number: '12345'
)
iban.iban                     # => "ES8023100001180000012345"

# San Marino
iban = IBAN::IBANBuilder.build(
  country_code: 'SM',
  bank_code: '05428',
  branch_code: '11101',
  account_number: '000000123456'
)
iban.iban                     # => "SM88X0542811101000000123456"
```

Support for Germany, Greece, Ireland, Malta, The Netherlands and the
UK is coming soon.
