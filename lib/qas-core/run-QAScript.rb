
require_relative 'QAScript.rb'

question = ARGV.join(' ')

qas = QAScript.new

result = qas.find_answer(question)

puts result[:debug]

puts "The answer is #{result[:answer]}"
