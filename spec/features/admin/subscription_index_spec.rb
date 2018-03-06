require 'spec_helper'
require 'shared/context/adjust_sku_context.rb'

describe "Subscription Adjust Sku", type: :feature do
  include_context "setup subscriptions for adjusting skus"
  stub_authorization!

  before do
    visit spree.admin_subscriptions_path
  end

  context "admin subscriptions index page", js: true do
    it "users can filter subscriptions by the SKU of their items" do
      fill_in("q[subscription_items_variant_sku_eq]", with: "GPM100")

      click_button('Filter Results')

      expect(page).to have_content(@subscription.id)
      expect(page).to have_content(@subscription.email)
      expect(page).to have_content(@subscription.orders.first.number)
    end

    it "users can filter by state" do
      @subscription.update_column(:state, 'renewing')

      select("Renewing", from: "q[state_eq]")
      click_button('Filter Results')
      
      expect(page).to have_content('renewing')
    end
  end
end
