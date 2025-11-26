require 'rails_helper'

RSpec.describe CommissionReminderSender, type: :service do
  let(:user) { create(:user, phone: "0776695886", first_name: "Test", last_name: "User") }
  let(:sender) { described_class.new(user) }

  before do
    # Mock SmsGateway pour ne pas envoyer de vrais SMS
    allow(SmsGateway).to receive(:send_message).and_return({
      status: 200,
      body: '{"id": "test-id-123", "status": "sent"}'
    })
  end

  describe "#call" do
    context "avec un numéro de téléphone valide" do
      before do
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
      end

      it "crée un rappel avec le statut 'sent' quand l'API répond 200" do
        result = sender.call(kind: "initial")

        expect(result.success?).to be true
        expect(result.reminder).to be_persisted
        expect(result.reminder.status).to eq("sent")
        expect(result.reminder.kind).to eq("initial")
        expect(result.reminder.phone_number).to eq("+33776695886")
        expect(result.reminder.message_content).to be_present
      end

      it "normalise le numéro de téléphone français" do
        user.update(phone: "0776695886")
        result = sender.call(kind: "initial")

        expect(result.reminder.phone_number).to eq("+33776695886")
      end

      it "normalise un numéro déjà au format international" do
        user.update(phone: "+33776695886")
        result = sender.call(kind: "initial")

        expect(result.reminder.phone_number).to eq("+33776695886")
      end

      it "normalise un numéro commençant par 33" do
        user.update(phone: "33776695886")
        result = sender.call(kind: "initial")

        expect(result.reminder.phone_number).to eq("+33776695886")
      end

      it "marque le rappel comme 'failed' quand l'API répond avec une erreur" do
        allow(SmsGateway).to receive(:send_message).and_return({
          status: 400,
          body: '{"message": "invalid phone number"}'
        })

        result = sender.call(kind: "initial")

        expect(result.success?).to be true # Le service retourne success même si l'API échoue
        expect(result.reminder.status).to eq("failed")
      end

      it "enregistre l'external_id de l'API" do
        allow(SmsGateway).to receive(:send_message).and_return({
          status: 200,
          body: '{"id": "external-123", "status": "sent"}'
        })

        result = sender.call(kind: "initial")

        expect(result.reminder.external_id).to eq("external-123")
      end

      it "enregistre le message_content complet" do
        result = sender.call(kind: "initial")

        expect(result.reminder.message_content).to include("Bonjour Test")
        expect(result.reminder.message_content).to include("€")
        expect(result.reminder.message_content).to include("https://revolut.me/renaudcosson")
        expect(result.reminder.message_content).to include("REF")
      end
    end

    context "sans numéro de téléphone" do
      let(:user_without_phone) do
        u = create(:user, first_name: "Test", last_name: "User")
        u.update_column(:phone, nil)
        u
      end
      let(:sender_no_phone) { described_class.new(user_without_phone.reload) }

      before do
        create(:mt5_account, user: user_without_phone, balance: 5000.0, high_watermark: 4000.0)
      end

      it "lève une erreur" do
        expect(user_without_phone.reload.phone).to be_nil
        result = sender_no_phone.call(kind: "initial")
        expect(result.success?).to be false
        expect(result.message).to eq("Aucun numéro renseigné")
      end
    end

    context "sans commission due" do
      let(:user_no_commission) do
        u = create(:user, phone: "+33776695886", first_name: "Test", last_name: "User")
        u.update_column(:commission_rate, 0)
        u
      end
      let(:sender_no_commission) { described_class.new(user_no_commission.reload) }

      before do
        create(:mt5_account, user: user_no_commission, balance: 1000.0, high_watermark: 1000.0, initial_balance: 1000.0)
      end

      it "lève une erreur sans force" do
        expect(user_no_commission.reload.total_commission_due).to eq(0)
        result = sender_no_commission.call(kind: "initial", force: false)
        expect(result.success?).to be false
        expect(result.message).to eq("Aucune commission due")
      end

      it "permet l'envoi avec force: true" do
        result = sender_no_commission.call(kind: "initial", force: true)

        expect(result.success?).to be true
      end
    end

    context "avec différents types de rappels" do
      before do
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
      end

      it "génère le bon message pour 'initial'" do
        result = sender.call(kind: "initial")

        expect(result.reminder.message_content).to include("Merci de bien vouloir régler sous 48h")
      end

      it "génère le bon message pour 'follow_up_24h'" do
        result = sender.call(kind: "follow_up_24h")

        expect(result.reminder.message_content).to include("Il reste 24h pour régulariser")
      end

      it "génère le bon message pour 'follow_up_2h' avec avertissement bots" do
        result = sender.call(kind: "follow_up_2h")

        expect(result.reminder.message_content).to include("URGENT")
        expect(result.reminder.message_content).to include("bots de trading seront AUTOMATIQUEMENT COUPÉS")
        expect(result.reminder.message_content).to include("DANGER RÉEL")
        expect(result.reminder.message_content).to include("trades en cours ne seront PLUS contrôlés")
      end

      it "génère le bon message pour 'follow_up_28d'" do
        result = sender.call(kind: "follow_up_28d")

        expect(result.reminder.message_content).to include("Rappel important")
      end

      it "génère le bon message pour 'manual'" do
        result = sender.call(kind: "manual", force: true)

        expect(result.reminder.message_content).to include("Merci de bien vouloir régler sous 48h")
      end
    end

    context "avec un deadline personnalisé" do
      before do
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
      end

      it "utilise le deadline fourni" do
        custom_deadline = 72.hours.from_now
        result = sender.call(kind: "initial", deadline: custom_deadline)

        expect(result.reminder.deadline_at).to be_within(1.second).of(custom_deadline)
        expect(result.reminder.message_content).to include(custom_deadline.strftime("%d/%m/%Y %H:%M"))
      end

      it "utilise un deadline par défaut de 48h si non fourni" do
        result = sender.call(kind: "initial")

        expect(result.reminder.deadline_at).to be_within(1.minute).of(48.hours.from_now)
      end
    end

    context "gestion des erreurs" do
      before do
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
      end

      it "gère les erreurs de l'API SMS" do
        allow(SmsGateway).to receive(:send_message).and_raise(StandardError.new("API Error"))

        result = sender.call(kind: "initial")

        expect(result.success?).to be false
        expect(result.reminder.status).to eq("failed")
        expect(result.reminder.error_message).to eq("API Error")
      end

      it "gère les réponses JSON invalides" do
        allow(SmsGateway).to receive(:send_message).and_return({
          status: 200,
          body: "invalid json"
        })

        result = sender.call(kind: "initial")

        expect(result.success?).to be true
        expect(result.reminder.status).to eq("sent")
        expect(result.reminder.external_id).to be_nil
      end
    end
  end

  describe "#preview" do
    before do
      create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
    end

    it "retourne une prévisualisation sans envoyer de SMS" do
      result = sender.preview(kind: "initial")

      expect(result.success?).to be true
      expect(result.data).to be_present
      expect(result.data[:text]).to include("Bonjour Test")
      expect(CommissionReminder.count).to eq(0) # Aucun rappel créé
    end

    it "lève une erreur si pas de numéro" do
      user_without_phone = create(:user, first_name: "Test2", last_name: "User2")
      user_without_phone.update_column(:phone, nil)
      create(:mt5_account, user: user_without_phone, balance: 5000.0, high_watermark: 4000.0)
      sender_no_phone = described_class.new(user_without_phone.reload)
      
      expect(user_without_phone.reload.phone).to be_nil
      result = sender_no_phone.preview(kind: "initial")
      expect(result.success?).to be false
      expect(result.message).to eq("Aucun numéro renseigné")
    end

    it "lève une erreur si pas de commission due" do
      user_no_commission = create(:user, phone: "+33776695886", first_name: "Test3", last_name: "User3")
      user_no_commission.update_column(:commission_rate, 0)
      create(:mt5_account, user: user_no_commission, balance: 1000.0, high_watermark: 1000.0, initial_balance: 1000.0)
      sender_no_commission = described_class.new(user_no_commission.reload)

      expect(user_no_commission.reload.total_commission_due).to eq(0)
      result = sender_no_commission.preview(kind: "initial")
      expect(result.success?).to be false
      expect(result.message).to eq("Aucune commission due")
    end
  end
end

