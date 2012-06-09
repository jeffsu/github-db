require 'sinatra'
require 'haml'
require 'yaml'
require './github-db'
require 'bundler'
require './lib/jade-filter'

enable :sessions
set :session_secret, "foobarbaz"



Bundler.require(:default)
CONFIG = YAML.load_file("./config.yml")

def new_repo(session)
  return Repo.new(session[:token], session[:user], session[:repo])
end

def new_client
  OAuth2::Client.new(CONFIG['client'], CONFIG['secret'], 
      :ssl           => { :ca_file => CONFIG['pem'] },
      :site          => 'https://github.com',
      :authorize_url => 'https://github.com/login/oauth/authorize',
      :token_url     => 'https://github.com/login/oauth/access_token')
end

def redirect_uri(path = '/auth/github/callback', query = nil)
  uri = URI.parse(request.url)
  uri.path  = path
  uri.query = query
  uri.to_s
end

get '/' do
  haml :index
end

post '/set_repo' do
  session[:user] = params[:user]
  session[:repo] = params[:repo]
  redirect '/pivot'
end

get '/auth/github' do
  url = new_client.auth_code.authorize_url(
    :redirect_uri => redirect_uri,
    :scope        => 'repo',
  )

  redirect url
end

get '/auth/github/callback' do
  access_token = new_client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
  session['token'] =  access_token.token
  redirect '/'
end


get '/pivot' do
  repo = new_repo(session)
  haml :pivot
end

get '/populate' do
  repo = new_repo(session)
  repo.populate!
  "Finished"
end

get '/ms/*' do
  mochiscript "ms/#{params[:splat][0]}".to_sym
end

post '/milestones/:id/order' do
  m = Milestone.where(:number => params[:id]).first
  m.issue_order = params[:order].split(',')
  m.save
end

post '/issues/:id' do 
  args = {}
  repo = new_repo(session)

  if n = params[:milestone]
    args['milestone'] = n.to_i
  end

  if labels = params[:labels]
    args['labels'] = labels.split(',')
  end

  data = repo.post("/issues/#{params[:id]}", args)
  repo.upsert_issue(data)
end
