module Spree
  module Api
    class SubscriptionsController < Spree::Api::BaseController
      before_action :find_subscription, except: [:index]

      def self.prepended(base)
        base.prepend_after_action :deliver_cancellation_email, only: [:cancel]
        base.prepend_after_action :deliver_pause_email, only: [:pause]
        # need to touch user so the address list is updated
        base.prepend_after_action :touch_user, only: [:update_address, :create_address, :select_address]
      end

      def index
        render json: current_api_user.subscriptions,
          root: false,
          each_serializer: SubscriptionSerializer
      end

      def show
        render_subscription
      end

      def update
        @previous_interval = @subscription.interval
        result = @subscription.update_attributes(subscription_params)

        if result
          render json: @subscription.to_json
          Spree::SubscriptionMailer.delay.updated(@subscription, @previous_interval)
        else
          invalid_resource!(@subscription)
        end
      end

      def skip_next_order
        @subscription.skip_next_order

        render_subscription
      end

      def undo_skip_next_order
        @subscription.undo_skip_next_order

        render_subscription
      end

      def cancel
        @subscription.cancel

        render_subscription
      end

      def pause
        @subscription.pause

        render_subscription
      end

      def resume
        @subscription.resume

        render_subscription
      end

      def create_address
        new_address = Spree::SubscriptionAddress.create(address_params)

        if new_address.errors.empty?
          # attribute is either ship_address or bill_address
          @subscription.send("#{params[:attribute]}=", new_address)
          @subscription.save

          render json: @subscription.send(params[:attribute]).to_json
        else
          invalid_resource!(new_address)
        end
      end

      def update_address
        result = @subscription.send(params[:attribute]).dup.update_attributes(address_params)

        if result
          @subscription.touch

          render json: @subscription.send(params[:attribute]).to_json
        else
          invalid_resource!(@subscription.send(params[:attribute]))
        end
      end

      def select_address
        @subscription.send("#{params[:attribute]}=", find_subscription_address)
        if @subscription.save
          render json: @subscription.send(params[:attribute]).to_json
        else
          invalid_resource!(@subscription.send(params[:attribute]))
        end
      end

      # create a new credit card
      # then assign it to the subscription
      def create_credit_card
        order = @subscription.last_order
        credit_card = nil
        begin
          ::Spree::CreditCard.transaction do
            credit_card = current_api_user.credit_cards.build(credit_card_params)
            credit_card.save

            @subscription.credit_card = credit_card
            @subscription.save

            CardStore.store_card_for_user(current_api_user, credit_card, credit_card.verification_value)
          end

          render_subscription
        rescue CardStore::CardError
          @resource = credit_card
          render "sprangular/errors/invalid", status: 422
        end
      end

      private

      def deliver_cancellation_email
        Spree::SubscriptionMailer.cancel(@subscription).deliver_now
      end

      def deliver_pause_email
        Spree::SubscriptionMailer.pause(@subscription).deliver_now
      end

      def touch_user
        @subscription.user.touch
      end

      def render_subscription
        render json: @subscription,
          root: false,
          serializer: SubscriptionSerializer
      end

      def find_subscription
        @subscription ||= Spree::Subscription.accessible_by(current_ability, :read).find(params[:id])
      end

      def find_subscription_address
        @subscription_address ||= Spree::SubscriptionAddress.accessible_by(current_ability, :read).find(params[:address_id])
      end

      def address_params
        params.require(:address).permit(permitted_address_params)
      end

      def subscription_params
        params.require(:subscription).permit(permitted_subscription_attributes)
      end

      def credit_card_params
        params.require(:credit_card).permit!
      end

      def permitted_address_params
        [:firstname, :lastname, :address1, :address2, :city, :phone, :zipcode, :state_id, :state_name, :country_id, :user_id]
      end

      def permitted_subscription_attributes
        [:interval, :credit_card_id, :email]
      end
    end
  end
end
