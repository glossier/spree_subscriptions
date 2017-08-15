require 'spec_helper'

describe Spree::Subscription do
  include OrderMacros

  it { should have_and_belong_to_many(:orders) }
  it { should belong_to(:user) }
  it { should belong_to(:credit_card)}
  it { should respond_to(:resume_on)}

  context "#products" do
    it 'should return a collection of products' do
      create_completed_subscription_order
      @order.subscriptions.last.products.map(&:subscribable?).all?.should be true
    end
  end

  context "#credit_card" do
    before do
      create_completed_subscription_order
    end

    it "should be automatically associated with a credit card when the initial order is completed" do
      expect(@order.subscriptions.last.credit_card).not_to be_nil
    end
  end

  context "shipment dates" do
    before do
      Timecop.freeze
      create_completed_subscription_order
    end

    it "should return the shipment date of the last order" do
      @order.subscriptions.last.last_shipment_date.to_i.should == Time.now.to_i
    end

    it "should be able to calculate the date of the next shipment" do
      next_shipment_date.should == original_shipment_date
    end

    after do
      Timecop.return
    end
  end

  context "skipping orders" do
    before do
      Timecop.freeze
      create_completed_subscription_order

      @order.subscriptions.last.skip_next_order
    end

    it "should calculate the correct next shipment date if user decides to skip" do
      next_shipment_date.should == next_calc_shipment_date
    end

    it "should fall back to the original shipment date after undoing" do
      @order.subscriptions.last.undo_skip_next_order
      next_shipment_date.should == original_shipment_date
    end
  end

  context "shipment" do
    before do
      create_completed_subscription_order
    end

    it "should have a shipment" do
      expect(@order.subscriptions.last.shipment).not_to be_nil
    end

    it "should have a shipping method" do
      expect(@order.subscriptions.last.shipping_method).not_to be_nil
    end
  end

  # context "#prepaid" do
  #   before do
  #     create_completed_subscription_order
  #   end
  #
  #   it "should know if it's been paid for in advance" do
  #     @order.subscription.prepaid?.should be false
  #   end
  #
  #   it "should know if it has a prepaid balance remaining" do
  #     @order.subscription.prepaid_balance_remaining?.should be false
  #   end
  #
  #   it "should be set to prepaid when a prepaid order is submitted" do
  #     create_completed_prepaid_subscription_order
  #     @order.subscribable?.should be true
  #     @order.subscription.duration.should == 6
  #     @order.subscription.interval.should == 4
  #     @order.subscription.prepaid?.should be true
  #   end
  # end

  describe "#cancelled?" do
    let(:subscription) { FactoryGirl.create(:subscription, state: subscription_state) }

    context "when the subscription has been cancelled" do
      let(:subscription_state) { 'cancelled' }

      it "returns true" do
        expect(subscription.cancelled?).to be true
      end
    end

    context "when the subscription has not been cancelled" do
      let(:subscription_state) { 'active' }

      it "returns false" do
        expect(subscription.cancelled?).to be false
      end
    end
  end

  describe "#cancel!" do
    let(:subscription) { FactoryGirl.create(:subscription, state: :active) }

    it "cancels the subscription" do
      expect {
        subscription.cancel!
      }.to change {
        subscription.state
      }.from('active').to('cancelled')
    end
  end

  describe "#pause" do
    let(:subscription) { FactoryGirl.create(:subscription) }
    it "pause the subscription" do
      expect {
        subscription.pause
      }.to change {
        subscription.state
      }.from('active').to('paused')
    end
  end

  describe "#resume" do
    let(:subscription) { FactoryGirl.create(:subscription, state: 'paused') }
    it "resumes the subscription" do
      expect {
        subscription.resume
      }.to change {
        subscription.state
      }.from('paused').to('active')
    end

    it "resumes the subscription if the resume date is today" do
      expect {
        subscription.resume(Time.now)
      }.to change {
        subscription.state
      }.from('paused').to('active')
    end

    it "resumes the subscription for past resume date" do
      expect {
        subscription.resume(Time.now - 1.month)
      }.to change {
        subscription.state
      }.from('paused').to('active')
    end

    it "keeps the subscription paused for future resume date" do
        expect {
          subscription.resume(Time.now + 1.month)
        }.to_not change {
          subscription.state
        }
    end

    it "lists subscriptions that are due to be resumed today" do
      scheduled_to_be_resumed = create_subscriptions([
        { state: :paused, resume_at: Time.now - 1.day },
        { state: :paused, resume_at: Time.now }
      ])
      others = create_subscriptions([
        { state: :active, resume_at: Time.now - 6.months },
        { state: :paused, resume_at: Time.now + 1.day }
      ])

      to_resume = Spree::Subscription.ready_to_resume

      expect(to_resume).to eq(scheduled_to_be_resumed)
    end

    def create_subscriptions(subscriptions_attr)
      subscriptions = []
      subscriptions_attr.each { |attributes| subscriptions << FactoryGirl.create(:subscription, attributes) }
      subscriptions.each(&:save!)
      subscriptions
    end
  end

  context '#create_next_order!' do
    let(:second_store) { create(:store) }

    before do
      create_completed_subscription_order

      subscription.last_order.update_column(:currency, 'CAD')
      subscription.last_order.update_column(:store_id, second_store.id)
    end

    it "has the last order's currency and store" do
      subscription.create_next_order!

      expect(subscription.last_order.currency).to eq 'CAD'
      expect(subscription.last_order.store_id).to eq second_store.id
    end
  end

  describe "can_renew?" do
    let(:subscription) { FactoryGirl.create(:subscription) }

    context "completed order with subscription" do
      before do
        create_completed_subscription_order
      end

      it "can renew if subscription is active and has an interval" do
        expect(@order.subscriptions.last.can_renew?).to be_truthy
      end
    end

    it "cannot renew if subscription is paused" do
      subscription.pause

      expect(subscription.can_renew?).to be_falsey
    end

    it "cannot renew if subscription is cancelled" do
      subscription.cancel

      expect(subscription.can_renew?).to be_falsey
    end

    it "cannot renew if subscription does not have an interval" do
      subscription.update_column(:interval, 0)
      expect(subscription.can_renew?).to be_falsey

      subscription.update_column(:interval, nil)
      expect(subscription.can_renew?).to be_falsey
    end
  end

end
