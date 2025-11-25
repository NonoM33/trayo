module Api
  module V2
    class NotificationsController < BaseController
      def index
        notifications = build_notifications
        paginated = paginate_with_cursor(notifications, cursor_field: :created_at, limit: 50)

        render_success({
          data: paginated[:data],
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more],
          unread_count: notifications.count { |n| !n[:read] }
        })
      end

      def mark_as_read
        notification_ids = params[:notification_ids] || []
        if notification_ids.any?
          render_success({ message: "Notifications marked as read", count: notification_ids.count })
        else
          render_error("No notification IDs provided", status: :unprocessable_entity)
        end
      end

      def unread_count
        notifications = build_notifications
        unread = notifications.count { |n| !n[:read] }
        render_success({ unread_count: unread })
      end

      private

      def build_notifications
        notifications = []

        accounts = current_user.mt5_accounts
        accounts.each do |account|
          if account.balance < account.initial_balance * 0.9
            notifications << {
              id: "account_low_balance_#{account.id}",
              type: "warning",
              title: "Solde faible",
              message: "Le solde du compte #{account.account_name} est en dessous de 90% du solde initial",
              account_id: account.id,
              read: false,
              created_at: account.updated_at
            }
          end

          recent_trades = account.trades.where("close_time >= ?", 24.hours.ago)
          if recent_trades.count > 50
            notifications << {
              id: "account_high_activity_#{account.id}",
              type: "info",
              title: "Activité élevée",
              message: "#{recent_trades.count} trades dans les dernières 24h sur #{account.account_name}",
              account_id: account.id,
              read: false,
              created_at: Time.current
            }
          end
        end

        bot_purchases = current_user.bot_purchases.active
        bot_purchases.each do |purchase|
          if purchase.current_drawdown > purchase.trading_bot.max_drawdown_limit * 0.8
            notifications << {
              id: "bot_high_drawdown_#{purchase.id}",
              type: "warning",
              title: "Drawdown élevé",
              message: "Le bot #{purchase.trading_bot.name} approche de sa limite de drawdown",
              bot_purchase_id: purchase.id,
              read: false,
              created_at: purchase.updated_at
            }
          end

          if purchase.is_running == false && purchase.status == 'active'
            notifications << {
              id: "bot_stopped_#{purchase.id}",
              type: "warning",
              title: "Bot arrêté",
              message: "Le bot #{purchase.trading_bot.name} est arrêté",
              bot_purchase_id: purchase.id,
              read: false,
              created_at: purchase.updated_at
            }
          end
        end

        if current_user.balance_due > 100
          notifications << {
            id: "payment_due",
            type: "info",
            title: "Paiement en attente",
            message: "Vous avez un solde à payer de #{current_user.balance_due.round(2)}$",
            read: false,
            created_at: Time.current
          }
        end

        bonus_deposits = current_user.bonus_deposits.pending
        if bonus_deposits.any?
          notifications << {
            id: "bonus_pending",
            type: "info",
            title: "Bonus en attente",
            message: "Vous avez #{bonus_deposits.count} bonus en attente de validation",
            read: false,
            created_at: Time.current
          }
        end

        notifications.sort_by { |n| n[:created_at] }.reverse
      end
    end
  end
end

