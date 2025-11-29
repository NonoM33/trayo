class OnboardingController < ApplicationController
  layout 'onboarding'
  skip_before_action :verify_authenticity_token, only: [:next_step, :complete, :create_payment_intent, :confirm_payment, :update_step]
  
  before_action :find_invitation, only: [:show, :step, :create_payment_intent, :update_step]
  before_action :verify_access, only: [:show, :step]
  
  def landing
    render :landing
  end
  
  def show
    @brokers = load_brokers
    @trading_bots = TradingBot.active.order(:price)
    render :show
  end
  
  def step
    @brokers = load_brokers
    @trading_bots = TradingBot.active.order(:price)
    render :show
  end
  
  def create_payment_intent
    offer_type = params[:offer_type] || 'licence'
    
    if offer_type == 'subscription'
      create_subscription_setup
    else
      create_one_time_payment
    end
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def create_one_time_payment
    amount = calculate_total_amount
    
    intent = Stripe::PaymentIntent.create(
      amount: (amount * 100).to_i,
      currency: 'eur',
      metadata: { 
        invitation_code: @invitation.code,
        email: @invitation.email,
        offer_type: 'licence'
      }
    )
    
    @invitation.update(stripe_payment_intent_id: intent.id)
    
    render json: { 
      clientSecret: intent.client_secret,
      paymentIntentId: intent.id,
      type: 'payment_intent'
    }
  end

  def create_subscription_setup
    plan = params[:subscription_plan] || 'starter'
    plan_config = Subscription::PLANS[plan]
    
    unless plan_config
      render json: { error: "Plan invalide" }, status: :unprocessable_entity
      return
    end

    setup_intent = Stripe::SetupIntent.create(
      payment_method_types: ['card'],
      metadata: {
        invitation_code: @invitation.code,
        email: @invitation.email,
        plan: plan
      }
    )

    @invitation.update(
      broker_data: (@invitation.broker_data_parsed || {}).merge(
        offer_type: 'subscription',
        subscription_plan: plan,
        setup_intent_id: setup_intent.id
      ).to_json
    )

    render json: {
      clientSecret: setup_intent.client_secret,
      setupIntentId: setup_intent.id,
      type: 'setup_intent',
      plan: plan,
      price: plan_config[:price]
    }
  end

  public
  
  def confirm_payment
    @invitation = Invitation.find_by(code: params[:code])
    
    unless @invitation
      render json: { error: "Invitation invalide" }, status: :not_found
      return
    end

    offer_type = params[:offer_type] || @invitation.broker_data_parsed["offer_type"] || 'licence'

    if offer_type == 'subscription'
      confirm_subscription_payment
    else
      confirm_one_time_payment
    end
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe confirmation error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def confirm_one_time_payment
    payment_intent_id = params[:payment_intent_id]
    
    intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
    
    if intent.status == 'succeeded'
      @invitation.update(
        stripe_payment_intent_id: payment_intent_id,
        broker_data: (@invitation.broker_data_parsed || {}).merge(
          payment_status: 'succeeded',
          paid_at: Time.current.iso8601
        ).to_json
      )
      
      render json: { 
        success: true, 
        status: 'succeeded',
        message: 'Paiement confirmé'
      }
    else
      render json: { 
        success: false, 
        status: intent.status,
        message: 'Paiement en attente de confirmation'
      }
    end
  end

  def confirm_subscription_payment
    setup_intent_id = params[:setup_intent_id]
    payment_method_id = params[:payment_method_id]
    plan = params[:plan] || @invitation.broker_data_parsed["subscription_plan"] || 'pro'

    unless payment_method_id.present?
      if setup_intent_id.present?
        setup_intent = Stripe::SetupIntent.retrieve(setup_intent_id)
        payment_method_id = setup_intent.payment_method
      end
    end

    unless payment_method_id.present?
      render json: { error: "Méthode de paiement manquante" }, status: :unprocessable_entity
      return
    end

    @invitation.update(
      broker_data: (@invitation.broker_data_parsed || {}).merge(
        payment_method_id: payment_method_id,
        subscription_confirmed: true,
        confirmed_at: Time.current.iso8601
      ).to_json
    )

    render json: {
      success: true,
      status: 'confirmed',
      message: 'Abonnement prêt à être activé',
      plan: plan
    }
  end

  def update_step
    step = params[:step].to_i
    if step >= 1 && step <= 6
      @invitation.update(step: step)
      render json: { success: true, step: step }
    else
      render json: { success: false, error: "Invalid step" }, status: :unprocessable_entity
    end
  end
  
  def next_step
    @invitation = Invitation.find_by(code: params[:code])
    
    unless @invitation && @invitation.is_valid?
      redirect_to root_path, alert: "Code d'invitation invalide ou expiré"
      return
    end
    
    update_step_data
    
    if user_created?
      @invitation.complete!
      session[:onboarding_password] = @random_password
      redirect_to onboarding_complete_path(code: params[:code])
    else
      redirect_to onboarding_path(code: params[:code]), alert: "Une erreur s'est produite"
    end
  end
  
  def complete
    @invitation = Invitation.find_by(code: params[:code])
    
    unless @invitation
      redirect_to root_path, alert: "Code d'invitation invalide"
      return
    end
    
    @password = session.delete(:onboarding_password)
    @user = User.find_by(email: @invitation.email)
    @selected_bots = TradingBot.where(id: @invitation.selected_bots_parsed)
    
    render :complete
  end
  
  private
  
  def find_invitation
    @invitation = Invitation.find_by(code: params[:code])
    
    unless @invitation
      redirect_to root_path, alert: "Code d'invitation invalide"
      return
    end
  end
  
  def verify_access
    unless @invitation.is_valid?
      redirect_to root_path, alert: "Code d'invitation expiré ou déjà utilisé"
      return
    end
  end
  
  def update_step_data
    @invitation.update(
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[:email],
      phone: params[:phone]
    )
    
    if params[:broker_name].present?
      broker_data = {
        broker_name: params[:broker_name],
        account_id: params[:account_id],
        account_password: params[:account_password]
      }
      @invitation.update(broker_data: broker_data.to_json)
      
      credentials = {
        account_id: params[:account_id],
        account_password: params[:account_password]
      }
      @invitation.update(broker_credentials: credentials.to_json)
    end
    
    # Gérer le type d'offre
    offer_type = params[:offer_type] || 'licence'
    
    if offer_type == 'subscription' && params[:subscription_plan].present?
      # Pour les abonnements, on stocke le plan et on détermine les bots inclus
      plan_bots = get_bots_for_plan(params[:subscription_plan])
      @invitation.update(
        selected_bots: plan_bots.to_json,
        broker_data: (@invitation.broker_data_parsed || {}).merge(
          offer_type: 'subscription',
          subscription_plan: params[:subscription_plan]
        ).to_json
      )
    elsif params[:selected_bots].present?
      @invitation.update(
        selected_bots: params[:selected_bots].to_json,
        broker_data: (@invitation.broker_data_parsed || {}).merge(
          offer_type: 'licence'
        ).to_json
      )
    end
  end
  
  def get_bots_for_plan(plan)
    case plan
    when 'starter'
      # Bot GBPUSD uniquement
      TradingBot.active.where("LOWER(name) LIKE ?", "%gbp%").pluck(:id)
    when 'pro'
      # Bots GBPUSD + Or
      TradingBot.active.where("LOWER(name) LIKE ? OR LOWER(name) LIKE ? OR LOWER(symbol) LIKE ?", "%gbp%", "%or%", "%xau%").pluck(:id)
    when 'premium'
      # Tous les bots
      TradingBot.active.pluck(:id)
    else
      []
    end
  end
  
  def user_created?
    bot_ids = @invitation.selected_bots_parsed
    broker_creds = @invitation.broker_credentials_parsed
    broker_data = @invitation.broker_data_parsed
    
    return false if @invitation.email.blank?
    
    # Vérifier si l'utilisateur existe déjà
    existing_user = User.find_by(email: @invitation.email)
    if existing_user
      Rails.logger.warn "User #{@invitation.email} already exists, skipping creation"
      @user = existing_user
      @random_password = nil
      return true
    end
    
    @random_password = SecureRandom.hex(8) # 8 caractères hex = 16 chars
    
    ActiveRecord::Base.transaction do
      user = User.create!(
        email: @invitation.email,
        first_name: @invitation.first_name,
        last_name: @invitation.last_name,
        phone: @invitation.phone,
        password: @random_password,
        password_confirmation: @random_password,
        commission_rate: 25.0,
        is_admin: false,
        init_mt5: false
      )
      
      # Créer le compte MT5 avec un ID unique si nécessaire
      mt5_id = broker_creds["account_id"].to_s.presence || "MT5_#{user.id}_#{Time.current.to_i}"
      
      # Vérifier que le mt5_id n'est pas déjà utilisé
      if Mt5Account.exists?(mt5_id: mt5_id)
        mt5_id = "#{mt5_id}_#{SecureRandom.hex(4)}"
      end
      
      mt5_account = user.mt5_accounts.create!(
        mt5_id: mt5_id,
        account_name: "#{@invitation.first_name} #{@invitation.last_name}".strip.presence || user.email,
        broker_name: broker_data["broker_name"].presence || "Broker",
        broker_server: "DEFAULT",
        broker_password: broker_creds["account_password"],
        balance: 0,
        initial_balance: 0,
        high_watermark: 0,
        is_admin_account: false
      )
    
    offer_type = broker_data["offer_type"]
    subscription_plan = broker_data["subscription_plan"]
    payment_method_id = broker_data["payment_method_id"]
    is_subscription = offer_type == 'subscription' && subscription_plan.present?

    vps = user.vps.create!(
      name: "VPS #{@invitation.first_name}",
      status: "ordered",
      monthly_price: is_subscription ? 0 : 399.99,
      billing_status: is_subscription ? 'paid' : 'pending',
      ordered_at: Time.current
    )
    
    bot_purchases_created = []
    if bot_ids.present? && bot_ids.is_a?(Array) && bot_ids.any?
      bot_ids = bot_ids.map(&:to_i) unless bot_ids.first.is_a?(Integer)
      bot_ids.each do |bot_id|
        begin
          bot = TradingBot.find(bot_id)
          
          purchase = user.bot_purchases.create!(
            trading_bot: bot,
            price_paid: is_subscription ? 0 : bot.price,
            status: "active",
            purchase_type: is_subscription ? "subscription_#{subscription_plan}" : "onboarding",
            billing_status: is_subscription ? 'paid' : 'pending',
            is_running: false
          )
          bot_purchases_created << purchase
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.error "Bot with ID #{bot_id} not found: #{e.message}"
        end
      end
    end

    if is_subscription && payment_method_id.present?
      begin
        result = SubscriptionService.create_subscription(
          user: user,
          plan: subscription_plan,
          payment_method_id: payment_method_id
        )
        
        @subscription = result[:subscription]
        Rails.logger.info "Subscription created: #{@subscription.stripe_subscription_id}"
      rescue => e
        Rails.logger.error "Failed to create subscription: #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
      end
    elsif bot_purchases_created.any? || vps.present?
      builder = Invoices::Builder.new(
        user: user,
        source: "invitation",
        metadata: { invitation_id: @invitation.id },
        deactivate_bots: true
      )
      @invoice = builder.build_from_selection(
        bot_purchases: bot_purchases_created,
        vps_list: vps.present? ? [vps] : []
      )
      
      if @invoice && @invitation.stripe_payment_intent_id.present?
        @invoice.update(stripe_payment_intent_id: @invitation.stripe_payment_intent_id)
        
        begin
          intent = Stripe::PaymentIntent.retrieve(@invitation.stripe_payment_intent_id)
          if intent.status == 'succeeded'
            @invoice.register_payment!(
              amount: intent.amount / 100.0,
              payment_method: 'stripe',
              paid_at: Time.current,
              notes: "Paiement Stripe: #{intent.id}"
            )
            @invoice.update(stripe_charge_id: intent.latest_charge)
          end
        rescue Stripe::StripeError => e
          Rails.logger.error "Error retrieving PaymentIntent: #{e.message}"
        end
      end
    end
    
    @user = user
      @password = @random_password
      @vps_price = vps.monthly_price * 12
      @selected_bots = TradingBot.where(id: bot_ids)
    end # fin transaction
    
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Validation error: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    false
  rescue => e
    Rails.logger.error "Erreur lors de la création de l'utilisateur: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    false
  end
  
  def load_brokers
    [
      {
        id: "fusion",
        name: "Fusion Markets",
        logo: "🔄",
        description: "Low cost trading avec commissions à $2.25 par trade.",
        affiliate_link: "https://fusionmarkets.com/",
        advantages: ["Spread 0.0", "Commission $2.25", "Support dédié"]
      },
      {
        id: "icmarkets",
        name: "IC Markets",
        logo: "📈", 
        description: "Spreads compétitifs et plateforme MT5 professionnelle.",
        affiliate_link: "https://icmarkets.com/?camp=25863",
        advantages: ["Spread ultra-serré", "Leverage 1:500", "ECN"]
      }
    ]
  end
  
  def calculate_total_amount
    offer_type = params[:offer_type] || 'licence'
    
    if offer_type == 'subscription'
      plan_prices = { 'starter' => 99, 'pro' => 149.99, 'premium' => 299.99 }
      plan = params[:subscription_plan] || 'starter'
      plan_prices[plan] || 99
    else
      bot_ids = params[:selected_bots] || @invitation.selected_bots_parsed
      bot_ids = JSON.parse(bot_ids) if bot_ids.is_a?(String)
      
      bots_total = TradingBot.where(id: bot_ids).sum(:price)
      vps_price = 399.99 # Prix annuel du VPS
      
      bots_total + vps_price
    end
  end
end
