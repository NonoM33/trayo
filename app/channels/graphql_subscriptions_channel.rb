class GraphqlSubscriptionsChannel < ApplicationCable::Channel
  def subscribed
    @subscription_id = SecureRandom.uuid
    stream_from "graphql_subscriptions:#{@subscription_id}"
  end

  def unsubscribed
    TrayoSchema.subscriptions.delete_subscription(@subscription_id)
  end

  def execute(data)
    result = TrayoSchema.subscriptions.execute(
      data["query"],
      context: context,
      variables: data["variables"] || {},
      operation_name: data["operationName"]
    )

    transmit({
      result: result.to_h,
      more: result.subscription?
    })
  end

  private

  def context
    {
      current_user: current_user,
      subscription_id: @subscription_id
    }
  end
end

