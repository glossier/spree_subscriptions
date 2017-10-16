class AddAddress3ToSubscriptionAddresses < ActiveRecord::Migration
  def change
    add_column :spree_subscription_addresses, :address3, :string, limit: 255
  end
end
