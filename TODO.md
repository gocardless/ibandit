- [] Build IBANs from national banking details (e.g., UK account number and sort code).
     This is hard because the bank_code needs to beblooked up, probably from the
     Bank Directory Plus file
- [] Validate the format of each IBAN component individually or remove the format
     validator (which would then be the job of a modulus checking gem)
