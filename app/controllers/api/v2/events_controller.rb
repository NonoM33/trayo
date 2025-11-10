module Api
  module V2
    class EventsController < BaseController
      include ActionController::Live

      def index
        response.headers['Content-Type'] = 'text/event-stream'
        response.headers['Cache-Control'] = 'no-cache'
        response.headers['X-Accel-Buffering'] = 'no'

        channels = params[:channels]&.split(',')&.map(&:strip) || ['account', 'trade', 'bot', 'payment']
        user_id = current_user.id

        # Send initial connection message
        response.stream.write("data: {\"type\":\"connected\",\"channels\":#{channels.to_json}}\n\n")

        # Use Action Cable's pubsub adapter
        cable_adapter = ActionCable.server.config.cable
        pubsub = ActionCable.server.pubsub

        channel_names = channels.map do |channel|
          case channel
          when 'account'
            "account_channel_#{user_id}"
          when 'trade'
            "trade_channel_#{user_id}"
          when 'bot'
            "bot_channel_#{user_id}"
          when 'payment'
            "payment_channel_#{user_id}"
          end
        end.compact

        subscriptions = channel_names.map { |name| pubsub.subscribe(name) { |data| broadcast_event(data) } }

        # Keep connection alive
        loop do
          sleep 1
          response.stream.write(": heartbeat\n\n")
        end
      rescue IOError, ClientDisconnected
        # Client disconnected
      ensure
        subscriptions&.each(&:unsubscribe) if subscriptions
        response.stream.close
      end

      private

      def broadcast_event(data)
        response.stream.write("data: #{data.to_json}\n\n")
      rescue IOError
        # Client disconnected
      end
    end
  end
end

