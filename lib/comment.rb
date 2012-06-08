class Comment 
  include Document
  field :body
  field :user
  field :created_at, type: DateTime
  field :updated_at, type: DateTime
end
