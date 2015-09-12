require 'dashing'

#
# Dashing configuration
#
configure do
  set :auth_token, 'SECRET_VALUE'
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
