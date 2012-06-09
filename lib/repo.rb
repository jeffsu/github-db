require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'cgi'


class Repo 
  def initialize(token, user, repo)
    @repo = repo 
    @user = user

    @token = token
    @http = Net::HTTP.new("api.github.com", 443)
    @http.use_ssl = true
  end

  def get(path, params={})
    query = params.keys.map { |k| "#{k}=#{CGI.escape(params[k].to_s)}" }.join('&')
    uri  = URI.parse("https://api.github.com/repos/#{@user}/#{@repo}#{path}?#{query}")

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "token #{@token}"

    response = @http.request(request)

    if response.code == '200'
      JSON.parse(response.body)
    else 
      raise response.body 
    end
  end

  def post(path, params={})
    uri  = URI.parse("https://api.github.com/repos/#{@user}/#{@repo}#{path}")

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = params.to_json
    request['Authorization'] = "token #{@token}"
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

  def populate!
    retrieve!
  end

  def retrieve!
    time  = Issue.last_updated 

    puts "Retrieving Issues"

    count = nil
    page  = 0
    while !count || count >= 25 
      count = retrieve_issues!(time, page += 1, 'open')
      puts "Paging issues #{page} of 'open' count: #{count}"
    end

    count = nil 
    page  = 0
    while !count || count >= 25
      count = retrieve_issues!(time, page += 1, 'closed')
      puts "Paging issues #{page} of 'closed' #{count}"
    end

  end

  def retrieve_issues!(time=nil, page=1, state=nil)
    time ||= Issue.last_updated

    rows = get("/issues", { since: time_str(time), page: page, state: state || 'open' })
    rows.each do |data|
      upsert_issue(data)
    end

    return rows.count
  end

  def repo_name
    return "#{@user}/#{@repo}"
  end

  def upsert_issue(data) 
    mdata = data['milestone']

    Issue.sanitize_hash!(data)
    issue = Issue.get(data)

    if issue
      puts "Updating Issue: #{issue.number}"
      issue.update_attributes(data)
    else
      puts "Inserting Issue: #{data['number']}"
      issue = Issue.new(data)
    end

    issue.repo ||= repo_name

    retrieve_comments!(issue)
    issue.save

    if mdata
      unless issue.milestone
        puts "Inserting milestone"
        puts mdata.inspect
        m = Milestone.new(mdata)
        m.repo = repo_name
        m.save
      end
    end
  end

  def retrieve_comments!(issue)
    if issue.comment_count > 0
      puts "Retreiving Comments!"
      issue.comments = get("/issues/#{issue.number}/comments", {})
    end
  end
end
