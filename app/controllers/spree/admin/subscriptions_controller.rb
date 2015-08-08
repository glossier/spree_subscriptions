module Spree
  module Admin
    class SubscriptionsController < ResourceController
      before_action :require_order_id, only: [:new]

      def new
        order_id = params[:order_id]

        unless order_id.nil?
          order = Spree::Order.find(order_id)
          @subscription = build_subscription_from_order(order)

          # build subscription addresses
          user = order.user
          @subscription.build_ship_address(order.ship_address.dup.attributes.merge({user_id: user.id}))
          @subscription.build_bill_address(order.bill_address.dup.attributes.merge({user_id: user.id}))

          # build items
          build_subscription_items(@subscription, order)
        end
      end

      def create
        subscription = Spree::Subscription.new(params[:subscription].permit!)
        build_subscription_items(subscription, subscription.orders.first)

        subscription.save

        redirect_to admin_subscriptions_url
      end

      def renew
        failure_count = @object.failure_count
        ::GenerateSubscriptionOrder.new(@object).call

        # check if the failure count has increase, that means we have an error
        if failure_count != @object.failure_count
          # send a renewal failure notice
          failed_order = @object.orders.reorder('created_at desc').first
          log = SubscriptionLog.find_by_order_id(failed_order.id)
          SubscriptionMailer.renewal_failure(@object, log.reason).deliver

          flash[:error] = flash_message_for(@object, :error_renew)
        else
          flash[:success] = flash_message_for(@object, :successfully_renewed)
        end
        respond_with(@object) do |format|
          format.html { redirect_to collection_url }
        end
      end

      def cancel
        if @object.cancel
          flash[:success] = flash_message_for(@object, :successfully_cancelled)
          respond_with(@object) do |format|
            format.html { redirect_to collection_url }
          end
        end
      end

      protected
        def collection
          return @collection if defined?(@collection)
          params[:q] ||= HashWithIndifferentAccess.new
          params[:q][:s] ||= 'id desc'

          @collection = super
          @search = @collection.ransack(params[:q])
          @collection = @search.result(distinct: true).
            includes(subscription_includes).
            page(params[:page]).
            per(params[:per_page] || Spree::Config[:promotions_per_page])

          @collection
        end     

        def require_order_id
          if params[:order_id].nil?
            redirect_to admin_subscriptions_url
            flash[:error] = flash_message_for(@object, :requires_order_id)
          end
        end

        def build_subscription_from_order(order)
          attrs = {
            user_id: order.user.id,
            state: 'active',
            interval: order.subscription_interval,
            duration: order.subscription_duration,
            prepaid_amount: order.subscription_prepaid_amount,
            credit_card_id: order.credit_card_id_if_available
          }
          order.build_subscription(attrs)
        end

        def build_subscription_items(subscription, order)
          order.line_items.each do |line_item|
            subscription.subscription_items.build(
              subscription: subscription,
              variant: line_item.variant,
              quantity: line_item.quantity,
              price: line_item.price
            )
          end
        end

        def subscription_includes
          [:user, :orders]
        end         
    end
  end
end
