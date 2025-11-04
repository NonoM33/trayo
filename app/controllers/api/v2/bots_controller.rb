module Api
  module V2
    class BotsController < BaseController
      before_action :set_bot, only: [:show]

      def index
        bots = TradingBot.active
        bots = apply_filters(bots, allowed_filters: {
          status: {},
          risk_level: {},
          price: { gt: true, lt: true, gte: true, lte: true }
        })

        paginated = paginate_with_cursor(bots, cursor_field: :id)

        render_success({
          data: paginated[:data].map { |b| bot_serializer(b) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ bot: bot_serializer(@bot) })
      end

      def my_bots
        purchases = current_user.bot_purchases.where(status: 'active')
        paginated = paginate_with_cursor(purchases, cursor_field: :id)

        render_success({
          data: paginated[:data].map { |p| bot_purchase_serializer(p) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      private

      def set_bot
        @bot = TradingBot.find_by(id: params[:id])
        render_error("Bot not found", status: :not_found) unless @bot
      end

      def bot_serializer(bot)
        {
          id: bot.id,
          name: bot.name,
          description: bot.description,
          price: bot.price,
          status: bot.status,
          is_active: bot.is_active,
          risk_level: bot.risk_level,
          magic_number_prefix: bot.magic_number_prefix,
          max_drawdown_limit: bot.max_drawdown_limit,
          projection_monthly_min: bot.projection_monthly_min,
          projection_monthly_max: bot.projection_monthly_max,
          projection_yearly: bot.projection_yearly,
          win_rate: bot.win_rate,
          features: bot.features,
          projected_monthly_average: bot.projected_monthly_average,
          risk_badge_color: bot.risk_badge_color,
          risk_label: bot.risk_label,
          created_at: bot.created_at,
          updated_at: bot.updated_at
        }
      end

      def bot_purchase_serializer(purchase)
        {
          id: purchase.id,
          price_paid: purchase.price_paid,
          status: purchase.status,
          is_running: purchase.is_running,
          magic_number: purchase.magic_number,
          total_profit: purchase.total_profit,
          trades_count: purchase.trades_count,
          current_drawdown: purchase.current_drawdown,
          max_drawdown_recorded: purchase.max_drawdown_recorded,
          started_at: purchase.started_at,
          stopped_at: purchase.stopped_at,
          roi_percentage: purchase.roi_percentage,
          days_active: purchase.days_active,
          average_daily_profit: purchase.average_daily_profit,
          is_profitable: purchase.is_profitable?,
          within_drawdown_limit: purchase.within_drawdown_limit?,
          status_badge: purchase.status_badge,
          status_color: purchase.status_color,
          trading_bot: {
            id: purchase.trading_bot.id,
            name: purchase.trading_bot.name,
            description: purchase.trading_bot.description
          }
        }
      end
    end
  end
end

