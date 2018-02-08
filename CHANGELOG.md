## 0.11.9 - February 8, 2018

- Add support for Australian swift national ids

## 0.11.8 - February 8, 2018

- Incorrectly published version. Please do not use.

## 0.11.7 - December 20, 2017

- Add support for Australian pseudo-IBANs

## 0.11.6 - August 16, 2017

- Handle invalid characters when computing check digits for Italy

## 0.11.5 - June 16, 2017

- Fix invalid regular expression `account_number_format` for Dominican Republic IBANs.

## 0.11.4 - March 13, 2017

- Fix `swift_national_id` for Slovenian IBANs. Previously it was
  returning two digits, instead of five.

## 0.11.3 -  March 9, 2017

- Fix bug: Previously, constructing an `Ibandit::IBAN` object with
  `country_code: "SE"` and certain 4-digit values for `account_number`
  would throw `NoMethodError`. The IBAN object can now be successfully
  constructed (and will return a false value for `valid?`).

## 0.11.2 -  July 4, 2016

- Handle invalid pseudo-IBANs

## 0.11.1 -  June 6, 2016

- Update BLZ data

## 0.11.0 -  March 30, 2016

- BREAKING CHANGE: Rename `IBAN#iban_national_id` to `IBAN#swift_national_id`.
  See https://github.com/gocardless/ibandit/pull/69 for more details.

## 0.10.1 -  March 7, 2016

- Update BLZ data

## 0.10.0 -  February 25, 2016

- BREAKING CHANGE: Pass an `Ibandit::IBAN` object to modulus checker hooks,
  rather than a string. See https://github.com/gocardless/ibandit/pull/68 for
  more details.

## 0.9.1 -  January 26, 2016

- Update BLZ data

## 0.9.0 -  January 25, 2016

- BREAKING CHANGE: Update modulus checker hooks to expect a `valid_branch_code?`
  method. See https://github.com/gocardless/ibandit/pull/65 for more details.

## 0.8.8 -  January 22, 2016

- Strip whitespace from Spanish account numbers

## 0.8.7 -  December 8, 2015

- Handle bad characters gracefully when constructing Italian IBANs

## 0.8.6 -  December 6, 2015

- Add details of Swedish validation scheme to Swedish data file
- Update BLZ data

## 0.8.5 - November 20, 2015

- Handle Danish long-format account numbers without a hyphen

## 0.8.4 - October 15, 2015

- Fix bug in Sweden::Validator.valid_serial_number_length?

## 0.8.3 - September 5, 2015

- Update BLZ data (again)

## 0.8.2 - September 5, 2015

- Update BLZ data

## 0.8.1 - August 14, 2015
- Clean SWIFT details

## 0.8.0 - August 14, 2015
- Return local details for Sweden
- Introduce pseudo-IBANs for Sweden

## 0.7.0 - August 11, 2015
- Remove all unused `CheckDigit` methods

## 0.6.6 - July 31, 2015
- Add Croatia to LocalDetailsCleaner and IBANAssembler
- Add Czech Republic to LocalDetailsCleaner and IBANAssembler

## 0.6.5 - July 30, 2015
- Add Romania to LocalDetailsCleaner and IBANAssembler
- Add Bulgaria to LocalDetailsCleaner and IBANAssembler
- Add Hungary to LocalDetailsCleaner and IBANAssembler

## 0.6.4 - July 28, 2015

- Add Poland to LocalDetailsCleaner and IBANAssembler
- Add Iceland to LocalDetailsCleaner and IBANAssembler

## 0.6.3 - July 25, 2015

- Strip out additional '-' characters from Danish account numbers

## 0.6.2 - July 21, 2015

- Add Denmark to LocalDetailsCleaner and IBANAssembler

## 0.6.1 - July 21, 2015

- Add Norway to LocalDetailsCleaner and IBANAssembler

## 0.6.0 - July 20, 2015

- Add support for Sweden

## 0.5.0 - July 12, 2015

- Add an error for unsupported German bank details, and stop raising whilst
  cleaning them

## 0.4.5 - June 25, 2015

- Add Dutch translation

## 0.4.4 - June 5, 2015

- Update BLZ data

## 0.4.3 - May 20, 2015

- Add Italian translation

## 0.4.2 - May 19, 2015

- Bug fix for `CheckDigit.belgian` by [@isaacseymour](https://github.com/isaacseymour)

## 0.4.1 - April 28, 2015

- Add Spanish translation by [@alan](https://github.com/alan), [@sinjo](https://github.com/sinjo) and Jess Milligan

## 0.4.0 - April 24, 2015

- Update length of national ID for Spain from 8 characters to 4, in line with
  SWIFT change

## 0.3.8 - April 8, 2015

- Add Portuguese translation by [@nlopes](https://github.com/nlopes)

## 0.3.7 - April 7, 2015

- Add German translation by [@georg911](https://github.com/georg911)

## 0.3.6 - March 23, 2015

- Fix the load path for I18n

## 0.3.5 - March 23, 2015

- Use I18n for internationalised validation messages (patch by [@isaacseymour](https://github.com/isaacseymour))

## 0.3.4 - March 6, 2015

- Update BLZ data

## 0.3.3 - March 4, 2015

- Add Greece to LocalDetailsCleaner and IBANAssembler

## 0.3.2 - February 24, 2015

- Allow for injection of a modulus checker

## 0.3.1 - February 14, 2015

- Add Malta to LocalDetailsCleaner and IBANAssembler

## 0.3.0 - February 6, 2015

- Move IBANBuilder interface into main IBAN class by overloading its constructor
- Move validation of local details input out of IBANBuilder into IBAN
- Split `IBAN.valid_length?` into individual checks on the length of bank code, branch code, and account number
- Return `nil` for fields which aren't present, rather than an empty string

## 0.2.1 - January 30, 2015

- Add Lithuania to IBANBuilder

## 0.2.0 - January 27, 2015

- Add GermanDetailsConverter

## 0.1.1 - January 8, 2015

- Add zero-padding to CheckDigit.spanish

## 0.1.0 - December 29, 2014

- Initial public release

## 0.0.16 - December 29, 2014

- Fix error handling in Modulus 97-10 check digit calculation

## 0.0.15 - December 26, 2014

- Raise namespaced errors

## 0.0.14 - December 17, 2014

- Add the Netherlands to IBANBuilder, and rename CheckDigit.mod_11

## 0.0.13 - December 17, 2014

- Send cleaned (de-space/hyphenated) sort codes to the BIC finder lambda

## 0.0.12 - December 16, 2014

- Allow spaced as well as hyphenated UK sort codes

## 0.0.11 - December 15, 2014

- `IBAN#to_s` returns IBAN string rather than object properties
- Local check digits accessors
- Only raises `ArgumentError`
- Additional documentation on local details/IBAN conversion quirks

## 0.0.10 - December 13, 2014

- Update format validations for all IBAN countries. Add local_check_digits
  accessor method to IBAN.

## 0.0.5 - December 8, 2014

- Add IBANSTRUCTURE file. All IBAN countries are now supported for validation
  and deconstruction.

## 0.0.2 - December 4, 2014

- Rename to ibandit

## 0.0.1 - November 27, 2014

- Initial commit
