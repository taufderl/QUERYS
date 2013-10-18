class SparqlQAS
  require 'rdf'
  require 'sparql/client'  
  
  # Send query for questions after the object  
  def self.object_query(subject, predicate)
    "SELECT distinct ?o 
      WHERE {
        dbpedia:#{subject} #{predicate} ?o.
      }"  
  end
  
  # Send query for questions after the subject
  def self.subject_query(predicate, object)
    "SELECT distinct ?s
      WHERE {
        ?s dbpedia-owl:#{predicate} dbpedia:#{object}.
      }"  
  end
  
  # Send general query
  def self.create_query(hash)
    if (hash['subject'] && hash['predicate'])
      return object_query(hash['subject'], hash['predicate'])
    elsif (hash['predicate'] && hash['object'])
      return subject_query(hash['predicate'], hash['object'])
    else
      return nil
    end
  end


  ######## OLD EXAMPLE
  def example_query()
    "SELECT distinct ?x ?y ?z 
      WHERE {
        ?x rdf:type dbpedia-owl:Country.
        ?x ?y ?z.
      }"  
  end

end