class AdjustSkuService

	def update_subscription(old_sku, new_sku)
    variant1 = Spree::Variant.find_by(sku: old_sku)
    variant2 = Spree::Variant.find_by(sku: new_sku)

    subscription_items = Spree::SubscriptionItem.where(variant_id: variant1.id)
    for item in subscription_items
      subscription = item.subscription
      subscription.subscription_items.create!(
        variant_id: variant2.id, quantity: item.quantity, price: item.price, cost_price: item.cost_price, \
        tax_category_id: item.tax_category_id, adjustment_total: item.adjustment_total, additional_tax_total: item.additional_tax_total, \
        promo_total: item.promo_total, included_tax_total: item.included_tax_total, pre_tax_amount: item.pre_tax_amount, interval: item.interval)
      subscription_items.delete(item)
    end
	end

end
