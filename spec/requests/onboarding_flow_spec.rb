require 'rails_helper'

RSpec.describe "Onboarding Flow", type: :request do
  let!(:trading_bot_gbp) { create(:trading_bot, name: "GBPUSD Bot", price: 399.99, symbol: "GBPUSD") }
  let!(:trading_bot_gold) { create(:trading_bot, name: "Or XAU", price: 399.99, symbol: "XAUUSD") }
  let!(:trading_bot_btc) { create(:trading_bot, name: "BTC Bot", price: 499.99, symbol: "BTCUSD") }

  describe "Complete onboarding flow with licence" do
    let(:invitation) { create(:invitation) }

    it "completes full flow successfully" do
      # Step 1: Access onboarding page
      get onboarding_path(code: invitation.code)
      expect(response).to be_successful

      # Step 2: Create payment intent
      allow(Stripe::PaymentIntent).to receive(:create).and_return(
        double(client_secret: "pi_test_secret")
      )

      post onboarding_payment_intent_path(code: invitation.code),
           params: {
             offer_type: "licence",
             selected_bots: [trading_bot_gbp.id, trading_bot_gold.id]
           },
           as: :json

      expect(response).to be_successful
      expect(JSON.parse(response.body)["clientSecret"]).to eq("pi_test_secret")

      # Step 3: Complete registration
      post onboarding_next_step_path(code: invitation.code),
           params: {
             first_name: "Jean",
             last_name: "Test",
             email: invitation.email,
             phone: "+33600000000",
             broker_name: "IC Markets",
             account_id: "12345678",
             account_password: "mypassword",
             offer_type: "licence",
             selected_bots: [trading_bot_gbp.id.to_s, trading_bot_gold.id.to_s]
           }

      expect(response).to redirect_to(onboarding_complete_path(code: invitation.code))

      # Verify user was created
      user = User.find_by(email: invitation.email)
      expect(user).to be_present
      expect(user.first_name).to eq("Jean")
      expect(user.last_name).to eq("Test")

      # Verify MT5 account
      expect(user.mt5_accounts.count).to eq(1)
      mt5 = user.mt5_accounts.first
      expect(mt5.broker_name).to eq("IC Markets")
      expect(mt5.broker_password).to eq("mypassword")

      # Verify VPS
      expect(user.vps.count).to eq(1)
      vps = user.vps.first
      expect(vps.status).to eq("ordered")
      expect(vps.monthly_price).to eq(399.99)

      # Verify bot purchases
      expect(user.bot_purchases.count).to eq(2)
      expect(user.bot_purchases.pluck(:trading_bot_id)).to match_array([trading_bot_gbp.id, trading_bot_gold.id])
      expect(user.bot_purchases.all? { |bp| !bp.is_running }).to be true

      # Verify invoice
      expect(user.invoices.count).to eq(1)

      # Verify invitation is completed
      invitation.reload
      expect(invitation.status).to eq("completed")

      # Step 4: Access complete page
      get onboarding_complete_path(code: invitation.code)
      expect(response).to be_successful
    end
  end

  describe "Complete onboarding flow with subscription" do
    let(:invitation) { create(:invitation) }

    it "completes flow with pro subscription" do
      # Create payment intent for subscription
      allow(Stripe::PaymentIntent).to receive(:create).and_return(
        double(client_secret: "pi_subscription_secret")
      )

      post onboarding_payment_intent_path(code: invitation.code),
           params: {
             offer_type: "subscription",
             subscription_plan: "pro"
           },
           as: :json

      expect(response).to be_successful
      
      # Verify amount is 149.99€
      expect(Stripe::PaymentIntent).to have_received(:create).with(
        hash_including(amount: 14999)
      )

      # Complete registration
      post onboarding_next_step_path(code: invitation.code),
           params: {
             first_name: "Marie",
             last_name: "Sub",
             email: invitation.email,
             phone: "+33611111111",
             broker_name: "Fusion Markets",
             account_id: "99999999",
             account_password: "subpass",
             offer_type: "subscription",
             subscription_plan: "pro"
           }

      expect(response).to redirect_to(onboarding_complete_path(code: invitation.code))

      user = User.find_by(email: invitation.email)
      expect(user).to be_present
      expect(user.bot_purchases.count).to be >= 1
      expect(user.vps.count).to eq(1)
    end

    it "completes flow with starter subscription" do
      allow(Stripe::PaymentIntent).to receive(:create).and_return(
        double(client_secret: "pi_starter_secret")
      )

      post onboarding_payment_intent_path(code: invitation.code),
           params: { offer_type: "subscription", subscription_plan: "starter" },
           as: :json

      expect(Stripe::PaymentIntent).to have_received(:create).with(
        hash_including(amount: 9900) # 99€
      )
    end

    it "completes flow with premium subscription" do
      allow(Stripe::PaymentIntent).to receive(:create).and_return(
        double(client_secret: "pi_premium_secret")
      )

      post onboarding_payment_intent_path(code: invitation.code),
           params: { offer_type: "subscription", subscription_plan: "premium" },
           as: :json

      expect(Stripe::PaymentIntent).to have_received(:create).with(
        hash_including(amount: 29999) # 299.99€
      )
    end
  end

  describe "Error handling" do
    let(:invitation) { create(:invitation) }

    context "with Stripe payment failure" do
      before do
        allow(Stripe::PaymentIntent).to receive(:create).and_raise(
          Stripe::CardError.new("Your card was declined", "card_declined", code: "card_declined")
        )
      end

      it "returns error and allows retry" do
        post onboarding_payment_intent_path(code: invitation.code),
             params: { offer_type: "licence", selected_bots: [trading_bot_gbp.id] },
             as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)["error"]).to include("declined")

        # User should not be created yet
        expect(User.find_by(email: invitation.email)).to be_nil
      end
    end

    context "with invalid invitation" do
      it "rejects access to onboarding" do
        get onboarding_path(code: "FAKE_CODE")
        expect(response).to redirect_to(root_path)
      end

      it "rejects payment intent creation" do
        post onboarding_payment_intent_path(code: "FAKE_CODE"),
             params: { offer_type: "licence" },
             as: :json

        expect(response).to redirect_to(root_path)
      end
    end

    context "with expired invitation" do
      let(:expired_invitation) { create(:invitation, :expired) }

      it "rejects access" do
        get onboarding_path(code: expired_invitation.code)
        expect(response).to redirect_to(root_path)
      end
    end

    context "with already completed invitation" do
      let(:completed_invitation) { create(:invitation, :completed) }

      it "rejects new registration" do
        get onboarding_path(code: completed_invitation.code)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "Data integrity" do
    let(:invitation) { create(:invitation) }

    it "generates unique MT5 IDs when duplicates exist" do
      # Create existing MT5 account with same ID
      existing_user = create(:user)
      create(:mt5_account, user: existing_user, mt5_id: "DUPLICATE123")

      allow(Stripe::PaymentIntent).to receive(:create).and_return(
        double(client_secret: "pi_test")
      )

      post onboarding_next_step_path(code: invitation.code),
           params: {
             first_name: "New",
             last_name: "User",
             email: invitation.email,
             phone: "+33600000000",
             broker_name: "IC Markets",
             account_id: "DUPLICATE123",
             account_password: "pass",
             offer_type: "licence",
             selected_bots: [trading_bot_gbp.id.to_s]
           }

      expect(response).to redirect_to(onboarding_complete_path(code: invitation.code))

      # New user should have a modified MT5 ID
      new_user = User.find_by(email: invitation.email)
      expect(new_user.mt5_accounts.first.mt5_id).not_to eq("DUPLICATE123")
    end
  end

  describe "Pricing calculations" do
    let(:invitation) { create(:invitation) }

    before do
      allow(Stripe::PaymentIntent).to receive(:create).and_return(
        double(client_secret: "pi_test")
      )
    end

    it "calculates correct total for multiple bots" do
      post onboarding_payment_intent_path(code: invitation.code),
           params: {
             offer_type: "licence",
             selected_bots: [trading_bot_gbp.id, trading_bot_gold.id, trading_bot_btc.id]
           },
           as: :json

      # 399.99 + 399.99 + 499.99 + 399.99 (VPS) = 1699.96
      expected_amount = ((399.99 + 399.99 + 499.99 + 399.99) * 100).to_i
      
      expect(Stripe::PaymentIntent).to have_received(:create).with(
        hash_including(amount: expected_amount)
      )
    end

    it "calculates correct total for single bot" do
      post onboarding_payment_intent_path(code: invitation.code),
           params: {
             offer_type: "licence",
             selected_bots: [trading_bot_gbp.id]
           },
           as: :json

      # 399.99 + 399.99 (VPS) = 799.98
      expected_amount = ((399.99 + 399.99) * 100).to_i
      
      expect(Stripe::PaymentIntent).to have_received(:create).with(
        hash_including(amount: expected_amount)
      )
    end
  end

  describe "Security" do
    let(:invitation) { create(:invitation) }

    it "generates a random password for new users" do
      allow(Stripe::PaymentIntent).to receive(:create).and_return(
        double(client_secret: "pi_test")
      )

      post onboarding_next_step_path(code: invitation.code),
           params: {
             first_name: "Secure",
             last_name: "User",
             email: invitation.email,
             phone: "+33600000000",
             broker_name: "IC Markets",
             account_id: "SEC123456",
             account_password: "pass",
             offer_type: "licence",
             selected_bots: [trading_bot_gbp.id.to_s]
           }

      user = User.find_by(email: invitation.email)
      expect(user).to be_present
      expect(user.password_digest).to be_present
    end

    it "stores broker password securely in MT5 account" do
      allow(Stripe::PaymentIntent).to receive(:create).and_return(
        double(client_secret: "pi_test")
      )

      post onboarding_next_step_path(code: invitation.code),
           params: {
             first_name: "Broker",
             last_name: "Test",
             email: invitation.email,
             phone: "+33600000000",
             broker_name: "IC Markets",
             account_id: "BROKER123",
             account_password: "super_secret_broker_pass",
             offer_type: "licence",
             selected_bots: [trading_bot_gbp.id.to_s]
           }

      user = User.find_by(email: invitation.email)
      mt5 = user.mt5_accounts.first
      expect(mt5.broker_password).to eq("super_secret_broker_pass")
    end
  end
end
