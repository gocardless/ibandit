- Give it a name

- Build IBANs from national banking details (e.g., UK account number and sort code).
  1) Understand what this looks like for each country. For the UK, it involves:
    - Looking up the BIC from the SWIFT Bank Directory Plus database
    - Using the BIC to calculate the Bank Code (first 4 digits)
    - Combining the Bank Code, Sort Code and Account Number to get the BBAN
  2) Implement country-by-country (won't be automatable)

- Validate the format of each IBAN component individually or remove the format
  validator (which would then be the job of a modulus checking gem)

- Specs for IBANSTRUCTURE parser
