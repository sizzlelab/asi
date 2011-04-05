source "http://rubygems.org"

gem "rails", "3.0.0"

# Deploy with Capistrano
gem "capistrano"

# Bundle the extra gems:

gem "andand"
gem "hoptoad_notifier"
gem "json"
gem "mongrel"
gem "mysql", "2.8.1"
gem "rmagick"
gem "rubycas-client"
gem "thinking-sphinx", :require => "thinking_sphinx"
gem "whenever"
gem "i18n"
gem "has_many_polymorphs", :git => "http://github.com/jystewart/has_many_polymorphs.git"
gem "will_paginate", "~> 3.0.pre2"
gem "rdoc"

# this also needs to be in production so that rapidoc can run on the server
gem "factory_girl_rails"

group :production do
  gem "memcache-client"
end

group :development do
  # To use debugger
  gem "ruby-debug"
end

group :test do
  gem "redgreen"
end

