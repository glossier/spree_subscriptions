class AddEmailToSubscriptions < ActiveRecord::Migration
  def up
    add_column :spree_subscriptions, :email, :string, default: nil

    Spree::Subscription.active.each do |subscription|
      subscription.update_column(:email, subscription.last_completed_order.email)
    end
  end

  def down
    remove_column :spree_subscriptions, :email
  end
end
