require "./github-db"
repo = Repo.new
puts repo.time_str(1.year.ago)
repo.retrieve!

puts Issue.count.inspect
puts Issue.last_updated.to_s
Issue.all.each do |issue|
  issue.repo = "Factual/front"
  issue.save
end
#puts Issue.first.inspect
