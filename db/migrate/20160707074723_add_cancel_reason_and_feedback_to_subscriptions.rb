class AddCancelReasonAndFeedbackToSubscriptions < ActiveRecord::Migration
  def change
    add_column :spree_subscriptions, :cancel_reasons, :text, array: true, default: []
    add_column :spree_subscriptions, :cancel_feedback, :text
  end
end
