class AdjustSkuService

	def update_subscriptions(old_sku, new_sku)
    old_variant = Spree::Variant.find_by(sku: old_sku)
    new_variant = Spree::Variant.find_by(sku: new_sku)
    subscriptions = []
    items = subscription_items(old_variant)
    items.each do |item|
      next if item.subscription.cancelled_at
      item.update_column(:variant_id, new_variant.id)
      subscriptions << item.subscription
    end
    subscriptions
  end

  def subscription_items(variant)
    subscription_items = Spree::SubscriptionItem.where(variant_id: variant.id)
  end
end
