module Spree
  class OrderSubscription < Spree::Base
    self.table_name = :spree_orders_subscriptions
    belongs_to :order
    belongs_to :subscription
  end
end
