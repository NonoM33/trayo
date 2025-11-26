require 'rails_helper'

RSpec.describe CommissionReminderDispatchJob, type: :job do
  let(:user) do
    u = create(:user, phone: "+33776695886")
    create(:mt5_account, user: u, balance: 5000.0, high_watermark: 4000.0)
    u
  end
  let(:job) { described_class.new }

  before do
    # Mock SmsGateway
    allow(SmsGateway).to receive(:send_message).and_return({
      status: 200,
      body: '{"id": "test-id", "status": "sent"}'
    })
  end

  describe "#perform" do
    context "avec un rappel initial" do
      it "envoie le SMS et planifie les follow-ups" do
        deadline = 48.hours.from_now

        expect(CommissionReminderSender).to receive(:new).with(user).and_call_original
        expect(CommissionReminderDispatchJob).to receive(:set).with(wait: 24.hours).and_call_original
        expect(CommissionReminderDispatchJob).to receive(:set).with(wait: be_within(1.second).of(deadline - 2.hours - Time.current)).and_call_original

        job.perform(user.id, kind: "initial", deadline: deadline, schedule_followups: true)

        expect(CommissionReminder.count).to eq(1)
        expect(CommissionReminder.first.kind).to eq("initial")
      end

      it "planifie le rappel 24h avant la deadline" do
        deadline = 48.hours.from_now
        mock_set = double("ActiveJob::ConfiguredJob")
        allow(CommissionReminderDispatchJob).to receive(:set).and_return(mock_set)
        allow(mock_set).to receive(:perform_later)

        job.perform(user.id, kind: "initial", deadline: deadline, schedule_followups: true)

        expect(CommissionReminderDispatchJob).to have_received(:set).with(wait: 24.hours)
        expect(mock_set).to have_received(:perform_later).with(
          user.id,
          hash_including(kind: "follow_up_24h", schedule_followups: false)
        )
      end

      it "planifie le rappel 2h avant la deadline" do
        deadline = 48.hours.from_now
        mock_set = double("ActiveJob::ConfiguredJob")
        allow(CommissionReminderDispatchJob).to receive(:set).and_return(mock_set)
        allow(mock_set).to receive(:perform_later)

        job.perform(user.id, kind: "initial", deadline: deadline, schedule_followups: true)

        expect(mock_set).to have_received(:perform_later).with(
          user.id,
          hash_including(kind: "follow_up_2h", schedule_followups: false)
        )
      end

      it "ne planifie pas le rappel 2h si le deadline est trop proche" do
        deadline = 1.hour.from_now
        mock_set = double("ActiveJob::ConfiguredJob")
        allow(CommissionReminderDispatchJob).to receive(:set).and_return(mock_set)
        allow(mock_set).to receive(:perform_later)

        job.perform(user.id, kind: "initial", deadline: deadline, schedule_followups: true)

        # Doit planifier le 24h
        expect(mock_set).to have_received(:perform_later).with(
          user.id,
          hash_including(kind: "follow_up_24h")
        )

        # Ne doit pas planifier le 2h car trop proche (deadline dans 1h, donc final_time serait dans le passé)
        expect(mock_set).not_to have_received(:perform_later).with(
          user.id,
          hash_including(kind: "follow_up_2h")
        )
      end
    end

    context "avec un rappel follow-up" do
      it "envoie le SMS mais ne planifie pas de nouveaux follow-ups" do
        deadline = 48.hours.from_now
        allow(CommissionReminderDispatchJob).to receive(:perform_later)

        job.perform(user.id, kind: "follow_up_24h", deadline: deadline, schedule_followups: false)

        expect(CommissionReminder.count).to eq(1)
        expect(CommissionReminder.first.kind).to eq("follow_up_24h")
        expect(CommissionReminderDispatchJob).not_to have_received(:perform_later)
      end

      it "envoie le SMS de rappel 2h avec le message d'avertissement" do
        deadline = 2.hours.from_now

        job.perform(user.id, kind: "follow_up_2h", deadline: deadline, schedule_followups: false)

        reminder = CommissionReminder.first
        expect(reminder.kind).to eq("follow_up_2h")
        expect(reminder.message_content).to include("URGENT")
        expect(reminder.message_content).to include("bots de trading seront AUTOMATIQUEMENT COUPÉS")
        expect(reminder.message_content).to include("DANGER RÉEL")
      end
    end

    context "avec un rappel follow_up_28d" do
      it "envoie le SMS avec force: true" do
        deadline = 48.hours.from_now

        job.perform(user.id, kind: "follow_up_28d", deadline: deadline, force: true, schedule_followups: false)

        expect(CommissionReminder.count).to eq(1)
        expect(CommissionReminder.first.kind).to eq("follow_up_28d")
      end
    end

    context "quand l'utilisateur n'existe pas" do
      it "ne fait rien" do
        expect {
          job.perform(99999, kind: "initial")
        }.not_to change { CommissionReminder.count }
      end
    end

    context "quand l'envoi échoue" do
      before do
        allow(SmsGateway).to receive(:send_message).and_return({
          status: 400,
          body: '{"message": "error"}'
        })
      end

      it "ne planifie pas de follow-ups" do
        deadline = 48.hours.from_now
        allow(CommissionReminderDispatchJob).to receive(:perform_later)

        job.perform(user.id, kind: "initial", deadline: deadline, schedule_followups: true)

        expect(CommissionReminderDispatchJob).not_to have_received(:perform_later)
      end
    end
  end
end

