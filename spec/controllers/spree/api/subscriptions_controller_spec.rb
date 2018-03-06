require 'spec_helper'
include SubscriptionMacros

module Spree
  describe Api::SubscriptionsController, type: :controller do
    render_views

    let(:current_api_user) do
      user = Spree.user_class.new(email: "spree@example.com", password: 'dynamo1234')
      user.generate_spree_api_key!
      user
    end

    before do
      setup_subscriptions_for current_api_user
      @subscription = current_api_user.subscriptions.last
      stub_authentication!
    end

    it "restricts access to subscriptions" do
      @subscription.update_column(:user_id, 999)
      response = api_get :show, id: @subscription.id

      expect(response[:id]).to be nil
    end

    it "should allow the owner of the subscription to access it" do
      api_get :show, id: @subscription.id
      expect(json_response[:id]).to be @subscription.id
    end

    context "skipping" do
      it "should skip next order" do
        expect(next_shipment_date).to eql original_shipment_date

        api_get :skip_next_order, id: @subscription.id
        expect(next_shipment_date).to eql next_calc_shipment_date
      end

      it "should be able to undo a skip next order" do
        @subscription.skip_next_order
        expect(next_shipment_date).to eql next_calc_shipment_date

        api_get :undo_skip_next_order, id: @subscription.id
        expect(next_shipment_date).to eql original_shipment_date
      end
    end

    it "should be able to cancel a subscription" do
      api_put :cancel, id: @subscription.id
      @subscription.reload

      expect(@subscription.state).to eq 'cancelled'
      expect(@subscription.can_renew?).to be false
    end

    it "should be able to pause a subscription" do
      api_put :pause, id: @subscription.id
      @subscription.reload

      expect(@subscription.state).to eq 'paused'
      expect(@subscription.can_renew?).to be false
    end

    it "should be able to resume after pausing" do
      @subscription.pause
      expect(@subscription.state).to eq 'paused'

      api_put :resume, id: @subscription.id
      @subscription.reload

      expect(@subscription.state).to eq 'active'
      expect(@subscription.can_renew?).to be true
    end

    it "should create a billing address" do
      billing_address = FactoryGirl.create(:subscription_address)

      api_post :create_address, id: @subscription.id, address: billing_address.attributes, attribute: 'billing_address'

      expect(@subscription.reload.billing_address.id).to be json_response[:id]
    end

    it "should create a shipping address" do
      shipping_address = FactoryGirl.create(:subscription_address)

      api_post :create_address, id: @subscription.id, address: shipping_address.attributes, attribute: 'shipping_address'

      expect(@subscription.reload.shipping_address.id).to be json_response[:id]
    end

    it "should update an address" do
      updated_shipping_address = @subscription.shipping_address
      updated_shipping_address.firstname = 'new'
      updated_shipping_address.lastname = 'new'
      updated_shipping_address.address1 = '1 new address'
      updated_shipping_address.zipcode = '90000'

      api_post :update_address, id: @subscription.id, address: updated_shipping_address.attributes, attribute: 'shipping_address'

      @subscription.reload
      expect(@subscription.shipping_address.firstname).to eq json_response[:firstname]
      expect(@subscription.shipping_address.lastname).to eq json_response[:lastname]
      expect(@subscription.shipping_address.address1).to eq json_response[:address1]
      expect(@subscription.shipping_address.zipcode).to eq json_response[:zipcode]
    end

    it "should select an existing address" do
      # create a new shipping address for the subscription
      new_shipping_address = FactoryGirl.create(:subscription_address)
      existing_shipping_address = @subscription.shipping_address

      api_post :create_address, id: @subscription.id, address: new_shipping_address.attributes, attribute: 'shipping_address'

      expect(@subscription.reload.shipping_address.id).to be json_response[:id]

      # now select the previous shipping address
      api_post :select_address, id: @subscription.id, address_id: existing_shipping_address.id, attribute: 'shipping_address'

      expect(@subscription.reload.shipping_address.id).to be existing_shipping_address.id
    end
  end
end
