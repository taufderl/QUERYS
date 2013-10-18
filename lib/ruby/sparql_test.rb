# require libs
require 'rdf'
require 'sparql/client'  
require_relative 'SparqlQAS'

sparql = SPARQL::Client.new("http://dbpedia.org/sparql")


query = sparql.query(SparqlQAS.create_query(object: 'Angela_Merkel', predicate: 'leaderName'))
#query = sparql.query(SparqlQAS.create_query(subject: 'Italy', predicate: 'capital')) 
 
 
query.each_solution do |s|
  puts s.inspect
end
 