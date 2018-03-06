def subscription
  @order.subscriptions.last
end

def next_shipment_date
  @order.subscriptions.last.next_shipment_date.to_date
end

def next_calc_shipment_date
  subscription.last_shipment_date.advance(subscription.calc_next_renewal_date).to_date
end

def original_shipment_date
  (subscription.interval).months.from_now.to_date
end
