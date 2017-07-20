class GenerateSubscriptionOrder
  include SubscriptionTransitions
  attr_reader :subscription

  class PaymentError < StandardError
  end

  def initialize(subscription)
    @subscription = subscription
  end

  def call
    return false unless @subscription.eligible_for_processing?
    begin
      create_next_order_with_payment
    rescue => error
      log_failure_and_continue(error)
    end
  end

  def create_next_order_with_payment
    previous_order = subscription.last_completed_order

    # create a new order and populate the next order with the same line items
    subscription.subscription_items.each do |line_item|
      next_order.contents.add(line_item.variant, line_item.quantity)
    end

    transition_order_from_cart_to_address!(next_order)
    transition_order_from_address_to_delivery!(next_order)
    transition_order_from_delivery_to_payment!(next_order)

    # else if there is none or store credits were not enough
    ensure_credit_card_has_expiration_month
    next_order.create_payment!(payment_gateway_for_card(credit_card), credit_card)

    transition_order_from_payment_to_complete!(next_order)

    true
  end

  def payment_gateway_for_card(credit_card)
    @eligible_gateways ||= ::Spree::PaymentMethod.where(active: true)
    if credit_card.payment_provider == 'Stripe'
      gateway = @eligible_gateways.where(type: 'Spree::Gateway::StripeGateway').first
    end
    # attempt to use the credit card bogus gateway
    gateway = @eligible_gateways.where(type: 'Spree::Gateway::Bogus').first unless gateway.present?

    gateway.present? ? gateway : @eligible_gateways.first
  end

  def ensure_credit_card_has_expiration_month
    if credit_card.month.nil?
      credit_card.month = 1
      credit_card.year = 2020
      credit_card.save
    end
  end

  def store_credit_card_for_subscription
    subscription.credit_card = subscription.last_order_credit_card
  end

  private

  def log_failure_and_continue(error)
    ::SubscriptionLog.create(order_id: next_order.id, reason: error.to_s)
    subscription.increment_failure_count
  end

  def credit_card
    @credit_card ||= subscription.credit_card || store_credit_card_for_subscription
  end

  def order_populator
    @order_populator ||= ::Spree::OrderPopulator.new(next_order, ::Spree::Config[:currency])
  end

  def next_order
    @next_order ||= subscription.create_next_order!
  end
end
