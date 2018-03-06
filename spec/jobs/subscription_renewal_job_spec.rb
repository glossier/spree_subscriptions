require 'spec_helper'

describe SubscriptionRenewalJob do
  include SubscriptionMacros

  let(:user) { create(:user) }

  before(:each) do
    setup_subscriptions_for user
  end

  it "renews a subscription with a new order" do
    subscription = user.subscriptions.first

    expect(user.orders.count).to eq(1)

    SubscriptionRenewalJob.new.perform(subscription.id)

    expect(user.orders.count).to eq(2)
  end
end
