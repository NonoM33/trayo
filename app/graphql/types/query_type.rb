# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    field :user, Types::UserType, null: true, description: "Current authenticated user"
    def user
      context[:current_user]
    end

    field :users, [Types::UserType], null: true, description: "List of users (admin only)" do
      argument :limit, Integer, required: false, default_value: 50
      argument :offset, Integer, required: false, default_value: 0
    end
    def users(limit: 50, offset: 0)
      return [] unless context[:current_user]&.is_admin?
      User.order(created_at: :desc).limit(limit).offset(offset)
    end

    field :user_by_id, Types::UserType, null: true, description: "User by ID" do
      argument :id, ID, required: true
    end
    def user_by_id(id:)
      user = User.find_by(id: id)
      return nil unless user
      return nil unless context[:current_user]&.is_admin? || context[:current_user]&.id == user.id
      user
    end

    field :mt5_accounts, [Types::Mt5AccountType], null: true, description: "MT5 accounts of current user"
    def mt5_accounts
      return [] unless context[:current_user]
      context[:current_user].mt5_accounts
    end

    field :mt5_account, Types::Mt5AccountType, null: true, description: "MT5 account by ID" do
      argument :id, ID, required: true
    end
    def mt5_account(id:)
      account = Mt5Account.find_by(id: id)
      return nil unless account
      return nil unless context[:current_user]&.id == account.user_id || context[:current_user]&.is_admin?
      account
    end

    field :account_balance, Types::Mt5AccountType.connection_type, null: true, description: "Account balance aggregation"
    def account_balance
      return [] unless context[:current_user]
      context[:current_user].mt5_accounts
    end

    field :account_projection, [Types::ProjectionType], null: true, description: "Account projection" do
      argument :days, Integer, required: false, default_value: 30
    end
    def account_projection(days: 30)
      return [] unless context[:current_user]
      mt5_accounts = context[:current_user].mt5_accounts
      mt5_accounts.map do |account|
        projection_data = account.calculate_projection(days)
        {
          account_id: account.id,
          mt5_id: account.mt5_id,
          account_name: account.account_name,
          current_balance: account.balance,
          **projection_data
        }
      end
    end

    field :trades, Types::TradeType.connection_type, null: true, description: "List of trades" do
      argument :account_id, ID, required: false
      argument :bot_id, ID, required: false
      argument :symbol, String, required: false
      argument :status, String, required: false
      argument :start_date, Types::DateTimeType, required: false
      argument :end_date, Types::DateTimeType, required: false
    end
    def trades(account_id: nil, bot_id: nil, symbol: nil, status: nil, start_date: nil, end_date: nil)
      return Trade.none unless context[:current_user]

      scope = Trade.joins(mt5_account: :user).where(users: { id: context[:current_user].id })

      scope = scope.where(mt5_account_id: account_id) if account_id.present?
      scope = scope.where(symbol: symbol) if symbol.present?
      scope = scope.where(status: status) if status.present?

      if bot_id.present?
        bot = TradingBot.find_by(id: bot_id)
        scope = scope.where(magic_number: bot.magic_number_prefix) if bot&.magic_number_prefix
      end

      if start_date.present? || end_date.present?
        scope = scope.where("close_time >= ?", start_date) if start_date.present?
        scope = scope.where("close_time <= ?", end_date) if end_date.present?
      end

      scope.order(close_time: :desc)
    end

    field :trade, Types::TradeType, null: true, description: "Trade by ID" do
      argument :id, ID, required: true
    end
    def trade(id:)
      trade = Trade.find_by(id: id)
      return nil unless trade
      return nil unless context[:current_user]&.id == trade.mt5_account.user_id || context[:current_user]&.is_admin?
      trade
    end

    field :trades_stats, Types::StatsType, null: true, description: "Trades statistics" do
      argument :account_id, ID, required: false
      argument :start_date, Types::DateTimeType, required: false
      argument :end_date, Types::DateTimeType, required: false
    end
    def trades_stats(account_id: nil, start_date: nil, end_date: nil)
      return nil unless context[:current_user]

      scope = Trade.joins(mt5_account: :user).where(users: { id: context[:current_user].id })
      scope = scope.where(mt5_account_id: account_id) if account_id.present?
      scope = scope.where("close_time >= ?", start_date) if start_date.present?
      scope = scope.where("close_time <= ?", end_date) if end_date.present?

      trades = scope.to_a
      return nil if trades.empty?

      winning_trades = trades.select { |t| t.profit > 0 }
      losing_trades = trades.select { |t| t.profit < 0 }

      {
        total_profit: trades.sum(&:profit).round(2),
        total_trades: trades.count,
        winning_trades: winning_trades.count,
        losing_trades: losing_trades.count,
        win_rate: trades.any? ? (winning_trades.count.to_f / trades.count * 100).round(2) : 0,
        average_profit: trades.any? ? (trades.sum(&:profit) / trades.count).round(2) : 0,
        best_trade: trades.any? ? trades.max_by(&:profit)&.profit : nil,
        worst_trade: trades.any? ? trades.min_by(&:profit)&.profit : nil,
        total_commission: trades.sum { |t| t.commission || 0 }.round(2),
        total_swap: trades.sum { |t| t.swap || 0 }.round(2)
      }
    end

    field :trading_bots, [Types::TradingBotType], null: true, description: "List of available trading bots" do
      argument :status, String, required: false
      argument :risk_level, String, required: false
    end
    def trading_bots(status: nil, risk_level: nil)
      scope = TradingBot.active
      scope = scope.where(status: status) if status.present?
      scope = scope.where(risk_level: risk_level) if risk_level.present?
      scope
    end

    field :trading_bot, Types::TradingBotType, null: true, description: "Trading bot by ID" do
      argument :id, ID, required: true
    end
    def trading_bot(id:)
      TradingBot.find_by(id: id)
    end

    field :my_bots, [Types::BotPurchaseType], null: true, description: "Bots purchased by current user"
    def my_bots
      return [] unless context[:current_user]
      context[:current_user].bot_purchases.where(status: 'active')
    end

    field :bot_purchase, Types::BotPurchaseType, null: true, description: "Bot purchase by ID" do
      argument :id, ID, required: true
    end
    def bot_purchase(id:)
      purchase = BotPurchase.find_by(id: id)
      return nil unless purchase
      return nil unless context[:current_user]&.id == purchase.user_id || context[:current_user]&.is_admin?
      purchase
    end

    field :bot_status, Types::BotPurchaseType, null: true, description: "Bot status by purchase ID" do
      argument :purchase_id, ID, required: true
    end
    def bot_status(purchase_id:)
      purchase = BotPurchase.find_by(id: purchase_id)
      return nil unless purchase
      return nil unless context[:current_user]&.id == purchase.user_id || context[:current_user]&.is_admin?
      purchase
    end

    field :my_vps, [Types::VpsType], null: true, description: "VPS of current user"
    def my_vps
      return [] unless context[:current_user]
      context[:current_user].vps
    end

    field :vps, Types::VpsType, null: true, description: "VPS by ID" do
      argument :id, ID, required: true
    end
    def vps(id:)
      vps = Vps.find_by(id: id)
      return nil unless vps
      return nil unless context[:current_user]&.id == vps.user_id || context[:current_user]&.is_admin?
      vps
    end

    field :my_payments, [Types::PaymentType], null: true, description: "Payments of current user"
    def my_payments
      return [] unless context[:current_user]
      context[:current_user].payments.order(payment_date: :desc)
    end

    field :payment, Types::PaymentType, null: true, description: "Payment by ID" do
      argument :id, ID, required: true
    end
    def payment(id:)
      payment = Payment.find_by(id: id)
      return nil unless payment
      return nil unless context[:current_user]&.id == payment.user_id || context[:current_user]&.is_admin?
      payment
    end

    field :balance_due, Float, null: false, description: "Balance due for current user"
    def balance_due
      return 0 unless context[:current_user]
      context[:current_user].balance_due
    end

    field :dashboard, Types::DashboardType, null: true, description: "Dashboard aggregation data"
    def dashboard
      return nil unless context[:current_user]
      user = context[:current_user]
      {
        total_balance: user.mt5_accounts.sum(:balance).round(2),
        total_profits: user.total_profits.round(2),
        total_commission_due: user.total_commission_due.round(2),
        total_credits: user.total_credits.round(2),
        balance_due: user.balance_due.round(2),
        accounts_count: user.mt5_accounts.count,
        bots_count: user.bot_purchases.count,
        active_bots_count: user.bot_purchases.where(status: 'active').count,
        recent_trades_count: user.trades.where("close_time >= ?", 24.hours.ago).count
      }
    end

    field :stats, Types::StatsType, null: true, description: "Global statistics" do
      argument :period, String, required: false, default_value: "30_days"
      argument :bot_id, ID, required: false
      argument :account_id, ID, required: false
    end
    def stats(period: "30_days", bot_id: nil, account_id: nil)
      return nil unless context[:current_user]
      user = context[:current_user]

      date_range = case period
      when "7_days" then 7.days.ago..Time.current
      when "30_days" then 30.days.ago..Time.current
      when "3_months" then 3.months.ago..Time.current
      when "6_months" then 6.months.ago..Time.current
      when "1_year" then 1.year.ago..Time.current
      else 30.days.ago..Time.current
      end

      scope = user.trades.where(close_time: date_range)
      scope = scope.where(mt5_account_id: account_id) if account_id.present?

      if bot_id.present?
        bot = TradingBot.find_by(id: bot_id)
        scope = scope.where(magic_number: bot.magic_number_prefix) if bot&.magic_number_prefix
      end

      trades = scope.to_a
      return nil if trades.empty?

      winning_trades = trades.select { |t| t.profit > 0 }
      losing_trades = trades.select { |t| t.profit < 0 }

      {
        total_profit: trades.sum(&:profit).round(2),
        total_trades: trades.count,
        winning_trades: winning_trades.count,
        losing_trades: losing_trades.count,
        win_rate: trades.any? ? (winning_trades.count.to_f / trades.count * 100).round(2) : 0,
        average_profit: trades.any? ? (trades.sum(&:profit) / trades.count).round(2) : 0,
        best_trade: trades.any? ? trades.max_by(&:profit)&.profit : nil,
        worst_trade: trades.any? ? trades.min_by(&:profit)&.profit : nil,
        total_commission: trades.sum { |t| t.commission || 0 }.round(2),
        total_swap: trades.sum { |t| t.swap || 0 }.round(2)
      }
    end

    field :monthly_profits, GraphQL::Types::JSON, null: true, description: "Monthly profits" do
      argument :months, Integer, required: false, default_value: 12
    end
    def monthly_profits(months: 12)
      return nil unless context[:current_user]
      user = context[:current_user]
      start_date = months.months.ago.beginning_of_month

      (0...months).map do |i|
        month_start = (start_date + i.months).beginning_of_month
        month_end = month_start.end_of_month
        month_trades = user.trades.where(close_time: month_start..month_end)
        {
          month: month_start.strftime("%Y-%m"),
          profit: month_trades.sum(&:profit).round(2),
          trades_count: month_trades.count
        }
      end
    end

    field :trades_by_day, GraphQL::Types::JSON, null: true, description: "Trades grouped by day of week"
    def trades_by_day
      return nil unless context[:current_user]
      user = context[:current_user]
      trades = user.trades.where.not(close_time: nil).to_a

      days_map = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']
      by_day = trades.group_by { |t| t.close_time&.wday }

      by_day.map do |wday, day_trades|
        {
          day_name: days_map[wday],
          wday: wday,
          total_trades: day_trades.count,
          total_profit: day_trades.sum { |t| t.profit || 0 }.round(2),
          winning_trades: day_trades.count { |t| (t.profit || 0) > 0 },
          losing_trades: day_trades.count { |t| (t.profit || 0) < 0 }
        }
      end
    end

    field :trades_by_hour, GraphQL::Types::JSON, null: true, description: "Trades grouped by hour"
    def trades_by_hour
      return nil unless context[:current_user]
      user = context[:current_user]
      trades = user.trades.where.not(close_time: nil).to_a

      by_hour = trades.group_by { |t| t.close_time&.hour }

      by_hour.map do |hour, hour_trades|
        {
          hour: hour,
          total_trades: hour_trades.count,
          total_profit: hour_trades.sum { |t| t.profit || 0 }.round(2),
          winning_trades: hour_trades.count { |t| (t.profit || 0) > 0 },
          losing_trades: hour_trades.count { |t| (t.profit || 0) < 0 }
        }
      end.sort_by { |h| h[:hour] }
    end
  end
end
