class Milestone
  include Document

  field :issue_order, type: Array
  field :title
  field :number, type: Integer
  field :description

  field :created_string
  field :created_at, type: DateTime

  field :repo

  index({ number: 1, repo: 1 }, { unique: true })
  index({ created_at: -1 })
  index({ created_string: -1 })
  index({ repo: 1 })

end
