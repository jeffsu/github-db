require 'mongoid'
class Issue
  include Mongoid::Document

  field :number
  field :state
  field :title
  field :body
  field :updated_at, type: DateTime

  index({ number: 1 }, { unique: true })
  index({ updated_at: -1 })

  def self.updated_at
    issue = order_by(:updated_at => :desc).first
    issue ? issue.updated_at : 1.year.ago
  end
end
