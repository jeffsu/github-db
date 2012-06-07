class Update
  field :table
  field :last_updated, type: DateTime

  index({ table: 1 }, { unique: true })
end
