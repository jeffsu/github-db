require 'net/http'
require 'net/https'
require 'uri'
require './issue'
require 'json'
require 'cgi'
require './integer'


Mongoid.configure do |config|
  name = "demo"
  config.master = Mongo::Connection.new.db(name)
end

class Repo 
  def initialize
    @user = "Factual"
    @repo = "front"
  end

  def get(path, params={})
    query = params.keys.map { |k| "#{k}=#{CGI.escape(params[k])}" }.join('&')
    puts query
    uri  = URI.parse("https://api.github.com/repos/#{@user}/#{@repo}#{path}?#{query}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth("jeffsu", "")
    response = http.request(request)
    JSON.parse(response.body)
  end

  def time_str(time)
    time.iso8601(10)
  end

  def retrieve_issues!
    get("/issues", { since: time_str(Issue.updated_at) }).each do |data|
      Issue.create(data)
    end
  end
end


repo = Repo.new
puts repo.time_str(1.year.ago)
repo.retrieve_issues!
puts Issue.count.inspect
puts Issue.updated_at.to_s
#puts Issue.first.inspect
