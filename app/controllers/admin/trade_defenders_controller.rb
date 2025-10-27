module Admin
  class TradeDefendersController < BaseController
    before_action :require_admin
    
    def index
      # Par défaut, on n'affiche QUE les trades en attente
      if params[:status].present? && params[:status] == 'all'
        # Si "Tous" est sélectionné, afficher tous les trades manuels
        @manual_trades = Trade.where(trade_originality: ['manual_pending_review', 'manual_client', 'manual_admin'])
                              .includes(:mt5_account)
                              .order(close_time: :desc)
      elsif params[:status].present?
        # Filtrer par statut spécifique
        @manual_trades = Trade.where(trade_originality: params[:status])
                              .includes(:mt5_account)
                              .order(close_time: :desc)
      else
        # Par défaut: afficher UNIQUEMENT les trades en attente
        @manual_trades = Trade.where(trade_originality: 'manual_pending_review')
                              .includes(:mt5_account)
                              .order(close_time: :desc)
      end
      
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
      
      @accounts_with_manual_trades = Mt5Account.joins(:trades)
                                               .where(trades: { trade_originality: ['manual_pending_review', 'manual_client', 'manual_admin'] })
                                               .distinct
                                               .includes(:user)
      
      @all_accounts = @manual_trades.includes(:mt5_account).map { |t| t.mt5_account }.uniq
      @all_symbols = Trade.where(trade_originality: ['manual_pending_review', 'manual_client', 'manual_admin']).distinct.pluck(:symbol).compact.sort
    end
    
    def approve_trade
      @trade = Trade.find(params[:id])
      old_profit = @trade.profit.abs
      
      @trade.update!(
        trade_originality: 'manual_admin',
        is_unauthorized_manual: false
      )
      
      if @trade.trade_originality_before_last_save == 'manual_client'
        mt5_account = @trade.mt5_account
        mt5_account.update(high_watermark: mt5_account.high_watermark + old_profit)
      end
      
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "Trade marked as admin trade"
    end
    
    def mark_as_client_trade
      @trade = Trade.find(params[:id])
      
      @trade.update!(
        trade_originality: 'manual_client',
        is_unauthorized_manual: true
      )
      
      @trade.mt5_account.apply_trade_defender_penalty(@trade.profit)
      
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "Trade marked as unauthorized client trade - penalty applied"
    end
    
    def recalculate_penalties_for_account
      @mt5_account = Mt5Account.find(params[:mt5_account_id])
      @mt5_account.recalculate_watermark_with_penalties
      
      redirect_to admin_client_path(@mt5_account.user), notice: "Watermark recalculated with penalties applied"
    end
    
    def bulk_mark_as_admin
      trade_ids = params[:trade_ids] || []
      
      if trade_ids.any?
        trades = Trade.where(id: trade_ids).where(trade_originality: 'manual_client')
        trades.each do |trade|
          trade.mt5_account.update(high_watermark: trade.mt5_account.high_watermark + trade.profit.abs)
        end
        
        Trade.where(id: trade_ids).update_all(
          trade_originality: 'manual_admin',
          is_unauthorized_manual: false
        )
        
        redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "#{trade_ids.count} trades marked as admin"
      else
        redirect_to admin_trade_defenders_path, alert: "No trades selected"
      end
    end
    
    def bulk_mark_as_client
      trade_ids = params[:trade_ids] || []
      
      if trade_ids.any?
        trades = Trade.where(id: trade_ids)
        trades.each do |trade|
          trade.update(
            trade_originality: 'manual_client',
            is_unauthorized_manual: true
          )
          trade.mt5_account.apply_trade_defender_penalty(trade.profit)
        end
        
        redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "#{trade_ids.count} trades marked as client - penalties applied"
      else
        redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), alert: "No trades selected"
      end
    end
    
    def mark_all_pending_as_admin
      count = Trade.where(trade_originality: 'manual_pending_review').update_all(
        trade_originality: 'manual_admin',
        is_unauthorized_manual: false
      )
      
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "#{count} trades marked as admin"
    end
    
    def mark_all_pending_as_client
      trades = Trade.where(trade_originality: 'manual_pending_review')
      
      trades.each do |trade|
        trade.update!(
          trade_originality: 'manual_client',
          is_unauthorized_manual: true
        )
        trade.mt5_account.apply_trade_defender_penalty(trade.profit)
      end
      
      redirect_to admin_trade_defenders_path(status: 'manual_pending_review'), notice: "#{trades.count} trades marked as client - penalties applied"
    end
  end
end

