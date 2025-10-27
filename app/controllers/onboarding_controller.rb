class OnboardingController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:next_step, :complete]
  
  before_action :find_invitation, only: [:show, :step]
  before_action :verify_access, only: [:show, :step]
  
  def landing
    render :landing
  end
  
  def show
    redirect_to onboarding_step_path(code: params[:code], step: @invitation.step)
  end
  
  def step
    render_step(@invitation.step)
  end
  
  def next_step
    @invitation = Invitation.find_by(code: params[:code])
    
    unless @invitation && @invitation.is_valid?
      redirect_to root_path, alert: "Code d'invitation invalide ou expiré"
      return
    end
    
    update_step_data
    
    if @invitation.step >= 4
      @invitation.complete!
      redirect_to onboarding_complete_path(code: params[:code])
    else
      @invitation.update(step: @invitation.step + 1)
      redirect_to onboarding_step_path(code: params[:code], step: @invitation.step)
    end
  end
  
  def complete
    @invitation = Invitation.find_by(code: params[:code])
    
    unless @invitation
      redirect_to root_path, alert: "Code d'invitation invalide"
      return
    end
    
    if user_created?
      @password = @random_password
      render :complete
    else
      redirect_to onboarding_step_path(code: params[:code], step: 1), alert: "Une erreur s'est produite"
    end
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
  
  def render_step(step_number)
    case step_number
    when 1
      render :step1_slides
    when 2
      @brokers = [
        {
          name: "Exness",
          logo: "🏦",
          description: "Bénéficiez de spreads serrés et d’une excellente exécution.",
          affiliate_link: "https://www.exness.com/a/l8cjp5hw8a",
          advantages: ["Spread serré", "Exécution rapide", "Support 24/7"]
        },
        {
          name: "IC Markets",
          logo: "📈",
          description: "Spreads compétitifs et plateforme MetaTrader 5 professionnelle.",
          affiliate_link: "https://icmarkets.com/?camp=25863",
          advantages: ["Spread ultra-serré", "Leverage jusqu'à 1:500", "Plateforme ECN"]
        }
      ]
      render :step2_brokers
    when 3
      @trading_bots = TradingBot.active.order(:price)
      render :step3_bots_selection
    when 4
      render :step4_payment
    else
      render :step1_rules
    end
  end
  
  def update_step_data
    case @invitation.step
    when 1
      @invitation.update(
        first_name: params[:first_name],
        last_name: params[:last_name],
        email: params[:email],
        phone: params[:phone],
        budget: params[:budget].to_f
      )
    when 2
      broker_data = {
        broker_name: params[:broker_name],
        affiliate_link: params[:affiliate_link],
        account_id: params[:account_id],
        account_password: params[:account_password]
      }
      @invitation.update(broker_data: broker_data.to_json)
      
      credentials = {
        account_id: params[:account_id],
        account_password: params[:account_password]
      }
      @invitation.update(broker_credentials: credentials.to_json)
    when 3
      if params[:selected_bots].present?
        @invitation.update(selected_bots: params[:selected_bots].to_json)
      end
    end
  end
  
  def user_created?
    return false unless @invitation.step == 4
    
    bot_ids = @invitation.selected_bots_parsed
    broker_creds = @invitation.broker_credentials_parsed
    
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
    
    bot_ids.each do |bot_id|
      bot = TradingBot.find(bot_id)
      
      user.bot_purchases.create!(
        trading_bot: bot,
        price_paid: bot.price,
        status: "active",
        purchase_type: "onboarding",
        is_running: false
      )
    end
    
    @invitation.complete!
    
    @user = user
    @vps_price = vps.monthly_price * 12
    @selected_bots = TradingBot.where(id: bot_ids)
    
    true
  rescue => e
    Rails.logger.error "Erreur lors de la création de l'utilisateur: #{e.message}"
    false
  end
end

