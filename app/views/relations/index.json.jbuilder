json.array!(@relations) do |relation|
  json.extract! relation, :key, :relation
  json.url relation_url(relation, format: :json)
end
