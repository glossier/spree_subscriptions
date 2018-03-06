class SubscriptionItemSerializer < ActiveModel::Serializer
  extend Spree::Api::ApiHelpers
  cached
  delegate :cache_key, to: :object

  attributes :id, :quantity, :price

  attributes :variant

  def variant
    variant = object.variant
    {
      id: variant.id,
      name: variant.product.name,
      options_text: variant.options_text
    }
  end
end
