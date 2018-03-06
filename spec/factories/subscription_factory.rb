FactoryGirl.define do
  factory :subscription, :class => Spree::Subscription do
    state 'active'
    interval 2
    next_renewal_at 1.month.from_now
    # prepaid false

    ship_address {
      FactoryGirl.create(:subscription_address)
    }
    bill_address {
      FactoryGirl.create(:subscription_address)
    }

    orders {
      [FactoryGirl.create(:completed_order_with_totals)]
    }

    association(:user)
  end
end
