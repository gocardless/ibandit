require 'spec_helper'

describe Ibandit::IBAN do
  subject(:iban) { described_class.new(arg) }
  let(:arg) { iban_code }
  let(:iban_code) { 'GB82WEST12345698765432' }

  its(:iban) { is_expected.to eq(iban_code) }

  context 'with a poorly formatted IBAN' do
    let(:iban_code) { "  gb82 WeSt 1234 5698 7654 32\n" }
    its(:iban) { is_expected.to eq('GB82WEST12345698765432') }
  end

  context 'with nil' do
    let(:arg) { nil }
    specify { expect { iban }.to raise_error(TypeError) }
  end

  context 'with local details' do
    let(:arg) do
      {
        country_code: 'GB',
        bank_code: 'WEST',
        branch_code: '123456',
        account_number: '98765432'
      }
    end

    its(:iban) { is_expected.to eq('GB82WEST12345698765432') }
  end

  context 'with nil local details' do
    let(:arg) do
      {
        country_code: nil,
        bank_code: nil,
        branch_code: nil,
        account_number: nil
      }
    end

    it { is_expected.to_not be_valid }
  end

  describe 'it decomposes the IBAN' do
    its(:country_code) { is_expected.to eq('GB') }
    its(:check_digits) { is_expected.to eq('82') }
    its(:bank_code) { is_expected.to eq('WEST') }
    its(:branch_code) { is_expected.to eq('123456') }
    its(:account_number) { is_expected.to eq('98765432') }
    its(:iban_national_id) { is_expected.to eq('WEST123456') }
    its(:local_check_digits) { is_expected.to be_nil }

    context 'when the IBAN is blank' do
      let(:iban_code) { '' }

      its(:country_code) { is_expected.to be_nil }
      its(:check_digits) { is_expected.to be_nil }
      its(:bank_code) { is_expected.to be_nil }
      its(:branch_code) { is_expected.to be_nil }
      its(:account_number) { is_expected.to be_nil }
      its(:iban_national_id) { is_expected.to be_nil }
      its(:bban) { is_expected.to be_nil }
      its(:local_check_digits) { is_expected.to be_nil }
    end

    context 'when the IBAN was created with local details' do
      let(:arg) do
        {
          country_code: 'GB',
          bank_code: 'WES',
          branch_code: '1234',
          account_number: '5678'
        }
      end

      its(:country_code) { is_expected.to eq(arg[:country_code]) }
      its(:bank_code) { is_expected.to eq(arg[:bank_code]) }
      its(:branch_code) { is_expected.to eq(arg[:branch_code]) }
      its(:account_number) { is_expected.to eq(arg[:account_number]) }
    end
  end

  describe '#to_s' do
    specify { expect(iban.to_s).to eq('GB82WEST12345698765432') }
    specify { expect(iban.to_s(:compact)).to eq('GB82WEST12345698765432') }

    it 'returns a prettified string when passed :formatted' do
      expect(iban.to_s(:formatted)).to eq('GB82 WEST 1234 5698 7654 32')
    end

    specify { expect { iban.to_s(:russian) }.to raise_error ArgumentError }

    context 'with the IBAN is nil' do
      let(:arg) { { country_code: 'GB' } }
      its(:to_s) { is_expected.to_not be_nil }
      specify { expect(iban.to_s(:formatted)).to be_empty }
    end
  end

  ###############
  # Validations #
  ###############

  describe '#valid_country_code?' do
    subject { iban.valid_country_code? }

    context 'with valid details' do
      it { is_expected.to eq(true) }
    end

    context 'with an unknown country code' do
      before { iban.valid_country_code? }
      let(:iban_code) { 'AA123456789123456' }
      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_country_code?
          expect(iban.errors).
            to include(country_code: "'AA' is not a valid ISO 3166-1 IBAN " \
                                     'country code')
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_country_code?
          expect(iban.errors).
            to include(country_code: "'AA' ist keine gültige IBAN " \
                                     'Länderkennung')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_country_code?
          expect(iban.errors).
            to include(country_code: "'AA' não é um código IBAN válido para " \
                                     'país segundo o ISO 3166-1')
        end
      end
    end
  end

  describe '#valid_check_digits?' do
    subject { iban.valid_check_digits? }

    context 'with valid details' do
      let(:iban_code) { 'GB82WEST12345698765432' }
      it { is_expected.to eq(true) }

      context 'where the check digit is zero-padded' do
        let(:iban_code) { 'GB06WEST12345698765442' }
        it { is_expected.to eq(true) }
      end
    end

    context 'with invalid details' do
      let(:iban_code) { 'GB12WEST12345698765432' }
      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: 'Check digits failed modulus check. ' \
                                     "Expected '82', received '12'.")
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: 'Les chiffres de vérification ont ' \
                                     "échoué les tests de modulo. '82' " \
                                     "attendu, '12' reçu.")
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: 'Die Prüfzahlen sind inkorrekt. ' \
                                     "Erwartet wurde '82', tatsächlich " \
                                     "erhalten '12'.")
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: 'Dígitos de controlo falharam a ' \
                                     "verificação. Esperados '82', " \
                                     "recebidos '12'.")
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: 'Los dígitos de control no han pasado ' \
                                     'la verificación de módulo. Se ' \
                                     "esperaba '82', se ha recibido '12'.")
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_check_digits?
          expect(iban.errors).
            to include(check_digits: 'la cifra di controllo non ha superato ' \
                                     "il controllo del modulo. Previsto '82'" \
                                     ", ricevuto '12'.")
        end
      end
    end

    context 'with invalid characters' do
      let(:iban_code) { 'AA82-EST123456987654' }
      it { is_expected.to be_nil }

      it 'does not set errors on the IBAN' do
        iban.valid_check_digits?
        expect(iban.errors).to_not include(:check_digits)
      end
    end

    context 'with an empty IBAN' do
      let(:iban_code) { '' }
      it { is_expected.to be_nil }

      it 'does not set errors on the IBAN' do
        iban.valid_check_digits?
        expect(iban.errors).to_not include(:check_digits)
      end
    end
  end

  describe '#valid_length?' do
    subject { iban.valid_length? }

    context 'with valid details' do
      it { is_expected.to eq(true) }
    end

    context 'with invalid details' do
      let(:iban_code) { 'GB82WEST123456987654' }
      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_length?
          expect(iban.errors).
            to include(length: "Length doesn't match SWIFT specification " \
                       '(expected 22 characters, received 20)')
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_length?
          expect(iban.errors).
            to include(length: 'La longueur ne correspond pas aux ' \
                               'spécifications SWIFT (22 caractères ' \
                               'attendus, 20 reçus)')
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_length?
          expect(iban.errors).
            to include(length: 'Die Länge stimmt nicht mit der SWIFT ' \
                               'Spezifikation überein (erwartet wurden 22 ' \
                               'Zeichen, tatsächlich erhalten 20)')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_length?
          expect(iban.errors).
            to include(length: 'O tamanho não está segundo a especificação ' \
                               'SWIFT (esperados 22 caracteres, recebidos 20)')
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_length?
          expect(iban.errors).
            to include(length: 'La longitud no corresponde a la ' \
                               'especificación SWIFT (Se esperaba 22 ' \
                               'símbolos, se ha recibido 20)')
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_length?
          expect(iban.errors).
            to include(length: 'La lunghezza non corrisponde ai requisiti ' \
                               'SWIFT (Previsti 22 caratteri, ricevuti 20)')
        end
      end
    end

    context 'with an invalid country_code' do
      let(:iban_code) { 'AA82WEST123456987654' }
      it { is_expected.to be_nil }

      it 'does not set errors on the IBAN' do
        iban.valid_length?
        expect(iban.errors).to_not include(:length)
      end
    end
  end

  describe '#valid_bank_code_length?' do
    subject { iban.valid_bank_code_length? }

    context 'with valid details' do
      it { is_expected.to eq(true) }
    end

    context 'with invalid details' do
      before { allow(iban).to receive(:bank_code).and_return('WES') }
      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: 'is the wrong length (should be 4 ' \
                                  'characters)')
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: "n'a pas la bonne longueur (doit avoir 4 " \
                                  'caractères)')
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: 'hat die falsche Länge (muss genau 4 ' \
                                  'Zeichen haben)')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: 'tem o tamanho errado (deve ter 4 ' \
                                  'caracteres)')
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: 'tiene la longitud equivocada (debería ' \
                                  'formarse de 4 símbolos)')
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_length?
          expect(iban.errors).
            to include(bank_code: 'è della lunghezza sbagliata (dovrebbe ' \
                                  'essere di 4 caratteri)')
        end
      end
    end

    context 'with an invalid country_code' do
      before { allow(iban).to receive(:country_code).and_return('AA') }
      it { is_expected.to be_nil }

      it 'does not set errors on the IBAN' do
        iban.valid_bank_code_length?
        expect(iban.errors).to_not include(:bank_code)
      end
    end
  end

  describe '#valid_branch_code_length?' do
    subject { iban.valid_branch_code_length? }

    context 'with valid details' do
      it { is_expected.to eq(true) }
    end

    context 'with invalid details' do
      before { allow(iban).to receive(:branch_code).and_return('12345') }
      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: 'is the wrong length (should be 6 ' \
                       'characters)')
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: "n'a pas la bonne longueur (doit avoir 6 " \
                                    'caractères)')
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: 'hat die falsche Länge (muss genau 6 ' \
                                    'Zeichen haben)')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: 'tem o tamanho errado (deve ter 6 ' \
                                    'caracteres)')
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: 'tiene la longitud equivocada (debería ' \
                                    'formarse de 6 símbolos)')
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).
            to include(branch_code: 'è della lunghezza sbagliata (dovrebbe ' \
                                    'essere di 6 caratteri)')
        end
      end
    end

    context 'without a branch code' do
      before { allow(iban).to receive(:branch_code).and_return(nil) }
      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: 'is required')
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: 'est requis')
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: 'muss ausgefüllt werden')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: 'é requerido')
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: 'es obligatorio')
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_length?
          expect(iban.errors).to include(branch_code: 'è obbligatorio')
        end
      end
    end

    context 'with an invalid country_code' do
      before { allow(iban).to receive(:country_code).and_return('AA') }
      it { is_expected.to be_nil }

      it 'does not set errors on the IBAN' do
        iban.valid_branch_code_length?
        expect(iban.errors).to_not include(:branch_code)
      end
    end
  end

  describe '#valid_account_number_length?' do
    subject { iban.valid_account_number_length? }

    context 'with valid details' do
      it { is_expected.to eq(true) }
    end

    context 'with an invalid account_number' do
      before { allow(iban).to receive(:account_number).and_return('1234567') }
      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: 'is the wrong length (should be 8 ' \
                                       'characters)')
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: "n'a pas la bonne longueur (doit " \
                                       'avoir 8 caractères)')
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: 'hat die falsche Länge (muss genau ' \
                                       '8 Zeichen haben)')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: 'tem o tamanho errado (deve ter 8 ' \
                                       'caracteres)')
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: 'tiene la longitud equivocada ' \
                                       '(debería formarse de 8 símbolos)')
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_length?
          expect(iban.errors).
            to include(account_number: 'è della lunghezza sbagliata ' \
                                       '(dovrebbe essere di 8 caratteri)')
        end
      end
    end

    context 'with an invalid country_code' do
      before { allow(iban).to receive(:country_code).and_return('AA') }
      it { is_expected.to be_nil }

      it 'does not set errors on the IBAN' do
        iban.valid_account_number_length?
        expect(iban.errors).to_not include(:account_number)
      end
    end
  end

  describe '#valid_characters?' do
    subject { iban.valid_characters? }

    context 'with valid details' do
      let(:iban_code) { 'GB82WEST12345698765432' }
      it { is_expected.to eq(true) }
    end

    context 'with invalid details' do
      let(:iban_code) { 'GB-123ABCD' }
      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: 'Non-alphanumeric characters found: -')
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: 'Caractères non alphanumériques présents ' \
                                   ': -')
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: 'Nicht-alphanumerische Zeichen gefunden: -')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: 'Caracteres não alfanuméricos ' \
                                   'encontrados: -')
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: 'Se han econtrado símbolos no ' \
                                   'alfanuméricos: -')
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_characters?
          expect(iban.errors).
            to include(characters: 'Un carattere non-alfanumerico è stato ' \
                                   'trovato: -')
        end
      end
    end
  end

  describe '#valid_format?' do
    subject { iban.valid_format? }

    context 'with valid details' do
      let(:iban_code) { 'GB82WEST12345698765432' }
      it { is_expected.to eq(true) }
    end

    context 'with invalid details' do
      let(:iban_code) { 'GB82WEST12AAAAAA7654' }
      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_format?
          expect(iban.errors).
            to include(format: 'Unexpected format for a GB IBAN.')
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_format?
          expect(iban.errors).
            to include(format: "Format inconnu pour l'IBAN GB.")
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_format?
          expect(iban.errors).
            to include(format: 'Unerwartetes Format für eine GB IBAN.')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_format?
          expect(iban.errors).
            to include(format: 'Formato errado para um IBAN GB.')
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_format?
          expect(iban.errors).
            to include(format: 'Formato inesperado para un IBAN de GB.')
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_format?
          expect(iban.errors).
            to include(format: 'Formato non atteso per un IBAN GB.')
        end
      end
    end

    context 'with an invalid country_code' do
      let(:iban_code) { 'AA82WEST12AAAAAA7654' }
      it { is_expected.to be_nil }

      it 'does not set errors on the IBAN' do
        iban.valid_format?
        expect(iban.errors).to_not include(:format)
      end
    end
  end

  describe '#valid_bank_code_format?' do
    subject { iban.valid_bank_code_format? }

    context 'GB numeric bank code' do
      let(:arg) do
        {
          country_code: 'GB',
          bank_code: '1234',
          branch_code: '200000',
          account_number: '55779911'
        }
      end

      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: 'is invalid')
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: 'est invalide')
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: 'ist nicht gültig')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: 'é inválido')
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: 'es inválido')
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_bank_code_format?
          expect(iban.errors).to include(bank_code: 'non è valido')
        end
      end
    end

    context 'with an invalid country code' do
      let(:iban_code) { 'AA821234BANK121234567B' }

      it { is_expected.to be_nil }
    end

    context 'with a wrong-length bank code' do
      let(:arg) do
        {
          country_code: 'FR',
          bank_code: '1234',
          branch_code: '12345',
          account_number: '123456789123'
        }
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#valid_branch_code_format?' do
    subject { iban.valid_branch_code_format? }

    context 'IT non-numeric branch code' do
      let(:arg) do
        {
          country_code: 'IT',
          bank_code: '12345',
          branch_code: 'ABCDE',
          account_number: '123456789012'
        }
      end

      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: 'is invalid')
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: 'est invalide')
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: 'ist nicht gültig')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: 'é inválido')
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: 'es inválido')
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_branch_code_format?
          expect(iban.errors).to include(branch_code: 'non è valido')
        end
      end
    end

    context 'with an invalid country code' do
      let(:iban_code) { 'AA821234BANK121234567B' }

      it { is_expected.to be_nil }
    end

    context 'with a wrong-length branch code' do
      let(:arg) do
        {
          country_code: 'PT',
          bank_code: '1234',
          branch_code: 'ABC',
          account_number: '123456789123'
        }
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#valid_account_number_format?' do
    subject { iban.valid_account_number_format? }

    context 'DE non-numeric account number' do
      let(:arg) do
        {
          country_code: 'DE',
          bank_code: '12345678',
          account_number: '55779911AA'
        }
      end

      it { is_expected.to eq(false) }

      context 'locale en', locale: :en do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: 'is invalid')
        end
      end

      context 'locale fr', locale: :fr do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: 'est invalide')
        end
      end

      context 'locale de', locale: :de do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: 'ist nicht gültig')
        end
      end

      context 'locale pt', locale: :pt do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: 'é inválido')
        end
      end

      context 'locale es', locale: :es do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: 'es inválido')
        end
      end

      context 'locale it', locale: :it do
        it 'sets errors on the IBAN' do
          iban.valid_account_number_format?
          expect(iban.errors).to include(account_number: 'non è valido')
        end
      end
    end

    context 'with an invalid country code' do
      let(:iban_code) { 'AA821234BANK121234567B' }

      it { is_expected.to be_nil }
    end

    context 'with a wrong-length account number' do
      let(:arg) do
        {
          country_code: 'NL',
          bank_code: 'ABCD',
          account_number: nil
        }
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#valid_local_modulus_check?' do
    subject(:valid_local_modulus_check?) { iban.valid_local_modulus_check? }

    context 'without a modulus checker defined' do
      it { is_expected.to be(true) }
    end

    context 'with a modulus checker defined' do
      before do
        Ibandit.modulus_checker = double(
          valid_bank_code?: valid_bank_code,
          valid_account_number?: valid_account_number)
      end
      after { Ibandit.modulus_checker = nil }
      before { iban.valid_local_modulus_check? }

      context 'with an invalid bank code' do
        let(:iban_code) { 'AT611904300234573201' }
        let(:valid_bank_code) { false }
        let(:valid_account_number) { true }

        it { is_expected.to be(false) }
        context 'locale en', locale: :en do
          specify { expect(iban.errors).to include(bank_code: 'is invalid') }
        end

        context 'locale fr', locale: :fr do
          specify { expect(iban.errors).to include(bank_code: 'est invalide') }
        end

        context 'locale de', locale: :de do
          specify do
            expect(iban.errors).to include(bank_code: 'ist nicht gültig')
          end
        end

        context 'locale pt', locale: :pt do
          specify { expect(iban.errors).to include(bank_code: 'é inválido') }
        end

        context 'locale es', locale: :es do
          specify { expect(iban.errors).to include(bank_code: 'es inválido') }
        end

        context 'locale it', locale: :it do
          specify { expect(iban.errors).to include(bank_code: 'non è valido') }
        end

        context 'when the bank code is not required' do
          let(:iban_code) { 'GB60BARC20000055779911' }
          before { Ibandit.bic_finder = double(call: 'BARCGB22XXX') }
          after { Ibandit.bic_finder = nil }
          before { iban.valid_local_modulus_check? }

          it { is_expected.to be(false) }
          context 'locale en', locale: :en do
            specify do
              expect(iban.errors).to include(branch_code: 'is invalid')
            end
          end

          context 'locale fr', locale: :fr do
            specify do
              expect(iban.errors).to include(branch_code: 'est invalide')
            end
          end

          context 'locale de', locale: :de do
            specify do
              expect(iban.errors).to include(branch_code: 'ist nicht gültig')
            end
          end

          context 'locale pt', locale: :pt do
            specify do
              expect(iban.errors).to include(branch_code: 'é inválido')
            end
          end

          context 'locale es', locale: :es do
            specify do
              expect(iban.errors).to include(branch_code: 'es inválido')
            end
          end

          context 'locale it', locale: :it do
            specify do
              expect(iban.errors).to include(branch_code: 'non è valido')
            end
          end
        end
      end

      context 'with an invalid account number' do
        let(:valid_bank_code) { true }
        let(:valid_account_number) { false }

        it { is_expected.to be(false) }
        context 'locale en', locale: :en do
          specify do
            expect(iban.errors).to include(account_number: 'is invalid')
          end
        end

        context 'locale fr', locale: :fr do
          specify do
            expect(iban.errors).to include(account_number: 'est invalide')
          end
        end

        context 'locale de', locale: :de do
          specify do
            expect(iban.errors).to include(account_number: 'ist nicht gültig')
          end
        end

        context 'locale pt', locale: :pt do
          specify do
            expect(iban.errors).to include(account_number: 'é inválido')
          end
        end

        context 'locale es', locale: :es do
          specify do
            expect(iban.errors).to include(account_number: 'es inválido')
          end
        end

        context 'locale it', locale: :it do
          specify do
            expect(iban.errors).to include(account_number: 'non è valido')
          end
        end
      end
    end
  end

  describe '#valid?' do
    describe 'validations called' do
      after { iban.valid? }

      specify { expect(iban).to receive(:valid_country_code?).at_least(1) }
      specify { expect(iban).to receive(:valid_characters?).at_least(1) }
      specify { expect(iban).to receive(:valid_check_digits?).at_least(1) }
      specify { expect(iban).to receive(:valid_length?).at_least(1) }
      specify { expect(iban).to receive(:valid_bank_code_length?).at_least(1) }
      specify { expect(iban).to receive(:valid_format?).at_least(1) }
      specify { expect(iban).to receive(:valid_bank_code_format?).at_least(1) }

      it 'validates the branch code length' do
        expect(iban).to receive(:valid_branch_code_length?).at_least(1)
      end

      it 'validates the account number length' do
        expect(iban).to receive(:valid_account_number_length?).at_least(1)
      end

      it 'validates the branch code format' do
        expect(iban).to receive(:valid_branch_code_format?).at_least(1)
      end

      it 'validates the account number format' do
        expect(iban).to receive(:valid_account_number_format?).at_least(1)
      end

      it 'runs local modulus checks' do
        expect(iban).to receive(:valid_local_modulus_check?).at_least(1)
      end
    end

    context 'for a valid Albanian IBAN' do
      let(:iban_code) { 'AL47 2121 1009 0000 0002 3569 8741' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Andorran IBAN' do
      let(:iban_code) { 'AD12 0001 2030 2003 5910 0100' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Austrian IBAN' do
      let(:iban_code) { 'AT61 1904 3002 3457 3201' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Azerbaijanian IBAN' do
      let(:iban_code) { 'AZ21 NABZ 0000 0000 1370 1000 1944' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Bahrainian IBAN' do
      let(:iban_code) { 'BH67 BMAG 0000 1299 1234 56' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Belgian IBAN' do
      let(:iban_code) { 'BE62 5100 0754 7061' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Bosnian IBAN' do
      let(:iban_code) { 'BA39 1290 0794 0102 8494' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Bulgarian IBAN' do
      let(:iban_code) { 'BG80 BNBG 9661 1020 3456 78' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Croatian IBAN' do
      let(:iban_code) { 'HR12 1001 0051 8630 0016 0' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Cypriot IBAN' do
      let(:iban_code) { 'CY17 0020 0128 0000 0012 0052 7600' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Czech IBAN' do
      let(:iban_code) { 'CZ65 0800 0000 1920 0014 5399' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Danish IBAN' do
      let(:iban_code) { 'DK50 0040 0440 1162 43' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Estonian IBAN' do
      let(:iban_code) { 'EE38 2200 2210 2014 5685' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Faroe Islands IBAN' do
      let(:iban_code) { 'FO97 5432 0388 8999 44' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Finnish IBAN' do
      let(:iban_code) { 'FI21 1234 5600 0007 85' }
      it { is_expected.to be_valid }
    end

    context 'for a valid French IBAN' do
      let(:iban_code) { 'FR14 2004 1010 0505 0001 3M02 606' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Georgian IBAN' do
      let(:iban_code) { 'GE29 NB00 0000 0101 9049 17' }
      it { is_expected.to be_valid }
    end

    context 'for a valid German IBAN' do
      let(:iban_code) { 'DE89 3704 0044 0532 0130 00' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Gibraltan IBAN' do
      let(:iban_code) { 'GI75 NWBK 0000 0000 7099 453' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Greek IBAN' do
      let(:iban_code) { 'GR16 0110 1250 0000 0001 2300 695' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Greenland IBAN' do
      let(:iban_code) { 'GL56 0444 9876 5432 10' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Hungarian IBAN' do
      let(:iban_code) { 'HU42 1177 3016 1111 1018 0000 0000' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Icelandic IBAN' do
      let(:iban_code) { 'IS14 0159 2600 7654 5510 7303 39' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Irish IBAN' do
      let(:iban_code) { 'IE29 AIBK 9311 5212 3456 78' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Israeli IBAN' do
      let(:iban_code) { 'IL62 0108 0000 0009 9999 999' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Italian IBAN' do
      let(:iban_code) { 'IT40 S054 2811 1010 0000 0123 456' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Jordanian IBAN' do
      let(:iban_code) { 'JO94 CBJO 0010 0000 0000 0131 0003 02' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Kuwaiti IBAN' do
      let(:iban_code) { 'KW81 CBKU 0000 0000 0000 1234 5601 01' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Latvian IBAN' do
      let(:iban_code) { 'LV80 BANK 0000 4351 9500 1' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Lebanese IBAN' do
      let(:iban_code) { 'LB62 0999 0000 0001 0019 0122 9114' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Liechtensteinian IBAN' do
      let(:iban_code) { 'LI21 0881 0000 2324 013A A' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Lithuanian IBAN' do
      let(:iban_code) { 'LT12 1000 0111 0100 1000' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Luxembourgian IBAN' do
      let(:iban_code) { 'LU28 0019 4006 4475 0000' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Macedonian IBAN' do
      let(:iban_code) { 'MK072 5012 0000 0589 84' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Maltese IBAN' do
      let(:iban_code) { 'MT84 MALT 0110 0001 2345 MTLC AST0 01S' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Maurititanian IBAN' do
      let(:iban_code) { 'MU17 BOMM 0101 1010 3030 0200 000M UR' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Moldovan IBAN' do
      let(:iban_code) { 'MD24 AG00 0225 1000 1310 4168' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Monocan IBAN' do
      let(:iban_code) { 'MC93 2005 2222 1001 1223 3M44 555' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Montenegrian IBAN' do
      let(:iban_code) { 'ME25 5050 0001 2345 6789 51' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Dutch IBAN' do
      let(:iban_code) { 'NL39 RABO 0300 0652 64' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Norwegian IBAN' do
      let(:iban_code) { 'NO93 8601 1117 947' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Pakistani IBAN' do
      let(:iban_code) { 'PK36 SCBL 0000 0011 2345 6702' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Polish IBAN' do
      let(:iban_code) { 'PL60 1020 1026 0000 0422 7020 1111' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Potuguese IBAN' do
      let(:iban_code) { 'PT50 0002 0123 1234 5678 9015 4' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Qatari IBAN' do
      let(:iban_code) { 'QA58 DOHB 0000 1234 5678 90AB CDEF G' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Romanian IBAN' do
      let(:iban_code) { 'RO49 AAAA 1B31 0075 9384 0000' }
      it { is_expected.to be_valid }
    end

    context 'for a valid San Marinian IBAN' do
      let(:iban_code) { 'SM86 U032 2509 8000 0000 0270 100' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Saudi IBAN' do
      let(:iban_code) { 'SA03 8000 0000 6080 1016 7519' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Serbian IBAN' do
      let(:iban_code) { 'RS35 2600 0560 1001 6113 79' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Slovakian IBAN' do
      let(:iban_code) { 'SK31 1200 0000 1987 4263 7541' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Slovenian IBAN' do
      let(:iban_code) { 'SI56 1910 0000 0123 438' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Spanish IBAN' do
      let(:iban_code) { 'ES80 2310 0001 1800 0001 2345' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Swedish IBAN' do
      let(:iban_code) { 'SE35 5000 0000 0549 1000 0003' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Swiss IBAN' do
      let(:iban_code) { 'CH93 0076 2011 6238 5295 7' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Tunisian IBAN' do
      let(:iban_code) { 'TN59 1000 6035 1835 9847 8831' }
      it { is_expected.to be_valid }
    end

    context 'for a valid Turkish IBAN' do
      let(:iban_code) { 'TR33 0006 1005 1978 6457 8413 26' }
      it { is_expected.to be_valid }
    end

    context 'for a valid UAE IBAN' do
      let(:iban_code) { 'AE07 0331 2345 6789 0123 456' }
      it { is_expected.to be_valid }
    end

    context 'for a valid UK IBAN' do
      let(:iban_code) { 'GB82 WEST 1234 5698 7654 32' }
      it { is_expected.to be_valid }
    end
  end

  describe '#local_check_digits' do
    context 'with a Belgian IBAN' do
      let(:iban_code) { 'BE62510007547061' }
      its(:local_check_digits) { is_expected.to eq('61') }
    end

    context 'with a French IBAN' do
      let(:iban_code) { 'FR1234567890123456789012345' }
      its(:local_check_digits) { is_expected.to eq('45') }
    end

    context 'with a Monocan IBAN' do
      let(:iban_code) { 'MC9320052222100112233M44555' }
      its(:local_check_digits) { is_expected.to eq('55') }
    end

    context 'with a Spanish IBAN' do
      let(:iban_code) { 'ES1212345678911234567890' }
      its(:local_check_digits) { is_expected.to eq('91') }
    end

    context 'with an Italian IBAN' do
      let(:iban_code) { 'IT12A1234567890123456789012' }
      its(:local_check_digits) { is_expected.to eq('A') }
    end

    context 'with an Estonian IBAN' do
      let(:iban_code) { 'EE382200221020145685' }
      its(:local_check_digits) { is_expected.to eq('5') }
    end

    context 'with an Finnish IBAN' do
      let(:iban_code) { 'FI2112345600000785' }
      its(:local_check_digits) { is_expected.to eq('5') }
    end

    context 'with an Portuguese IBAN' do
      let(:iban_code) { 'PT50000201231234567890154' }
      its(:local_check_digits) { is_expected.to eq('54') }
    end

    context 'with a Slovakian IBAN' do
      let(:iban_code) { 'SK3112000000198742637541' }
      its(:local_check_digits) { is_expected.to eq('9') }
    end

    context 'with a Dutch IBAN' do
      let(:iban_code) { 'NL91ABNA0417164300' }
      its(:local_check_digits) { is_expected.to eq('0') }
    end
  end
end
