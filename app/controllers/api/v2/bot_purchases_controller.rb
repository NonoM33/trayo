module Api
  module V2
    class BotPurchasesController < BaseController
      before_action :set_purchase, only: [:show, :status, :start, :stop, :performance]

      def index
        purchases = current_user.bot_purchases
        paginated = paginate_with_cursor(purchases, cursor_field: :id)

        render_success({
          data: paginated[:data].map { |p| bot_purchase_serializer(p) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ bot_purchase: bot_purchase_serializer(@purchase) })
      end

      def create
        bot = TradingBot.find_by(id: params[:bot_id])
        return render_error("Bot not found", status: :not_found) unless bot
        return render_error("Bot is not active", status: :unprocessable_entity) unless bot.status == 'active'

        existing_purchase = current_user.bot_purchases.find_by(trading_bot: bot, status: 'active')
        if existing_purchase
          return render_success({ bot_purchase: bot_purchase_serializer(existing_purchase) })
        end

        purchase = current_user.bot_purchases.build(
          trading_bot: bot,
          price_paid: bot.price,
          status: 'active',
          is_running: false
        )

        if purchase.save
          render_success({ bot_purchase: bot_purchase_serializer(purchase) }, status: :created)
        else
          render_error(purchase.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      def status
        render_success({ bot_purchase: bot_purchase_serializer(@purchase) })
      end

      def start
        @purchase.start!
        render_success({ bot_purchase: bot_purchase_serializer(@purchase.reload) })
      end

      def stop
        @purchase.stop!
        render_success({ bot_purchase: bot_purchase_serializer(@purchase.reload) })
      end

      def performance
        profit = params[:profit]&.to_f
        drawdown = params[:drawdown]&.to_f || 0

        return render_error("Profit is required", status: :unprocessable_entity) unless profit

        @purchase.update_performance(profit, drawdown)
        render_success({ bot_purchase: bot_purchase_serializer(@purchase.reload) })
      end

      private

      def set_purchase
        @purchase = current_user.bot_purchases.find_by(id: params[:id])
        render_error("Bot purchase not found", status: :not_found) unless @purchase
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
            description: purchase.trading_bot.description,
            risk_level: purchase.trading_bot.risk_level
          }
        }
      end
    end
  end
end

