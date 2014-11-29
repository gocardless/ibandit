# IBAN Utils

IBAN Utils is a Ruby library for manipulating and validating
[IBANs](http://en.wikipedia.org/wiki/International_Bank_Account_Number). It
allows you to:
1) Validate an IBAN's check digits and structure
2) Deconstruct an IBAN into national banking details

The gem is kept up to date using the IBAN structure file from SWIFT.

## Usage

### Installation

You don't need this source code unless you want to modify the gem. If you just
want to use it, you should run:

```ruby
gem install iban-utils
````

### Creating IBANs

All functionality is based around `IBAN` objects. To create one, simply pass a
string to `IBAN::IBAN.new`. Note that you don't need to worry about case and
whitespace:

```ruby
iban = IBAN::IBAN.new("xq75 B a dCode 666")
iban.pretty                    # => "XQ75 BADC ODE6 66"
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
