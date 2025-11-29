require 'rails_helper'

RSpec.describe OnboardingController, type: :request do
  let!(:trading_bot_gbp) { create(:trading_bot, name: "GBPUSD Bot", price: 399.99) }
  let!(:trading_bot_gold) { create(:trading_bot, name: "Or XAU/USD", price: 399.99) }
  let!(:trading_bot_btc) { create(:trading_bot, name: "BTC Bot", price: 499.99) }

  describe "GET #show" do
    context "with valid invitation" do
      let(:invitation) { create(:invitation) }

      it "renders the show page successfully" do
        get onboarding_path(code: invitation.code)
        expect(response).to be_successful
      end

      it "includes trading bots in the response" do
        get onboarding_path(code: invitation.code)
        expect(response.body).to include(trading_bot_gbp.name)
      end
    end

    context "with invalid invitation" do
      it "redirects to root with alert" do
        get onboarding_path(code: "INVALID_CODE")
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "with expired invitation" do
      let(:invitation) { create(:invitation, :expired) }

      it "redirects to root with alert" do
        get onboarding_path(code: invitation.code)
        expect(response).to redirect_to(root_path)
      end
    end

    context "with completed invitation" do
      let(:invitation) { create(:invitation, :completed) }

      it "redirects to root" do
        get onboarding_path(code: invitation.code)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST #create_payment_intent" do
    let(:invitation) { create(:invitation, :with_broker_data, :with_bots, bots: [trading_bot_gbp]) }

    context "with licence offer type" do
      before do
        allow(Stripe::PaymentIntent).to receive(:create).and_return(
          double(client_secret: "pi_test_secret_123", id: "pi_test_123")
        )
      end

      it "creates payment intent with correct amount for bots + VPS" do
        post onboarding_payment_intent_path(code: invitation.code),
             params: {
               offer_type: "licence",
               selected_bots: [trading_bot_gbp.id]
             },
             as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["clientSecret"]).to eq("pi_test_secret_123")
        expect(json["type"]).to eq("payment_intent")

        expect(Stripe::PaymentIntent).to have_received(:create).with(
          hash_including(
            amount: 79998,
            currency: 'eur'
          )
        )
      end
    end

    context "with subscription offer type" do
      before do
        allow(Stripe::SetupIntent).to receive(:create).and_return(
          double(client_secret: "seti_test_secret", id: "seti_test_123")
        )
      end

      it "creates setup intent for starter plan" do
        post onboarding_payment_intent_path(code: invitation.code),
             params: {
               offer_type: "subscription",
               subscription_plan: "starter"
             },
             as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["type"]).to eq("setup_intent")
        expect(json["plan"]).to eq("starter")
        expect(json["price"]).to eq(99.0)
      end

      it "creates setup intent for pro plan" do
        post onboarding_payment_intent_path(code: invitation.code),
             params: {
               offer_type: "subscription",
               subscription_plan: "pro"
             },
             as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["type"]).to eq("setup_intent")
        expect(json["plan"]).to eq("pro")
        expect(json["price"]).to eq(149.99)
      end

      it "creates setup intent for premium plan" do
        post onboarding_payment_intent_path(code: invitation.code),
             params: {
               offer_type: "subscription",
               subscription_plan: "premium"
             },
             as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["type"]).to eq("setup_intent")
        expect(json["plan"]).to eq("premium")
        expect(json["price"]).to eq(299.99)
      end
    end

    context "with Stripe error" do
      before do
        allow(Stripe::PaymentIntent).to receive(:create).and_raise(
          Stripe::StripeError.new("Card declined")
        )
      end

      it "returns error response" do
        post onboarding_payment_intent_path(code: invitation.code),
             params: {
               offer_type: "licence",
               selected_bots: [trading_bot_gbp.id]
             },
             as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Card declined")
      end
    end
  end

  describe "POST #next_step" do
    let(:invitation) { create(:invitation, :with_broker_data, :with_bots, bots: [trading_bot_gbp, trading_bot_gold]) }

    context "with valid data for licence" do
      let(:valid_params) do
        {
          code: invitation.code,
          first_name: "Jean",
          last_name: "Dupont",
          email: invitation.email,
          phone: "+33612345678",
          broker_name: "IC Markets",
          account_id: "123456789",
          account_password: "secretpass",
          offer_type: "licence",
          selected_bots: [trading_bot_gbp.id.to_s, trading_bot_gold.id.to_s]
        }
      end

      it "creates a new user" do
        expect {
          post onboarding_next_step_path(code: invitation.code), params: valid_params
        }.to change(User, :count).by(1)
      end

      it "creates MT5 account" do
        expect {
          post onboarding_next_step_path(code: invitation.code), params: valid_params
        }.to change(Mt5Account, :count).by(1)
      end

      it "creates VPS with ordered status" do
        expect {
          post onboarding_next_step_path(code: invitation.code), params: valid_params
        }.to change(Vps, :count).by(1)

        vps = Vps.last
        expect(vps.status).to eq("ordered")
        expect(vps.monthly_price).to eq(399.99)
      end

      it "creates bot purchases for selected bots" do
        expect {
          post onboarding_next_step_path(code: invitation.code), params: valid_params
        }.to change(BotPurchase, :count).by(2)

        purchases = BotPurchase.last(2)
        expect(purchases.map(&:trading_bot_id)).to match_array([trading_bot_gbp.id, trading_bot_gold.id])
        expect(purchases.all? { |p| p.is_running == false }).to be true
      end

      it "creates an invoice" do
        expect {
          post onboarding_next_step_path(code: invitation.code), params: valid_params
        }.to change(Invoice, :count).by(1)
      end

      it "marks invitation as completed" do
        post onboarding_next_step_path(code: invitation.code), params: valid_params
        invitation.reload
        expect(invitation.status).to eq("completed")
      end

      it "redirects to complete page" do
        post onboarding_next_step_path(code: invitation.code), params: valid_params
        expect(response).to redirect_to(onboarding_complete_path(code: invitation.code))
      end
    end

    context "with valid data for subscription" do
      let(:valid_params) do
        {
          code: invitation.code,
          first_name: "Marie",
          last_name: "Martin",
          email: invitation.email,
          phone: "+33698765432",
          broker_name: "Fusion Markets",
          account_id: "987654321",
          account_password: "password123",
          offer_type: "subscription",
          subscription_plan: "pro"
        }
      end

      it "creates bot purchases for subscription plan bots" do
        post onboarding_next_step_path(code: invitation.code), params: valid_params
        
        user = User.find_by(email: invitation.email)
        expect(user.bot_purchases.count).to be >= 1
      end

      it "stores subscription plan in broker_data" do
        post onboarding_next_step_path(code: invitation.code), params: valid_params
        invitation.reload
        
        broker_data = JSON.parse(invitation.broker_data)
        expect(broker_data["offer_type"]).to eq("subscription")
        expect(broker_data["subscription_plan"]).to eq("pro")
      end
    end

    context "with duplicate MT5 account ID" do
      before do
        create(:mt5_account, mt5_id: "123456789")
      end

      let(:valid_params) do
        {
          code: invitation.code,
          first_name: "Pierre",
          last_name: "Durand",
          email: invitation.email,
          phone: "+33612345678",
          broker_name: "IC Markets",
          account_id: "123456789", # Already exists
          account_password: "password",
          offer_type: "licence",
          selected_bots: [trading_bot_gbp.id.to_s]
        }
      end

      it "creates user with unique MT5 ID" do
        expect {
          post onboarding_next_step_path(code: invitation.code), params: valid_params
        }.to change(User, :count).by(1)

        user = User.find_by(email: invitation.email)
        expect(user.mt5_accounts.count).to eq(1)
        expect(user.mt5_accounts.first.mt5_id).not_to eq("123456789")
      end
    end

    context "when user already exists" do
      before do
        create(:user, email: invitation.email)
      end

      it "does not create duplicate user" do
        expect {
          post onboarding_next_step_path(code: invitation.code), params: { code: invitation.code }
        }.not_to change(User, :count)
      end
    end
  end

  describe "GET #complete" do
    let(:invitation) { create(:invitation, :completed) }
    let!(:user) { create(:user, email: invitation.email) }

    it "renders complete page successfully" do
      get onboarding_complete_path(code: invitation.code)
      expect(response).to be_successful
    end

    it "includes user email in response" do
      get onboarding_complete_path(code: invitation.code)
      expect(response.body).to include(user.email)
    end

    context "with invalid invitation code" do
      it "redirects to root" do
        get onboarding_complete_path(code: "INVALID")
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
