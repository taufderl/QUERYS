#!/usr/bin/env ruby

# require libs
require 'rdf'
require 'sparql/client'  
require_relative 'SparqlQAS'

sparql = SPARQL::Client.new("http://dbpedia.org/sparql")

hash = Hash.new

until ARGV.empty? do
  key = ARGV.shift
  val = ARGV.shift
  hash.merge! key => val
end

puts hash

querystring = SparqlQAS.create_query(hash)

result = sparql.query(querystring) 
 
result.each_solution do |s|
  puts s.inspect
end
 