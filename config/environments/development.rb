Rails.application.configure do
  url_options = { host: "localhost:3000" }
  config.action_mailer.default_url_options = url_options
  config.action_mailer.default_options = { from: "\"Spree\" <test@spree.com>" } # Change it also in spree.rb

  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.preview_path = "#{Rails.root}/lib/mailer_previews"
end
