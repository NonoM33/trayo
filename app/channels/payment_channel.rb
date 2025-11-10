class PaymentChannel < ApplicationCable::Channel
  def subscribed
    stream_from "payment_channel_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def self.broadcast_created(payment)
    user = payment.user
    ActionCable.server.broadcast(
      "payment_channel_#{user.id}",
      {
        type: 'payment_created',
        payment: {
          id: payment.id,
          amount: payment.amount,
          status: payment.status,
          payment_date: payment.payment_date,
          description: payment.description,
          payment_method: payment.payment_method
        }
      }
    )
  end
end

