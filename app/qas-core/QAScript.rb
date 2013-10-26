# TODO: be able to handle adjectives --> German capital -> Germany
# -> following proper nouns ?
# -> MISC ???
# 

#This class is the core of the question answering system.
class QAScript
  require 'wordnet'
  require 'nokogiri'
  require 'xmlsimple'
  require 'net/http'
  require 'stanford-core-nlp'
  require 'socket'
  require 'json'
  require_relative 'WordNetMap'
  require_relative 'Sparql'


  # The method find_answer runs the core algorithm that uses the stanford nlp 
  def find_answer(q, lastCountry)
     
 
    @debug_log = []
    @question = q
    @wordnet = WordNet::Lexicon.new    
    
    @words = []
    @lemmas = []
    @pos = []
    @ners = []
    
    ## check if question
    if @question.last != '?'
      return error_result "Please ask a question."
    end
    
    ########## 0. Use Stanford NLP <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    #use_inherited_nlp
    #use_tcp_nlp_server
    use_nlp_demo
        
    # collect debugging information  
    @debug_log << "words:      #{@words.join(', ')}"
    @debug_log << "lemmas:    #{@lemmas.join(', ')}"
    @debug_log << "pos-tags:  #{@pos.join(', ')}"
    @debug_log << "ner-tags:  #{@ners.join(', ')}"
    
    ########## 1. FIND COUNTRY IN QUESTION <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    locations = []
    
    # find locations in question
    @ners.each.with_index { |elem, i|
      if elem == 'LOCATION'
           locations << [@words[i], i]
      end
    }
    
    # check how many possible locations were found
    case locations.length
      when 0 # if did not find any country name
        @debug_log << "no certain country found"
        # TODO: find MISC in NERS and get wordnet pertaynim
        miscs = []
    
        # find miscs in question
        @ners.each.with_index { |elem, i|
          if elem == 'MISC'
               miscs << [@words[i], i]
          end
        }
        @debug_log << "found miscs: #{miscs.to_s}"
        
        case miscs.length
        when 1
          word = misc[0][0] # look this word in wordnet (not possible for now)
        when 2..10
          first = miscs.first[1]
          last = miscs.last[1]
        
          aggregated_misc = @words[first..last].join('_')
          
          if Country.find_by_name(aggregated_misc)
            @country = aggregated_misc
          end
        when 0
          # check for proper nouns
          # if two or more follwing proper nouns, join with _ and look up in countries
          nnps = []
          nnp_indices = []
          
          @pos.each_with_index do |pos, i|
            if pos == 'NNP' || pos == 'NNPS'
              nnps << @words[i]
              nnp_indices << i
            end
          end
          @debug_log << "Proper nouns #{nnps.to_s} found"
          
          case nnp_indices.length
          when 2
            if nnp_indices[1] - nnp_indices[0] == 1
              # combine them
              c = nnps.join('_')
              @debug_log << "Check for Country #{c} if exists"
              if Country.find_by_name(c)
                @country = c
              end 
            end
          end
        end
        
        # if related to country -> that is the subject country
        
        # activate referring to last country here if wanted
        #@country = lastCountry if lastCountry
      when 1
        # check if location is country
        if Country.find_by_name(locations[0])
          @debug_log << "found country #{locations[0]}"
          @country = locations[0][0]
        else
          @debug_log << "only location is no country"
          return error_result "Could not determine the referred country"   
        end 
      when 2..10
        @debug_log << "more than one location tag, try aggregation"
        
        first = locations.first[1]
        last = locations.last[1]
        
        aggregated_country = @words[first..last].join('_')
        
        @debug_log << "aggregated country: #{aggregated_country}"
        
        if Country.find_by_name(aggregated_country)
          @country = aggregated_country
        else
          n = 0
          indices = []
          locations.each do |l, i|
            if Country.find_by_name(l)
              n+=1
              indices << i
            end
          end
          
          case n
          when 0
            @debug_log << "this should not happen!!"  
          when 1
            @country = locations[indices[0]]
            @debug_log << "one country found: #{@country}"
          when 2..10
            @debug_log << "more than one country found...abort"
            return error_result "Didn't understand the question, because more than one country was mentioned"
        end
      end
    end 
    
    ## @country is defined from here
    @debug_log << ">>>>>>>>>> country: #{@country}"
    
    ########## 2. FIND RELATION <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     
    nouns = []
    adjectives = []
    verbs = []
    possible_relations = []
    
    # search for word types
    @pos.each.with_index do |elem, i|
      if (elem == 'NN' || elem == 'NNS')
        nouns << [@lemmas[i], i]
        # get hypernyms
        possible_relations += wordnet_hypernyms(@lemmas[i], WordNet::Noun)
        
      elsif (elem.include? 'JJ') && (@ners[i] != 'Misc')     ##check for capitalization
        adjectives << [@lemmas[i], i]
        # TODO: handle adjectives (Wordnet issue)
        
      elsif elem.include? 'VB'
        verbs << [@lemmas[i], i]
        # handle verbs
        possible_relations += wordnet_hypernyms(@lemmas[i], WordNet::Verb)
      end
    end
    @debug_log << "Found verb hypernyms: #{possible_relations}"
    
    # debug print findings
    @debug_log << "nouns:      #{nouns}"
    @debug_log << "adjectives: #{adjectives}"
    @debug_log << "verbs:      #{verbs}"
    @debug_log << "possible relations: #{possible_relations.join(', ')}"
    
    ########## 3. decide relation <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    case possible_relations.length
      when 0
        @debug_log << "didn't find possible relation"
        return error_result "Could not determine the aimed relation of the question"
      when 1
        @relation = WordNetMap.map[possible_relations[0]]
      when 2..10
        @debug_log << possible_relations.inspect
        
        # if all relations target the same predicated 
        targets = Set.new
        possible_relations.each do |r|
          targets.add WordNetMap.map[r]
        end
        if targets.size == 1
          @relation = targets.to_a[0]
      
        else
          if possible_relations.include? 'people'
            possible_relations.delete 'people'
          end
          if possible_relations.include? 'name'
            possible_relations.delete 'name'
          end
          if possible_relations.length == 1
            @relation = WordNetMap.map[possible_relations[0]]
          end
        end
            


        # if poeple and density: take density
        #elsif (possible_relations.length == 2) && (possible_relations.include? 'people') && (possible_relations.include? 'density')
        #  @relation = WordNetMap.map['density']
        #end
        
    end
    
    @debug_log << ">>>>>>>>>> relation: #{@relation}"
    
    ########## 4. Sparqle Query <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    # create client for dbpedia
    sparql = SPARQL::Client.new("http://dbpedia.org/sparql")
    
    # decide kind of query
    @query = ''
    @answer = ''
    case
      # when asked for property
      when @country && @country.length > 0 && @relation && @relation.length > 0
        @query = Sparql.object_query(@country, @relation)
        
        result = sparql.query(@query)
        
        case result.length
          when 0
            @debug_log << "TODO: no results found"
            return error_result "Sorry, there seems to be no information about that in DBpedia"
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
                inner_query = Sparql.object_query(@country, 'dbpedia-owl:capital')
                result = sparql.query(inner_query)
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
            end

            # replace _ with whitespace
            @answer.gsub!("_", ' ')
  
          when 2..10 # when more than one sparql result 
            @debug_log << "more than one sparql result found"
            @debug_log << result.inspect
            
            # find right one
            case @relation
            when 'dbpedia-owl:governmentType' # government type put all
              answers = []
              result.each do |r| 
                r[:o].to_s =~ (/[.]*\/([^\/]*)\z/)
                answers << $1
              end
              @answer =  answers.join ', '
            when 'dbpedia-owl:populationDensity'
         
              f = result[0][:o].to_f
              @answer = "#{f.round(1)} inhabitants/km²"
            when 'dbpedia-owl:language'
              # TODO
              @answer =~ (/[.]*\/([^\/]*)\z/)
              @answer =  $1
              if @answer.end_with? '_language'
                @answer = @answer[0..@answer.length-10]
              end
            end

          end

          @answer.gsub!("_", ' ')            
      
      # when asked for country
      when @object && @object.length > 0 && @relation && @relation.length > 0
        @query = Sparql.subject_query(@relation, @object)
    end
    
    @debug_log << "The answer output is set to #{@answer}" 
            
    
    # return hash with debug and solution info
    return {:debug => @debug_log, :country => @country, :answer => @answer }
  end # find_answer_method
  
  
  # find hypernyms from wordnet
  def wordnet_hypernyms(word, part_of_speech)
    if WordNetMap.map.keys.include? word
      return [word]
    else
      # look in wordnet
      synsets = @wordnet.lookup_synsets(word, part_of_speech) 
      
      hypernyms = Set.new
      
      # get all hypernyms from wordnet
      synsets.each  { |ss|
        ss.hypernyms.each { |synset|
          synset.words.each { |w|
            hypernyms << w.lemma
          }
        }
      }
      
      #check these with the mappings
      return hypernyms.to_a & WordNetMap.map.keys.to_a
    end
  end # end wordnet_hypernyms method
  
  private
  
  def error_result message
    { :debug => @debug_log, :error => message, :answer => false}
  end
  
  ## Several methods follow to use the nlp parser
  
  def use_nlp_demo
    uri = URI("http://nlp.stanford.edu:8080/corenlp/process")
    
    params = { 'outputFormat' => 'xml', 'input' => @question }
    uri.query = URI.encode_www_form(params)
    
    # do http query
    result = Net::HTTP.get_response(uri)
    
    #http = Net::HTTP.new(uri.host, uri.port)
    
    #http.read_timeout = 5
    #http.open_timeout = 5
    #begin
    #  result = http.start() {|httpr|
    #    httpr.post(uri.path, params)
    #  }
    #rescue Net::OpenTimeout 
    #  return error_result "The Stanford NLP core seems not to be reachable.\nCouldn't process your question."
    #end
    
    puts result.inspect
    puts result.body
      
    # extract xml part from html answer
    x = result.body.gsub!("<br>", '')
    x = Nokogiri::HTML(x).text
    from =  (x =~ /<\?xml /)
    to = (x =~ /<\/root>/) +7
    x = x[from, to-from]
        
    # read in xml string from nlp parser
    xml = XmlSimple.xml_in(x,  { 'KeyAttr' => 'name' })
    xml = xml['document'][0]['sentences'][0]['sentence'][0]['tokens'][0]['token']
    
    # extract data from xml document
    xml.each.with_index  { |element, i|
      @words[i] = element['word'][0]
      @lemmas[i] = element['lemma'][0]
      @pos[i] = element['POS'][0]
      @ners[i] = element['NER'][0]
    }    
  end
  
  def use_tcp_nlp_server
    begin
      cnlps = TCPSocket.new 'localhost', 52534
    rescue Errno::ECONNREFUSED
      return error_result "The core nlp is not running..."
    end
    cnlps.puts @question

    while answer = cnlps.gets
      result =  JSON.parse(answer)
    end
    
    @words = result['words']
    @lemmas = result['lemmas']
    @pos = result['pos']
    @ners = result['ners']
  end
  
  def use_inherited_nlp
    #@@pipeline = StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :ner) ## Needs to be set in config if this method is used
    annotated_question = StanfordCoreNLP::Annotation.new(@question)
    #@@pipeline.annotate(annotated_question)
    Rails.application.config.pipeline.annotate(annotated_question)
      
    annotated_question.get(:tokens).to_a.each_with_index do |token, i|
      @words[i] = token.get(:text).to_s
      @lemmas[i] = token.get(:lemma).to_s 
      @pos[i] = token.get(:part_of_speech).to_s
      @ners[i] = token.get(:named_entity_tag).to_s
    end
  end

end