require 'spec_helper'
require 'shared/context/adjust_sku_context.rb'

describe "Subscription Failures", type: :feature do
  let!(:subscription) { FactoryGirl.create(:subscription, state: 'renewing', failure_count: 1) }
  stub_authorization!

  before do
    visit spree.failures_admin_subscriptions_path
  end

  context "admin subscription renewal failures", js: true do
    it "shows the failed subscriptions" do
      expect(page).to have_content('renewing')
    end
  end
end
