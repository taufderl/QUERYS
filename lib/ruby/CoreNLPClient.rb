require 'stanford-core-nlp'
require 'socket'
require 'json'

server = TCPSocket.new 'localhost', 52534

server.puts "What is the capital of the Netherlands?"

while answer = server.gets
  result =  JSON.parse(answer)
end

@words = result['words']
@lemmas = result['lemmas']
@pos = result['pos']
@ners = result['ners']

puts "words:     #{@words.join(', ')}"
puts "lemmas:    #{@lemmas.join(', ')}"
puts "pos-tags:  #{@pos.join(', ')}"
puts "ner-tags:  #{@ners.join(', ')}"
