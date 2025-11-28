class OnboardingController < ApplicationController
  layout 'onboarding'
  skip_before_action :verify_authenticity_token, only: [:next_step, :complete, :create_payment_intent]
  
  before_action :find_invitation, only: [:show, :step, :create_payment_intent]
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
    amount = calculate_total_amount
    
    intent = Stripe::PaymentIntent.create(
      amount: (amount * 100).to_i,
      currency: 'eur',
      metadata: { invitation_code: @invitation.code }
    )
    
    render json: { clientSecret: intent.client_secret }
  rescue Stripe::StripeError => e
    render json: { error: e.message }, status: :unprocessable_entity
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
      session[:onboarding_password] = @password
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
    
    if params[:selected_bots].present?
      @invitation.update(selected_bots: params[:selected_bots].to_json)
    end
  end
  
  def user_created?
    bot_ids = @invitation.selected_bots_parsed
    broker_creds = @invitation.broker_credentials_parsed
    
    return false if @invitation.email.blank? || broker_creds["account_id"].blank?
    
    @random_password = SecureRandom.hex(16)
    
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
    
    broker_data = @invitation.broker_data_parsed
    
    mt5_account = user.mt5_accounts.create!(
      mt5_id: broker_creds["account_id"].to_s,
      account_name: "#{@invitation.first_name} #{@invitation.last_name}",
      broker_name: broker_data["broker_name"],
      broker_server: "DEFAULT",
      broker_password: broker_creds["account_password"],
      balance: 0,
      initial_balance: 0,
      high_watermark: 0,
      is_admin_account: false
    )
    
    vps = user.vps.create!(
      name: "VPS #{@invitation.first_name}",
      status: "ordered",
      monthly_price: 399.99,
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
            price_paid: bot.price,
            status: "active",
            purchase_type: "onboarding",
            is_running: false
          )
          bot_purchases_created << purchase
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.error "Bot with ID #{bot_id} not found: #{e.message}"
        end
      end
    end

    if bot_purchases_created.any? || vps.present?
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
    end
    
    @user = user
    @password = @random_password
    @vps_price = vps.monthly_price * 12
    @selected_bots = TradingBot.where(id: bot_ids)
    
    true
  rescue => e
    Rails.logger.error "Erreur lors de la création de l'utilisateur: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
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
    bot_ids = params[:selected_bots] || @invitation.selected_bots_parsed
    bot_ids = JSON.parse(bot_ids) if bot_ids.is_a?(String)
    
    bots_total = TradingBot.where(id: bot_ids).sum(:price)
    vps_price = 399.99 # Prix annuel du VPS
    
    bots_total + vps_price
  end
end
