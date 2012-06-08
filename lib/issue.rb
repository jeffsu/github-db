require 'mongoid'
class Issue
  include Document

  field :number
  field :state
  field :title
  field :body
  field :updated_string
  field :updated_at, type: DateTime
  field :comment_count, type: Integer
  field :closed_at, type: DateTime
  field :repo

  index({ number: 1 }, { unique: true })
  index({ updated_at: -1 })
  index({ updated_string: -1 })
  index({ repo: 1 })


  embeds_many :comments

  def self.sanitize_hash(hash)
    if n = hash['comments']
      hash['comment_count'] = n
      hash['updated_string'] = hash['updated_at']
      hash.delete('comments')
    end

    hash
  end

  def self.last_updated
    issue = order_by(:updated_string => :desc).first
    issue ? issue.updated_at : 3.months.ago
  end

  def self.get(data)
    return self.where(number: data['number'].to_i).first
  end

end
