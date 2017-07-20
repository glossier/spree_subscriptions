class AddRenewalDatesToSubscriptions < ActiveRecord::Migration
  def change
    add_column :spree_subscriptions, :next_renewal_at, :datetime
    add_column :spree_subscriptions, :last_renewal_at, :datetime

    Spree::Subscription.active.each do |subscription|
      subscription.update_column(:last_renewal_at,
        subscription.last_completed_order.completed_at)
      subscription.touch
    end
  end
end
