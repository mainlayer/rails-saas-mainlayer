source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.0"

gem "rails", "~> 7.1.0"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "redis", ">= 4.0.1"
gem "bcrypt", "~> 3.1.7"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false
gem "devise", "~> 4.9"
gem "mainlayer", "~> 1.0"
gem "httparty", "~> 0.21"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "dotenv-rails"
end

group :development do
  gem "web-console"
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webmock", "~> 3.23"
  gem "mocha"
end
