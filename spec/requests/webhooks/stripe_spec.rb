require 'rails_helper'

RSpec.describe "Webhooks::Stripe", type: :request do
  let!(:user) { create(:user, stripe_customer_id: 'cus_test_123') }
  let!(:invitation) { create(:invitation, email: user.email, stripe_payment_intent_id: 'pi_test_123') }
  let!(:trading_bot) { create(:trading_bot, price: 399.99) }
  let!(:invoice) do
    invoice = user.invoices.create!(
      reference: "INV-TEST-001",
      status: "pending",
      total_amount: 799.98,
      balance_due: 799.98,
      stripe_payment_intent_id: 'pi_test_123'
    )
    invoice.add_item(label: "Bot Test", unit_price: 399.99, quantity: 1)
    invoice.add_item(label: "VPS", unit_price: 399.99, quantity: 1)
    invoice
  end

  before do
    allow(Stripe::Webhook).to receive(:construct_event) do |payload, _sig, _secret|
      Stripe::Event.construct_from(JSON.parse(payload, symbolize_names: true))
    end
  end

  def stripe_webhook_headers
    { "CONTENT_TYPE" => "application/json", "HTTP_STRIPE_SIGNATURE" => "test_signature" }
  end

  describe "POST /webhooks/stripe" do
    context "with payment_intent.succeeded event" do
      let(:payload) do
        {
          id: "evt_test_123",
          type: "payment_intent.succeeded",
          data: {
            object: {
              id: "pi_test_123",
              amount: 79998,
              currency: "eur",
              status: "succeeded",
              customer: "cus_test_123",
              latest_charge: "ch_test_123",
              metadata: { invitation_code: invitation.code }
            }
          }
        }.to_json
      end

      it "updates invoice status to paid" do
        post "/webhooks/stripe", params: payload, headers: stripe_webhook_headers
        
        expect(response).to be_successful
        
        invoice.reload
        expect(invoice.status).to eq("paid")
        expect(invoice.balance_due).to eq(0)
      end

      it "creates a payment record" do
        expect {
          post "/webhooks/stripe", params: payload, headers: stripe_webhook_headers
        }.to change { invoice.invoice_payments.count }.by(1)
        
        payment = invoice.invoice_payments.last
        expect(payment.amount).to eq(799.98)
        expect(payment.payment_method).to eq("stripe")
      end

      it "updates invitation payment status" do
        post "/webhooks/stripe", params: payload, headers: stripe_webhook_headers
        
        invitation.reload
        broker_data = JSON.parse(invitation.broker_data || "{}")
        expect(broker_data["payment_status"]).to eq("succeeded")
      end
    end

    context "with payment_intent.payment_failed event" do
      let(:payload) do
        {
          id: "evt_test_failed",
          type: "payment_intent.payment_failed",
          data: {
            object: {
              id: "pi_test_123",
              amount: 79998,
              status: "failed",
              metadata: { invitation_code: invitation.code },
              last_payment_error: {
                message: "Your card was declined"
              }
            }
          }
        }.to_json
      end

      it "updates invitation with failure info" do
        post "/webhooks/stripe", params: payload, headers: stripe_webhook_headers
        
        expect(response).to be_successful
        
        invitation.reload
        broker_data = JSON.parse(invitation.broker_data || "{}")
        expect(broker_data["payment_status"]).to eq("failed")
      end
    end

    context "with customer.subscription.updated event" do
      let!(:subscription) do
        user.subscriptions.create!(
          stripe_subscription_id: "sub_test_123",
          stripe_customer_id: "cus_test_123",
          plan: "pro",
          status: "active",
          monthly_price: 149.99,
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end

      let(:payload) do
        {
          id: "evt_sub_updated",
          type: "customer.subscription.updated",
          data: {
            object: {
              id: "sub_test_123",
              status: "past_due",
              current_period_start: Time.current.to_i,
              current_period_end: 1.month.from_now.to_i,
              cancel_at_period_end: false
            }
          }
        }.to_json
      end

      it "updates subscription status" do
        post "/webhooks/stripe", params: payload, headers: stripe_webhook_headers
        
        expect(response).to be_successful
        
        subscription.reload
        expect(subscription.status).to eq("past_due")
      end
    end

    context "with invoice.paid event for subscription" do
      let!(:subscription) do
        user.subscriptions.create!(
          stripe_subscription_id: "sub_test_123",
          stripe_customer_id: "cus_test_123",
          plan: "pro",
          status: "past_due",
          monthly_price: 149.99,
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end

      let!(:bot_purchase) do
        user.bot_purchases.create!(
          trading_bot: trading_bot,
          price_paid: 0,
          status: "inactive",
          purchase_type: "subscription_pro",
          billing_status: "pending"
        )
      end

      let(:payload) do
        {
          id: "evt_invoice_paid",
          type: "invoice.paid",
          data: {
            object: {
              id: "in_test_123",
              subscription: "sub_test_123",
              lines: {
                data: [{ period: { end: 1.month.from_now.to_i } }]
              }
            }
          }
        }.to_json
      end

      it "reactivates subscription and bots" do
        post "/webhooks/stripe", params: payload, headers: stripe_webhook_headers
        
        expect(response).to be_successful
        
        subscription.reload
        expect(subscription.status).to eq("active")
        
        bot_purchase.reload
        expect(bot_purchase.status).to eq("active")
        expect(bot_purchase.billing_status).to eq("paid")
      end
    end

    context "with invalid signature" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(Stripe::SignatureVerificationError.new("Invalid", "sig"))
      end

      it "returns bad request" do
        post "/webhooks/stripe", params: "{}", headers: stripe_webhook_headers
        
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with unknown event type" do
      let(:payload) do
        {
          id: "evt_unknown",
          type: "unknown.event",
          data: { object: {} }
        }.to_json
      end

      it "returns success" do
        post "/webhooks/stripe", params: payload, headers: stripe_webhook_headers
        
        expect(response).to be_successful
      end
    end
  end
end
