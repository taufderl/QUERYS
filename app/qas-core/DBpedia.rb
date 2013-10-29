# This class provides the Sparql functions to query DBpedia
# TODO: clean DBpedia.class
class DBpedia
  require 'rdf'
  require 'sparql/client'
  
  # creates new DBpedia instance
  def initialize c, r
    @country = c
    @relation = r
    
    @answer = ''
    
    # create query
    @query = create_query(@country, @relation)
    # create sparql client for dbpedia
    @sparql_client = SPARQL::Client.new("http://dbpedia.org/sparql")
  end
  
  # runs the query and processes the results
  def query debug_log
    
    # runs query
    result = @sparql_client.query(@query)
    
    # check result length
    case result.length
    when 0
      case @relation
      when 'dbpedia-owl:dissolutionDate'
        inner_query = create_query(@country, 'dbpedia-owl:dissolutionYear')
          result = @sparql_client.query(inner_query)
          if result[0][:o]
            @answer = result[0][:o].to_s[0..3]
          end
      when 'dbpedia-owl:foundingDate'
        inner_query = create_query(@country, 'dbpedia-owl:foundingYear')
          result = @sparql_client.query(inner_query)
          if result[0][:o]
            @answer = result[0][:o].to_s[0..3]
          end
      else
        return {error: "Sorry, there seems to be no information about that in DBpedia."}
      end
      
    when 1
      @answer = result[0][:o].to_s
      
      case @relation
      when 'dbpedia-owl:anthem'
        @answer =~ (/[.]*\/([^\/]*)\z/)
        @answer = $1
      when 'dbpedia-owl:capital'
        @answer =~ (/[.]*\/([^\/]*)\z/)
        @answer = $1
      when 'dbpprop:areaKm'
        @answer += ' km²'
      when 'dbpedia-owl:currency'
        @answer =~ (/[.]*\/([^\/]*)\z/)
        @answer = $1
        if @answer.end_with? '_sign'
          @answer = @answer[0..@answer.length-6]
        end
      when 'dbpedia-owl:governmentType'
        @answer =~ (/[.]*\/([^\/]*)\z/)
        @answer = $1
      when 'dbpedia-owl:longName'
        @answer
      when 'dbpedia-owl:motto'
        @answer
      when 'dbpedia-owl:populationDensity'
        @answer
      when 'dbpprop:populationEstimate'
        @answer
      when 'dbpprop:largestCity'
        if @answer == 'capital'
          # do another query for the capital...
          inner_query = create_query(@country, 'dbpedia-owl:capital')
          result = @sparql_client.query(inner_query)
          @answer = result[0][:o].to_s
          @answer =~ (/[.]*\/([^\/]*)\z/)
          @answer =  $1
        else
          @answer =~ (/[.]*\/([^\/]*)\z/)
          @answer =  $1
        end
      when 'dbpedia-owl:language'
        @answer =~ (/[.]*\/([^\/]*)\z/)
        @answer =  $1
        if @answer.end_with? '_language'
          @answer = @answer[0..@answer.length-10]
        end
      when 'dbpedia-owl:leaderTitle'
        inner_query = create_query(@country, 'dbpedia-owl:leaderName')
        result = @sparql_client.query(inner_query)
        @answer += "is #{result[0][:o].to_s}"
      end

      # replace _ with whitespace
      @answer.gsub!("_", ' ')

    when 2..10 # when more than one sparql result 
      debug_log << "more than one sparql result found"
      
      answers = []
      # find right one
      case @relation
      when 'dbpedia-owl:governmentType', 'dbpedia-owl:capital' # government type put all
        result.each do |r| 
          r[:o].to_s =~ (/[.]*\/([^\/]*)\z/)
          answers << $1
        end
        @answer =  answers.join ', '
        
      when 'dbpedia-owl:populationDensity' # round population density and add unit
        f = result[0][:o].to_f
        @answer = "#{f.round(1)} inhabitants/km²"
        
      when 'dbpedia-owl:currency'
        result.each do |r| 
          r[:o].to_s =~ (/[.]*\/([^\/]*)\z/)
          answers << $1
        end
        @answer = answers.join(', ')
      when 'dbpedia-owl:language'
        result.each do |r| 
          r[:o].to_s =~ (/[.]*\/([^\/]*)\z/)
          answers << $1
        end
        @answer = answers.join(', ')
      when 'dbpedia-owl:dissolutionDate',  'dbpedia-owl:foundingDate'
        result.each do |date_r|
          answers << date_r[:o].to_s
        end
        @answer = answers.join(', ')
      when 'dbpedia-owl:leaderTitle'
        result.each do |date_r|
          answers << date_r[:o].to_s
        end
        inner_query = create_query(@country, 'dbpedia-owl:leaderName')
        result = @sparql_client.query(inner_query)
        result.each do |date_r|
          date_r[:o].to_s =~ (/[.]*\/([^\/]*)\z/)
          answers << $1
        end
        @answer = answers.join(', ')
      
      end
      @answer.gsub!("_", ' ')
    end
    
    return { answer: @answer }
   
  end
  
  
  private
  
  # Send query for questions after the object  
  def create_query(subject, predicate)
    "SELECT distinct ?o 
      WHERE {
        dbpedia:#{subject} #{predicate} ?o.
      }"  
  end

end