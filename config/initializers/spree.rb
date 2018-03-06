# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'
Spree.config do |config|
  # Example:
  # Uncomment to override the default site name.
  # config.site_name = "Spree Demo Site"
end

Spree.user_class = "Spree::User"
Spree::PermittedAttributes.line_item_attributes << :interval

Spree::Backend::Config.configure do |config|
  config.menu_items << config.class::MenuItem.new(
    [:subscriptions],
    'clock-o',
    partial: 'spree/admin/shared/subscriptions_sub_menu',
    url: :admin_subscriptions_path
  )
end
