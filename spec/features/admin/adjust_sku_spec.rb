require 'spec_helper'
require 'shared/context/adjust_sku_context.rb'

describe "Subscription Adjust Sku", type: :feature do
  include_context "setup subscriptions for adjusting skus"
  stub_authorization!

  context "Adjust SKU page", js: true do
    it "can update the sku's of subscription items to a new sku" do
      visit "/admin/subscriptions/adjust_sku"

      fill_in("old_sku", with: "GPM100")
      fill_in("new_sku", with: "GPM100-2")
      click_button("Adjust SKU")

      expect(@subscription.subscription_items.first.variant.sku).to eq("GPM100-2")
      expect(page).to have_content(@subscription.id)
      expect(page).to have_content(@subscription.email)
      expect(page).to have_content(@subscription.last_completed_order.number)
    end
  end

  context "renewed subscriptions" do
    it "subscription items have the new sku" do
      AdjustSkuService.new.update_subscriptions("GPM100", "GPM100-2")

      visit spree.admin_path
      visit "/admin/subscriptions/#{@subscription.id}/edit"

      click_link("Renew Now")

      expect(@subscription.subscription_items.first.variant.sku).to eq("GPM100-2")
    end
  end

end
