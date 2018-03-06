require 'spec_helper'


describe Spree::Order do
  let(:user) { stub_model(Spree::LegacyUser, :email => "spree@example.com") }
  let(:order) { stub_model(Spree::Order, :user => user) }
  let(:line_items) {[
    FactoryGirl.create(:line_item),
    FactoryGirl.create(:line_item, interval: 2, variant: FactoryGirl.create(:subscribable_variant))
  ]}

  it { should respond_to(:repeat_order?) }

  context "#finalize!" do
    let(:order) { create(:order) }

    context "with an ineligible order" do
      before do
        order.stub(:subscribable?).and_return(false)
        order.stub(:repeat_order?).and_return(false)
      end

      it "finalizes the order" do
        order.should_receive(:finalize_without_create_subscription!)

        order.finalize!
      end

      it "doesn't create a subscription" do
        order.finalize!

        expect(order.subscriptions).to be_empty
      end
    end

    context "with an eligible order" do
      before do
        order.line_items << line_items
        order.finalize!
      end

      it "can return a list of line items being subscribed to" do
        expect(order.subscribable_line_items.count).to eq(1)
      end

      it "creates a subscription and attaches it to the order" do
        expect(order.subscriptions).not_to be_nil
      end

      it "does not set the repeat_order flag" do
        order.reload
        expect(order.repeat_order).to be false
      end
    end

    context "with a subscription" do
      it "requires a user" do
        valid_order = order
        invalid_order = FactoryGirl.create(:completed_order_with_totals, user_id: nil)

        valid_order.finalize!
        invalid_order.finalize!

        expect(order.subscriptions).to_not be_nil
        expect(invalid_order.subscriptions).to be_empty
      end
    end
  end

  context "Subscription Interval" do
    it "returns the interval of the last subscription" do
      first = create(:subscription, interval: 3)
      last = create(:subscription, interval: 12)
      order = create(:order, subscriptions: [first, last])

      expect(order.subscription_interval).to eq(12)
    end

    it "returns 4 weeks if it doesn't have previous subscriptions" do
      order = create(:order, subscriptions: [])

      expect(order.subscription_interval).to eq(1)
    end
  end

end
