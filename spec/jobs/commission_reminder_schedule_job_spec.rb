require 'rails_helper'

RSpec.describe CommissionReminderScheduleJob, type: :job do
  describe "#perform" do
    let(:job) { described_class.new }

    context "le 14 du mois - envoi initial" do
      let(:date_14) { Time.zone.parse("2025-11-14 09:00") }
      
      let!(:client_with_phone_and_commission) do
        user = create(:user, phone: "+33776695886", is_admin: false)
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
        user
      end

      let!(:client_without_phone) do
        user = create(:user, phone: nil, is_admin: false)
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
        user
      end

      let!(:client_without_commission) do
        user = create(:user, phone: "+33776695887", is_admin: false)
        create(:mt5_account, user: user, balance: 1000.0, high_watermark: 1000.0)
        user
      end

      let!(:admin_user) do
        user = create(:user, :admin, phone: "+33776695888")
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
        user
      end

      before do
        allow(CommissionReminderDispatchJob).to receive(:perform_later)
      end

      it "envoie des SMS uniquement aux clients avec téléphone et commission due" do
        job.perform(date_14)

        expect(CommissionReminderDispatchJob).to have_received(:perform_later).with(
          client_with_phone_and_commission.id,
          hash_including(kind: "initial")
        ).once

        expect(CommissionReminderDispatchJob).not_to have_received(:perform_later).with(
          client_without_phone.id,
          anything
        )

        expect(CommissionReminderDispatchJob).not_to have_received(:perform_later).with(
          client_without_commission.id,
          anything
        )

        expect(CommissionReminderDispatchJob).not_to have_received(:perform_later).with(
          admin_user.id,
          anything
        )
      end
    end

    context "le 28 du mois - relances" do
      let(:date_28) { Time.zone.parse("2025-11-28 09:00") }
      let(:month_start) { date_28.beginning_of_month }
      
      let!(:client_with_initial_reminder) do
        user = create(:user, phone: "+33776695886", is_admin: false)
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
        create(:commission_reminder, :initial, status: "sent", user: user, created_at: month_start + 13.days)
        user
      end

      let!(:client_without_initial_reminder) do
        user = create(:user, phone: "+33776695887", is_admin: false)
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
        user
      end

      let!(:client_commission_paid) do
        user = create(:user, phone: "+33776695888", is_admin: false)
        create(:mt5_account, user: user, balance: 1000.0, high_watermark: 1000.0)
        create(:commission_reminder, :initial, status: "sent", user: user, created_at: month_start + 13.days)
        user
      end

      let!(:client_initial_reminder_failed) do
        user = create(:user, phone: "+33776695889", is_admin: false)
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
        create(:commission_reminder, :initial, status: "failed", user: user, created_at: month_start + 13.days)
        user
      end

      let!(:client_initial_reminder_old_month) do
        user = create(:user, phone: "+33776695890", is_admin: false)
        create(:mt5_account, user: user, balance: 5000.0, high_watermark: 4000.0)
        create(:commission_reminder, :initial, status: "sent", user: user, created_at: 2.months.ago)
        user
      end

      before do
        allow(CommissionReminderDispatchJob).to receive(:perform_later)
      end

      it "envoie des relances uniquement aux clients avec rappel initial du mois et commission toujours due" do
        job.perform(date_28)

        expect(CommissionReminderDispatchJob).to have_received(:perform_later).with(
          client_with_initial_reminder.id,
          hash_including(kind: "follow_up_28d", force: true, schedule_followups: false)
        ).once

        expect(CommissionReminderDispatchJob).not_to have_received(:perform_later).with(
          client_without_initial_reminder.id,
          anything
        )

        expect(CommissionReminderDispatchJob).not_to have_received(:perform_later).with(
          client_commission_paid.id,
          anything
        )

        expect(CommissionReminderDispatchJob).not_to have_received(:perform_later).with(
          client_initial_reminder_failed.id,
          anything
        )

        expect(CommissionReminderDispatchJob).not_to have_received(:perform_later).with(
          client_initial_reminder_old_month.id,
          anything
        )
      end
    end

    context "autres jours du mois" do
      it "ne fait rien les autres jours" do
        date_15 = Time.zone.parse("2025-11-15 09:00")
        allow(CommissionReminderDispatchJob).to receive(:perform_later)

        job.perform(date_15)

        expect(CommissionReminderDispatchJob).not_to have_received(:perform_later)
      end
    end
  end
end

