class SubscriptionRenewalJob < ActiveJob::Base
  queue_as :default

  def perform(subscription_id)
    subscription = Spree::Subscription.find(subscription_id)
    subscription.renew!

    before_failure_count = subscription.failure_count
    ::GenerateSubscriptionOrder.new(subscription).call

    # check if the failure count has increase, that means we have an error
    if subscription.failure_count > before_failure_count
      failed_order = subscription.orders.reorder('created_at desc').first
      log = SubscriptionLog.find_by_order_id(failed_order.id)
    else
      subscription.renewed!
    end
  end
end
