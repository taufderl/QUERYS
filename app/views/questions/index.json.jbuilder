json.array!(@questions) do |question|
  json.extract! question, :question, :answer, :correct
  json.url question_url(question, format: :json)
end
