- Give it a name

- Build IBANs from national banking details for each SEPA country
  - AUSTRIA: Done!
  - BELGIUM: Done!
  - CYPRUS: TODO
  - ESTONIA: Done!
  - FINLAND: TODO
  - FRANCE: Done!
  - GERMANY: TODO
  - GREECE: TODO
  - IRELAND: TODO
  - ITALY: Done!
  - LATVIA: TODO
  - LUXEMBOURG: TODO
  - MALTA: TODO
  - NETHERLANDS: TODO
  - PORTUGAL: Done!
  - SLOVAKIA: TODO
  - SLOVENIA: TODO
  - SPAIN: Done!
  - MONACO: Done!
  - SAN_MARINO: Done!
  - UK: TODO
    - Looking up the BIC from the SWIFT Bank Directory Plus database
    - Using the BIC to calculate the Bank Code (first 4 digits)
    - Combining the Bank Code, Sort Code and Account Number to get the BBAN

- Validate the format of each IBAN component individually or remove the format
  validator (which would then be the job of a modulus checking gem)

- Specs for IBANSTRUCTURE parser
