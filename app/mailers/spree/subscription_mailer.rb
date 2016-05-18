class Spree::SubscriptionMailer < Spree::BaseMailer
  layout 'spree/base_mailer'

  def updated(subscription, previous_interval)
    @subscription = subscription
    @previous_interval = previous_interval
    @shipment_date = @subscription.next_shipment_date.strftime "%B %e, %Y"
    set_default_variables('Auto-Delivery Updated', 'updated_subscription')

    mail(to: @to_address, from: from_address, subject: @subject)
  end

  def cancel(subscription)
    @subscription = subscription
    set_default_variables('Auto-Delivery Service Canceled', 'order_cancellation')

    mail(to: @to_address, from: from_address, subject: @subject)
  end

  def pause(subscription)
    @subscription = subscription
    set_default_variables('Auto-Delivery Service Paused', 'pause_subscription')

    mail(to: @to_address, from: from_address, subject: @subject)
  end

  private
    def set_default_variables(subject, campaign)
      @subject = subject
      @campaign = campaign
      @order = @subscription.last_order
      @to_address = @order.email
      @from_addess = from_address
    end

end
