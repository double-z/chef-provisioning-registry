require 'sinatra'

configure do
  set :bind, '0.0.0.0'
end

get "/v1/register/consul/:name" do
  ip = params[:name].gsub('-', '.')
  `consul join #{ip}`
end
