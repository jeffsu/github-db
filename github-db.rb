dir = File.dirname(__FILE__)
require 'mongoid'
require 'bson'

Mongoid.configure do |config|
  name = "demo"
  config.master = Mongo::Connection.new.db(name)
end

%W| document integer repo issue comment |.each do |file|
  require "#{dir}/lib/#{file}"
end
