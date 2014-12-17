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
