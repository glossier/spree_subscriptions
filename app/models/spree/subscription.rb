module Spree
  class Subscription < ActiveRecord::Base
    include SubscriptionStateMachine

    has_many :subscription_items, dependent: :destroy, inverse_of: :subscription
    has_and_belongs_to_many :orders, join_table: :spree_orders_subscriptions, after_add: :set_email
    belongs_to :user
    belongs_to :credit_card
    alias_attribute :items, :subscription_items

    belongs_to :bill_address, foreign_key: :bill_address_id, class_name: 'Spree::SubscriptionAddress'
    alias_attribute :billing_address, :bill_address

    belongs_to :ship_address, foreign_key: :ship_address_id, class_name: 'Spree::SubscriptionAddress'
    alias_attribute :shipping_address, :ship_address

    has_many :subscription_skips, dependent: :destroy, inverse_of: :subscription
    alias_attribute :skips, :subscription_skips

    accepts_nested_attributes_for :ship_address
    accepts_nested_attributes_for :bill_address

    validates_presence_of :ship_address
    validates_presence_of :bill_address
    validates_presence_of :user

    after_save :reset_failure_count, if: :credit_card_id_changed?
    after_create :mark_last_renewal!
    after_touch :adjust_next_renewal!

    class << self
      def active
        where(state: 'active')
      end

      def paused
        where(state: 'paused')
      end

      def with_interval
        where('interval > 0')
      end

      def prepaid
        where(prepaid: true)
      end

      def good_standing
        where('failure_count < 6')
      end

      def ready_for_next_order
        subscriptions = active.with_interval.good_standing.select do |subscription|
          next unless subscription.last_completed_order
          next if subscription.prepaid?
          subscription.next_shipment_date.to_date <= Date.today
        end

        where(id: subscriptions.collect(&:id))
      end

      def ready_to_resume
        where(["state = ? and resume_at <= ?", :paused, Time.now])
      end
    end

    def products
      subscription_items.map(&:variant)
    end

    def last_shipment_date
      last_completed_order.completed_at if last_completed_order
    end

    def next_shipment_date
      next_renewal_at
    end

    def calc_next_renewal_date
      { weeks: interval }
    end

    def active?
      %w(active renewing).include? state
    end

    def last_order
      orders.reorder('created_at desc').first
    end

    def last_completed_order
      completed_orders.reorder('completed_at desc').first
    end

    def last_order_credit_card
      last_completed_order.payments.where('amount > 0').where(state: 'completed').last.source
    end

    def last_order_date
      last_completed_order ? last_completed_order.completed_at : last_order.created_at
    end

    def next_order
      next_order = NullObject.new

      next_order.class_eval do
        def created_at
          '???'
        end
      end

      next_order
    end

    def create_next_order!
      # just keeping safe
      non_existing_attributes = Spree::SubscriptionAddress.dup.attribute_names - Spree::Address.attribute_names
      # use subscription's addresses for the new order and email
      created_order = orders.create!(
        user: last_completed_order.user,
        repeat_order: true,
        bill_address: Spree::Address.new(bill_address.dup.attributes.except(*non_existing_attributes)),
        ship_address: Spree::Address.new(ship_address.dup.attributes.except(*non_existing_attributes)),
        channel: 'subscription',
        store: last_completed_order.store,
        currency: last_completed_order.currency
      )
      created_order
    end

    def prepaid?
      false
    end

    def eligible_for_processing?
      active? && (!prepaid? || duration > 1)
    end

    def prepaid_balance_remaining?
      prepaid_amount > 0
    end

    def retry_count
      5 - failure_count
    end

    def increment_failure_count
      update_column(:failure_count, failure_count + 1)
    end

    def reset_failure_count
      update_column(:failure_count, 0)
    end

    def skip_next_order
      skips.create(skip_at: next_shipment_date) if can_skip?
    end

    def undo_skip_next_order
      last_skip.update_attribute(:undo_at, Time.now) if skipping?
    end

    def skip_order_at
      last_skip.skip_at if skipping?
    end

    def last_skip
      skips.last if skips.any? && skips.last.undo_at.nil? && skips.last.renewed_at.nil?
    end

    alias_attribute :skipping?, :last_skip

    def can_skip
      # only allow skipping after date has pass
      skipping? ? Date.today >= skip_order_at.to_date : true
    end

    def clear_skip_order
      last_skip.update_attribute(:renewed_at, Date.today) if skipping?
    end

    alias_attribute :can_skip?, :can_skip

    def completed_orders
      orders.complete
    end

    # fetch the last completed order shipment
    def shipment
      last_completed_order.shipments.last
    end

    # fetch the last completed order shipping method
    def shipping_method
      shipment.shipping_method
    end

    def failed_last_renewal?
      !orders.first.complete?
    end

    def can_renew?
      !(interval.nil? || interval.zero?) && !cancelled? && !paused?
    end

    def add_new_credit_card(params)
      ::Spree::CreditCard.transaction do
        credit_card = user.credit_cards.create(params)
        update_column(:credit_card_id, credit_card.id)

        CardStore.store_card_for_user(user, credit_card, credit_card.verification_value)
      end
    end

    def subscription_log_for(order)
      ::SubscriptionLog.where(order_id: order.id).last
    end

    def as_json(options = { })
      super((options || { }).merge({
          :methods => [:next_shipment_date, :skip_order_at]
      }))
    end

    private

    def mark_last_renewal!
      touch(:last_renewal_at)
    end

    def adjust_next_renewal!
      return if renewing?

      update_column(:next_renewal_at,
        last_renewal_at.advance(calc_next_renewal_date))
    end

    def set_email(new_order)
      # use the subscription's email if present vs last order's
      new_order.update_column(:email, email) if email
    end
  end
end
