class CreateSubscriptionJob < ActiveJob::Base
  queue_as :default

  def perform(order_id)
    begin
      order = Spree::Order.find(order_id)
      create_subscription_from_eligible_items(order)
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace
    end
  end

protected

  def create_subscription_from_eligible_items(order)
    user = order.user
    line_items = eligible_line_items(order)
    line_items.keys.each do |interval|
      attrs = {
        user_id: user.id,
        email: order.email,
        state: 'active',
        interval: interval,
        credit_card_id: order.credit_card_id_if_available
      }
      subscription = order.subscriptions.new(attrs)
      create_subscription_addresses(order, subscription, user)
      order.subscriptions << subscription
      create_subscription_items(line_items, subscription, interval)
    end
  end

  def eligible_line_items(order)
    @eligible_line_items ||= order.line_items.group_by { |item| item.interval }.reject{ |interval| interval.nil? || interval.zero? }
  end

  def create_subscription_addresses(order, subscription, user)
    non_existing_attributes = Spree::Address.attribute_names - Spree::SubscriptionAddress.dup.attribute_names
    order_ship_address = order.ship_address.dup.attributes.except(*non_existing_attributes)
    order_bill_address = order.bill_address.dup.attributes.except(*non_existing_attributes)

    subscription.create_ship_address!(order_ship_address.merge({user_id: user.id}))
    subscription.create_bill_address!(order_bill_address.merge({user_id: user.id}))
  end

  def create_subscription_items(eligible_line_items, subscription, interval)
    eligible_line_items[interval].each do |line_item|
      next unless line_item.product.subscribable?
      Spree::SubscriptionItem.create!(
        subscription: subscription,
        variant: line_item.variant,
        quantity: line_item.quantity,
        interval: interval
      )
    end
  end

end
