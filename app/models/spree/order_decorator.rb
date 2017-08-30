module Spree
  module OrderExtensions

    def self.prepended(base)
      base.alias_method_chain :finalize!, :create_subscription
      base.has_and_belongs_to_many :subscriptions, join_table: :spree_orders_subscriptions
      base.register_line_item_comparison_hook(:line_item_interval_match)
    end

    def finalize_with_create_subscription!
      CreateSubscriptionJob.perform_later(self.id) unless user.nil?
      finalize_without_create_subscription!
    end

    def line_item_interval_match(line_item, options)
      return true unless options[:interval].present?
      line_item.interval == options[:interval]
    end

    def subscription_interval
      subscription ? subscription.interval : 1
    end

    def subscription_products
      line_items.group_by { |item| item.interval }.reject{ |interval| interval.zero? }
    end

    def credit_card_id_if_available
      credit_cards.present? ? credit_cards.last.id : ''
    end

    def reset_failure_count_for_subscription
      if completed? && repeat_order?
        subscription.reset_failure_count
      end
    end

    def clear_skip_order_for_subscription
      if completed? && repeat_order?
        subscription.clear_skip_order
      end
    end

    def payment_method
      payments.last.payment_method
    end

    def create_payment!(payment_method, cc)
      payments.create!(
        payment_method: payment_method,
        source: cc,
        amount: update_totals,
        state: 'checkout'
      )
    end

    def subscribable_line_items
      line_items.where('interval > 0')
    end

    # convenience method for displaying internval and true/false in the admin
    def subscription
      subscriptions.last
    end
  end
end

Spree::Order.prepend Spree::OrderExtensions

Spree::Order.state_machine.after_transition to: :complete, do: :reset_failure_count_for_subscription
Spree::Order.state_machine.after_transition to: :complete, do: :clear_skip_order_for_subscription
