class QAS
  require 'xmlsimple'
  require 'wordnet'
  require 'net/http'
  require 'nokogiri'
  require 'htmlentities'
  require 'rdf'
  require_relative 'WordNetMap'
  require_relative 'SparqlQAS'
  
  @wordnet = WordNet::Lexicon.new
  
  def self.wordnet_hypernyms(word, part_of_speech)
    
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
  end
  
  ## TODO: STEP -2. read question
  @question = "What is the governmental form of the Netherlands?"
  
  ########## STEP -1. query nlp demo server <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  
  # prepare query string
  uri = URI("http://nlp.stanford.edu:8080/corenlp/process")
  params = { 'outputFormat' => 'xml', 'input' => @question }
  uri.query = URI.encode_www_form(params)
  
  # do http query
  result = Net::HTTP.get_response(uri)
  
  # parse xml from html answer
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
  
  # print information for debugging
  puts "WORDS:  #{@words.join("\t")}"
  puts "LEMMAS: #{@lemmas.join("\t")}"
  puts "POS:    #{@pos.join("\t")}"
  puts "NERS:   #{@ners.join("\t")}"
  
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
      puts 'no country found'
      # TODO: find MISC in NERS and get wordnet pertaynim
      # if related to country -> that is the subject country
      # if two or more follwing proper nouns, join with _ and look up in countries
    when 1
      #TODO: check if country, if not answer can't process
      @country = locations[0][0]
    when 2
      puts '2 locations found ---> ??'
      #TODO: check both entries against an existing structure of
  end 
  
  ## @country is defined from here
  puts "Country: #{@country}"
  
  ########## 2. FIND RELATION <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   
  nouns = []
  adjectives = []
  verbs = []
  possible_relations = []
  
  # search for word types
  @pos.each.with_index { |elem, i|
    if elem == 'NN' || elem == 'NNS'
      nouns << [@lemmas[i], i]
      # TODO: get hypernyms, store all
      
      possible_relations += wordnet_hypernyms(@lemmas[i], WordNet::Noun)
      
    elsif (elem.include? 'JJ') && (@ners[i] != 'Misc')     ##check for capitalization
      adjectives << [@lemmas[i], i]
      # TODO: 
    elsif elem.include? 'VB'
      verbs << [@lemmas[i], i]
      # TODO: get hypernyms
    end
  }
  
  # debug print findings
  puts "NOUNS:      #{nouns}"
  puts "ADJECTIVES: #{adjectives}"
  puts "VERBS:      #{verbs}"
  
  puts "possible relations: #{possible_relations}"
  
  ########## 3. decide relation <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  
  case possible_relations.length
    when 0
      # TODO: find solution or say no relation found
      puts "no relation found"
    when 1
      @relation = WordNetMap.map[possible_relations[0]]
    when 2..10
      # TODO: decide for certain relation or ??
      
  end
  
  puts "Relation >>>>>>>>>> #{@relation}"
  
  ########## 4. Sparqle Query <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  
  # TODO: integrate sparql query here
  
  
  sparql = SPARQL::Client.new("http://dbpedia.org/sparql")
  
  # decide kind of query
  @query = ''
  @answer = ''
  case
    # when asked for property
    when @country && @country.length > 0 && @relation && @relation.length > 0
      @query = SparqlQAS.object_query(@country, @relation)
      
      result = sparql.query(@query)
      
      case result.length
        when 0
          puts "no results found"
          #TODO: "do something"
        when 1
          result[0][:o].to_s =~ (/[.]*\/([A-Za-z]*)\z/)
          @answer =  $1
        when 2..10
          puts "too many results found"
          # TODO: find right one
      end
      
    # when asked for country
    when @object && @object.length > 0 && @relation && @relation.length > 0
      @query = SparqlQAS.subject_query(@relation, @object)
  end

  puts "answer: #{@answer}"

end