require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'cgi'


class Repo 
  def initialize
    @user = "Factual"
    @repo = "front"
    @http = Net::HTTP.new("api.github.com", 443)
    @http.use_ssl = true
  end

  def get(path, params={})
    query = params.keys.map { |k| "#{k}=#{CGI.escape(params[k].to_s)}" }.join('&')
    uri  = URI.parse("https://api.github.com/repos/#{@user}/#{@repo}#{path}?#{query}")

    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth("jeffsu", File.read('/home/jeffsu/password').strip)
    response = @http.request(request)
    if response.code == '200'
      JSON.parse(response.body)
    else 
      raise response.body 
    end
  end

  def time_str(time)
    time.iso8601(10)
  end

  def retrieve!
    time  = Issue.last_updated 

    count = nil
    page  = 0
    while !count || count >= 25 
      count = retrieve_issues!(time, page += 1, 'open')
      puts "Paging #{page} of 'open' count: #{count}"
    end

    count = nil 
    page  = 0
    while !count || count >= 25
      count = retrieve_issues!(time, page += 1, 'closed')
      puts "Paging #{page} of 'closed'"
    end
  end

  def retrieve_issues!(time=nil, page=1, state=nil)
    time ||= Issue.last_updated

    rows = get("/issues", { since: time_str(time), page: page, state: state || 'open' })
    rows.each do |data|
      data  = Issue.sanitize_hash(data)
      issue = Issue.get(data)

      if issue && issue.updated_string == data['updated_at']
        puts "Skipping: #{issue.number}"
        next
      end

      if issue
        puts "Updating Issue: #{issue.number}"
        issue.update_attributes(data)
      else
        puts "Inserting Issue: #{data['number']}"
        issue.repo = "#{@user}/#{@repo}"
        issue = Issue.new(data)
      end

      retrieve_comments!(issue)
      issue.save
    end

    return rows.count
  end

  def upsert(klass, data) 
    id = data['number'] || data['id']
    if obj
      puts "Updating #{klass.to_s} #{id}" 
      obj.update_attributes(data)
      return obj
    else
      puts "Inserting #{klass.to_s} #{id}"
      return self.create(data)
    end
  end

  def retrieve_comments!(issue)
    if issue.comment_count > 0
      puts "Retreiving Comments!"
      issue.comments = get("/issues/#{issue.number}/comments", {})
    end
  end
end
