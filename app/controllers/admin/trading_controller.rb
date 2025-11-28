class Admin::TradingController < Admin::BaseController
  before_action :require_admin

  def index
    @tab = params[:tab] || 'trades'
    
    case @tab
    when 'trades'
      load_trades
    when 'defender'
      load_trade_defender
    end
  end

  private

  def load_trades
    @clients = User.where(is_admin: false).order(:first_name)
    @symbols = Trade.distinct.pluck(:symbol).compact.sort
    @magic_numbers = Trade.distinct.pluck(:magic_number).compact.sort
    @bots_cache = TradingBot.where.not(magic_number_prefix: nil).to_a
    
    trades = Trade.includes(mt5_account: :user)
    
    if params[:client_id].present?
      trades = trades.joins(mt5_account: :user).where(users: { id: params[:client_id] })
    end
    trades = trades.where(symbol: params[:symbol]) if params[:symbol].present?
    trades = trades.where(magic_number: params[:magic_number]) if params[:magic_number].present?
    trades = trades.where('close_time >= ?', params[:date_from].to_date) if params[:date_from].present?
    trades = trades.where('close_time <= ?', params[:date_to].to_date.end_of_day) if params[:date_to].present?
    
    case params[:profit_filter]
    when 'positive' then trades = trades.where('profit > 0')
    when 'negative' then trades = trades.where('profit < 0')
    when 'zero' then trades = trades.where(profit: 0)
    end
    
    @trades = trades.order(close_time: :desc).page(params[:page]).per(50)
    @total_trades = trades.count
    @total_profit = trades.sum(:profit)
    @winning_trades = trades.where('profit > 0').count
    @losing_trades = trades.where('profit < 0').count
    @win_rate = @total_trades > 0 ? (@winning_trades.to_f / @total_trades * 100).round(1) : 0
    @magic_stats = trades.group(:magic_number).select(:magic_number, 'COUNT(*) as trades_count', 'SUM(profit) as total_profit').order('total_profit DESC')
  end

  def load_trade_defender
    @accounts_with_manual_trades = Mt5Account.joins(:trades).where.not(trades: { trade_originality: nil }).distinct.includes(:user)
    @all_symbols = Trade.where.not(trade_originality: nil).distinct.pluck(:symbol).compact.sort
    
    scope = Trade.where.not(trade_originality: nil).includes(mt5_account: :user)
    
    status = params[:status] || 'manual_pending_review'
    scope = scope.where(trade_originality: status) unless status == 'all'
    scope = scope.where(mt5_account_id: params[:account_id]) if params[:account_id].present?
    scope = scope.where(symbol: params[:symbol]) if params[:symbol].present?
    scope = scope.where('close_time >= ?', params[:date_from].to_date) if params[:date_from].present?
    scope = scope.where('close_time <= ?', params[:date_to].to_date.end_of_day) if params[:date_to].present?
    
    @manual_trades = scope.order(close_time: :desc).page(params[:page]).per(50)
    @pending_trades = Trade.where(trade_originality: 'manual_pending_review').count
    @admin_trades = Trade.where(trade_originality: 'manual_admin').count
    @client_trades = Trade.where(trade_originality: 'manual_client').count
    @total_penalty = Trade.where(trade_originality: 'manual_client').sum(:profit)
  end
end

