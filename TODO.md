- Give it a name

- Build IBANs from national banking details for each SEPA country
  - AUSTRIA: Done!
  - BELGIUM: Done!
  - CYPRUS: Done!
  - ESTONIA: Done!
  - FINLAND: Done!
  - FRANCE: Done!
  - GERMANY: Done!
  - GREECE: TODO
  - IRELAND: TODO
  - ITALY: Done!
  - LATVIA: Done!
  - LUXEMBOURG: Done!
  - MALTA: TODO
  - NETHERLANDS: TODO
  - PORTUGAL: Done!
  - SLOVAKIA: Done!
  - SLOVENIA: Done!
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
