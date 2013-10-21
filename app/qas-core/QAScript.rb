class QAScript
  require 'wordnet'
  require 'nokogiri'
  require 'xmlsimple'
  require 'net/http'
  require_relative 'WordNetMap'
  require_relative 'Sparql'
      
  def find_answer(q)
 
    @debug_log = []
    @question = q
    @wordnet = WordNet::Lexicon.new
    
    ########## STEP -1. query nlp demo server <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    # prepare query string
    uri = URI("http://nlp.stanford.edu:8080/corenlp/process")
    params = { 'outputFormat' => 'xml', 'input' => @question }
    uri.query = URI.encode_www_form(params)
    
    # do http query
    result = Net::HTTP.get_response(uri)
    
    # extract xml part from html answer
    x = result.body.gsub!("<br>", '')
    x = Nokogiri::HTML(x).text
    from =  (x =~ /<\?xml /)
    to = (x =~ /<\/root>/) +7
    x = x[from, to-from]
    
    
    ########## STEP 0. PARSE XML DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    # read in xml string from nlp parser
    xml = XmlSimple.xml_in(x,  { 'KeyAttr' => 'name' })
    xml = xml['document'][0]['sentences'][0]['sentence'][0]['tokens'][0]['token']
    
    # define data arrays
    @words = []
    @lemmas = []
    @pos = []
    @ners = []
    
    # extract data from xml document
    xml.each.with_index  { |element, i|
      @words[i] = element['word'][0]
      @lemmas[i] = element['lemma'][0]
      @pos[i] = element['POS'][0]
      @ners[i] = element['NER'][0]
    }
    
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
           locations << @words[i]
      end
    }
    
    # check how many possible locations were found
    case locations.length
      when 0 # if did not find any country name
        @debug_log << "TODO: no country found"
        # TODO: find MISC in NERS and get wordnet pertaynim
        # if related to country -> that is the subject country
        # if two or more follwing proper nouns, join with _ and look up in countries
      when 1
        # check if location is country
        if Country.find_by_name(locations[0])
          @debug_log << "found country #{locations[0]}"
          @country = locations[0]
        else
          @debug_log << "only location is no country"
          #TODO: do the same like there was no country found   
        end 
      when 2..10
        @debug_log << "more than one location found"
        n = 0
        indices = []
        locations.each.with_index do |l, i|
          if Country.find_by_name(l)
            n+=1
            indices << i
          end
        end
        case n
          when 0
            @debug_log << "no country found"
          when 1
            @country = locations[indices[0]]
            @debug_log << "one country found: #{@country}"
          when 2..10
            @debug_log << "more than one country found...abort"
            return error_result "Didn't understand the question, because more than one country was mentioned"
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
    @pos.each.with_index { |elem, i|
      if (elem == 'NN' || elem == 'NNS')
        nouns << [@lemmas[i], i]
        # get hypernyms
        possible_relations += wordnet_hypernyms(@lemmas[i], WordNet::Noun)
        
      elsif (elem.include? 'JJ') && (@ners[i] != 'Misc')     ##check for capitalization
        adjectives << [@lemmas[i], i]
        # TODO: handle adjectives
        
      elsif elem.include? 'VB'
        verbs << [@lemmas[i], i]
        # TODO: handle verbs
      end
    }
    
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
        # TODO: decide for certain relation or ??
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
            #TODO: "do something"
          when 1
            #TODO: extract answer if not a name
            @answer = result[0][:o].to_s
            result[0][:o].to_s =~ (/[.]*\/([A-Za-z]*)\z/)
            #@answer =  $1
          when 2..10
            @debug_log << "TODO: too many results found"
            # TODO: find right one
        end
        
      # when asked for country
      when @object && @object.length > 0 && @relation && @relation.length > 0
        @query = Sparql.subject_query(@relation, @object)
    end
    
    # return hash with debug and solution info
    return {:debug => @debug_log, :answer => @answer }
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
    { :debug => @debug_log, :answer => message}
  end

end