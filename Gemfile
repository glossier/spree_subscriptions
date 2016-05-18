source 'http://rubygems.org'

gem 'solidus', github: 'solidusio/solidus', branch: 'master'
# Provides basic authentication functionality for testing parts of your engine
gem 'solidus_auth_devise', github: 'solidusio/solidus_auth_devise', branch: 'master'
gem 'active_model_serializers', '~> 0.8.3'
gem 'stripe'
gem 'slim-rails'

group :test do
  gem 'factory_girl', '4.5.0'
  gem 'launchy'
  gem "shoulda-matchers", '2.8.0'
  gem 'haml-rails'
  gem 'database_cleaner', '1.4.1'
  gem 'timecop'
  gem 'guard-rspec', require: false
  gem 'simplecov', require: false
end

group :development do
  gem 'letter_opener'
end

gemspec
