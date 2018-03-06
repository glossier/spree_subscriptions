# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_subscriptions'
  s.version     = '2'
  s.summary     = 'A Solidus extension to manage subscribable products.'
  s.description = """
    This Solidus extension enables an e-commerce owner manage products that can be subscribed to,
    via recurring payments and shipments at set intervals.
  """
  s.required_ruby_version = '>= 2.3.0'

  s.author    = 'Bryan Mahoney'
  s.email     = 'bryan@godynamo.com'
  s.homepage  = 'http://www.godynamo.com/'

  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency "solidus", [">= 1.4", "< 2"]

  s.add_development_dependency 'capybara', '~> 2.4'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'factory_girl', '~> 4.4'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '3.3.0'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pry-rails'
  s.add_development_dependency 'pry-byebug'
end
