require 'sinatra'
require 'haml'
require 'yaml'
require './github-db'
require 'bundler'
Bundler.require(:default)

get '/' do
  haml :index
end

get '/ms/*' do
  mochiscript "ms/#{params[:splat][0]}".to_sym
end
