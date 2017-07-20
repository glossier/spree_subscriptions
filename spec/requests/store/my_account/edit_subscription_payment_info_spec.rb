require "spec_helper"

feature "Editing a subscription payment info", type: :request do
  include SubscriptionMacros

  before(:each) do
    Stripe.api_key = "sk_test_jTiNI1BxjFxBr4TUqdHefc1f"

    user = create(:user)
    setup_subscriptions_for user
    sign_in_as! user

    my_account = MyAccount::Page.new
    @credit_card = my_account.any_subscription.edit.payment_details
  end

  scenario "displays the current payment info" do
    expect(@credit_card.current_payment_info).to_not be_nil
  end

  scenario "can update payment info", :vcr do
    @credit_card.number = "4242424242424242"
    @credit_card.name = "John Doe"
    @credit_card.expiry = "06/20"
    @credit_card.code = "123"

    @credit_card.submit

    expect(@credit_card.current_payment_info).to have_text("4242")
    expect(@credit_card.current_payment_info).to have_text("John Doe")
    expect(@credit_card.current_payment_info).to have_text("6/2020")
  end
end
