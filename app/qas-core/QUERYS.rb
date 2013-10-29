# This class is the core of the question answering system.
#
class QUERYS
  # requirements 
  require_relative 'CoreNLP.rb'
  require_relative 'CountryFinder.rb'
  require_relative 'RelationFinder.rb'
  require_relative 'DBpedia.rb'


  # The method find_answer runs the core algorithm that uses the stanford nlp 
  def find_answer(question, storedCountry)
    
    @question = question
 
    @debug_log = []
    
    @country = nil
    @relation = nil
    @answer = nil
    
    @words = []
    @lemmas = []
    @pos = []
    @ners = []
    
    adjectives = []
    nouns = []
    verbs = []
    
    ## check if question has '?' at the end?
    if @question.last != '?'
      return error_result "Please ask a question including a questionmark."
    end
    
    ########## 1. tag question with Stanford NLP <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    # Create coreNLP intance
    coreNLP = CoreNLP.new @question
    
    # run one of the coreNLP parser version
    # make sure requirements are fulfilled!
    
    # send query to Stanford's online demo and parse the html result
    # internet access necessary
    cnlp_results = coreNLP.query_online_demo
    
    # use the coreNLP libraries,requires them to be loaded on startup (~700MB ram)
    #cnlp = coreNLP.query_inherited_nlp
    
    # send query to a the running TCP server, needs to be set up separately 
    #cnlp = coreNLP.query_tcp_nlp_server 
    
    
    # if result contains error message
    if cnlp_results[:error]
      # quit here and send error
      return error_result cnlp_results[:error]
      # else retrieve coreNLP results
    else 
      @words = cnlp_results[:words]
      @lemmas = cnlp_results[:lemmas]
      @pos = cnlp_results[:pos]
      @ners = cnlp_results[:ners]
    end
        
    # collect debugging information  
    @debug_log << "words:     #{@words.join(', ')}"
    @debug_log << "lemmas:    #{@lemmas.join(', ')}"
    @debug_log << "pos-tags:  #{@pos.join(', ')}"
    @debug_log << "ner-tags:  #{@ners.join(', ')}"
    
    ########## 2. Find Country in the question <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    # Create countryFinder instance
    countryFinder = CountryFinder.new cnlp_results
    
    # run country search
    country_search_result = countryFinder.search @debug_log
    
    # if result contains error message
    if country_search_result[:error]
      # check if there was a country stored from last request and take that one
      if storedCountry
        @country = storedCountry
      else
        # otherwise return error
        return error_result country_search_result[:error]
      end
    # if result didn't cointain error extract country
    else
      @country = country_search_result[:country]
    end
    
    ## @country is defined from here
    @debug_log << ">>>>>>>>>>  country: #{@country}"
    
    ########## 3. Find and decide relation <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     
    # Create relationFinder instance
    relationFinder = RelationFinder.new cnlp_results
    
    # run relation determination
    relation_result = relationFinder.determine @debug_log
    
    # if result contains error message
    if relation_result[:error]
      # return error message
      return error_result relation_result[:error]
    # otherwise extract relation
    else
      @relation = relation_result[:relation]
    end
    
    ## @relation is defined from here
    @debug_log << ">>>>>>>>>> relation: #{@relation}"
    
    ########## 4. Sparqle Query <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    # Create relationFinder instance
    dbpedia = DBpedia.new @country, @relation
    
    # run relation determination
    sparql_result = dbpedia.query @debug_log
    
    # if result contains error message
    if sparql_result[:error]
      # return error message
      return error_result sparql_result[:error]
    # otherwise extract relation
    else
      @answer = sparql_result[:answer]
    end
    
    ## @answer is defined from here
    @debug_log << ">>>>>>>>>>   answer: #{@answer}" 
             
    # return all data
    return {:debug => @debug_log, :country => @country, :answer => @answer, :relation => @relation}
    
  end  
    
  private
  
  def error_result message
    { :debug => @debug_log, :error => message, :answer => false, :country => @country, :relation => @relation}
  end

end