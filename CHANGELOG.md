# 0.3.5 - March 23, 2015

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
