Deface::Override.new(:virtual_path => 'spree/admin/shared/_order_summary',
                     :name         => 'add_subscription_link_to_admin_edit_order',
                     :insert_bottom   => ".additional-info",
                     :original    => '3a09af526d991bcbb51fcee781d28f7d7cbc981e',
                     :text         => '
<dt><%= Spree.t(:subscriptions) %>:</dt>
<% if @order.subscription %>
<dd><%= link_to(@order.subscription.id, edit_admin_subscription_path(@order.subscription), target: "_blank") %></dd>
<% else %>
<dd><%= link_to Spree.t(:create), new_admin_subscription_path(order_id: @order.id) %></dd>
<% end %>
')
