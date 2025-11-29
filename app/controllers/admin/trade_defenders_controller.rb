module Admin
  class TradeDefendersController < BaseController
    before_action :require_admin
    
    def index
      if params[:status].present? && params[:status] == 'all'
        @manual_trades = Trade.where(trade_originality: ['manual_pending_review', 'manual_client', 'manual_admin'])
                              .includes(mt5_account: :user)
                              .order(close_time: :desc)
      elsif params[:status].present?
        @manual_trades = Trade.where(trade_originality: params[:status])
                              .includes(mt5_account: :user)
                              .order(close_time: :desc)
      else
        @manual_trades = Trade.where(trade_originality: 'manual_pending_review')
                              .includes(mt5_account: :user)
                              .order(close_time: :desc)
      end
      
      @manual_trades = @manual_trades.joins(:mt5_account).where.not(mt5_accounts: { user_id: nil })
      
      if params[:account_id].present?
        @manual_trades = @manual_trades.where(mt5_account_id: params[:account_id])
      end
      
      if params[:symbol].present?
        @manual_trades = @manual_trades.where(symbol: params[:symbol])
      end
      
      if params[:date_from].present?
        @manual_trades = @manual_trades.where('close_time >= ?', params[:date_from])
      end
      
      if params[:date_to].present?
        @manual_trades = @manual_trades.where('close_time <= ?', params[:date_to])
      end
      
      @manual_trades = @manual_trades.page(params[:page]).per(50)
      
      @pending_trades = Trade.where(trade_originality: 'manual_pending_review').count
      @client_trades = Trade.where(trade_originality: 'manual_client').count
      @admin_trades = Trade.where(trade_originality: 'manual_admin').count
      
      @total_penalty = Trade.where(trade_originality: 'manual_client').sum(:profit)
      
      @accounts_with_manual_trades = Mt5Account.joins(:trades, :user)
                                               .where(trades: { trade_originality: ['manual_pending_review', 'manual_client', 'manual_admin'] })
                                               .distinct
                                               .includes(:user)
      
      @all_accounts = @manual_trades.includes(:mt5_account).map { |t| t.mt5_account }.uniq.compact
      @all_symbols = Trade.where(trade_originality: ['manual_pending_review', 'manual_client', 'manual_admin']).distinct.pluck(:symbol).compact.sort
    end
    
    def approve_trade
      @trade = Trade.find(params[:id])
      old_profit = @trade.profit.abs
      
      ActiveRecord::Base.transaction do
        @trade.update!(
          trade_originality: 'manual_admin',
          is_unauthorized_manual: false
        )
        
        if @trade.trade_originality_before_last_save == 'manual_client' && @trade.mt5_account.present?
          mt5_account = @trade.mt5_account
          mt5_account.update!(high_watermark: mt5_account.high_watermark + old_profit)
        end
      end
      
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "Trade marqué comme vôtre"
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      Rails.logger.error "Trade Defender Approve Error: #{e.message}"
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), alert: "Erreur: #{e.message}"
    end
    
    def mark_as_client_trade
      @trade = Trade.find(params[:id])
      
      ActiveRecord::Base.transaction do
        @trade.update!(
          trade_originality: 'manual_client',
          is_unauthorized_manual: true
        )
        
        @trade.mt5_account.apply_trade_defender_penalty(@trade.profit) if @trade.mt5_account.present?
      end
      
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "Trade marqué comme client - pénalité appliquée"
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      Rails.logger.error "Trade Defender Client Mark Error: #{e.message}"
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), alert: "Erreur: #{e.message}"
    end
    
    def recalculate_penalties_for_account
      @mt5_account = Mt5Account.find(params[:mt5_account_id])
      @mt5_account.recalculate_watermark_with_penalties
      
      redirect_to admin_client_path(@mt5_account.user), notice: "Watermark recalculé avec pénalités appliquées"
    rescue ActiveRecord::RecordNotFound => e
      redirect_to admin_trade_defenders_path, alert: "Compte non trouvé"
    end
    
    def bulk_mark_as_admin
      trade_ids = params[:trade_ids] || []
      
      if trade_ids.any?
        ActiveRecord::Base.transaction do
          trades = Trade.where(id: trade_ids).where(trade_originality: 'manual_client').includes(:mt5_account)
          trades.each do |trade|
            next unless trade.mt5_account.present?
            trade.mt5_account.update!(high_watermark: trade.mt5_account.high_watermark + trade.profit.abs)
          end
          
          Trade.where(id: trade_ids).update_all(
            trade_originality: 'manual_admin',
            is_unauthorized_manual: false
          )
        end
        
        redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "#{trade_ids.count} trades marqués comme vôtres"
      else
        redirect_to admin_trade_defenders_path, alert: "Aucun trade sélectionné"
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      Rails.logger.error "Trade Defender Bulk Admin Error: #{e.message}"
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), alert: "Erreur: #{e.message}"
    end
    
    def bulk_mark_as_client
      trade_ids = params[:trade_ids] || []
      
      if trade_ids.any?
        ActiveRecord::Base.transaction do
          trades = Trade.where(id: trade_ids).includes(:mt5_account)
          trades.each do |trade|
            next unless trade.mt5_account.present?
            
            trade.update!(
              trade_originality: 'manual_client',
              is_unauthorized_manual: true
            )
            trade.mt5_account.apply_trade_defender_penalty(trade.profit)
          end
        end
        
        redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "#{trade_ids.count} trades marqués comme client - pénalités appliquées"
      else
        redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), alert: "Aucun trade sélectionné"
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      Rails.logger.error "Trade Defender Bulk Client Error: #{e.message}"
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), alert: "Erreur: #{e.message}"
    end
    
    def mark_all_pending_as_admin
      ActiveRecord::Base.transaction do
        count = Trade.where(trade_originality: 'manual_pending_review').update_all(
          trade_originality: 'manual_admin',
          is_unauthorized_manual: false
        )
        
        redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "#{count} trades marqués comme vôtres"
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      Rails.logger.error "Trade Defender Error: #{e.message}"
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), alert: "Erreur lors de la mise à jour: #{e.message}"
    end
    
    def mark_all_pending_as_client
      trades = Trade.where(trade_originality: 'manual_pending_review').includes(mt5_account: :user)
      count = 0
      
      ActiveRecord::Base.transaction do
        trades.find_each do |trade|
          next unless trade.mt5_account.present?
          
          trade.update!(
            trade_originality: 'manual_client',
            is_unauthorized_manual: true
          )
          trade.mt5_account.apply_trade_defender_penalty(trade.profit)
          count += 1
        end
      end
      
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "#{count} trades marqués comme client - pénalités appliquées"
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      Rails.logger.error "Trade Defender Error: #{e.message}"
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), alert: "Erreur lors de la mise à jour: #{e.message}"
    end
  end
end

