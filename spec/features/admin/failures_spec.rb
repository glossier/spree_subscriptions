require 'spec_helper'

describe "Subscription Failures", type: :feature do
  stub_authorization!
  
  let!(:failed_subscription) { FactoryGirl.create(:subscription, state: 'renewing', failure_count: 1) }
  let!(:cancelled_subscription) { FactoryGirl.create(:subscription, state: 'cancelled', failure_count: 1) }
  let!(:active_subscription) { FactoryGirl.create(:subscription) }

  before do
    visit spree.failures_admin_subscriptions_path
  end

  context "admin subscription renewal failures", js: true do
    it "shows the only subscription that failed renewing" do
      expect(page).not_to have_content('active')
      expect(page).not_to have_content('cancelled')
      
      expect(page).to have_content('renewing')
    end
  end
end
