# This class provides the coreNLP functionality
#
# It implements 3 different methods, that all provide the same results
# but are based on different architecture 
class CoreNLP
  require 'net/http'
  require 'socket'
  require 'nokogiri'
  require 'stanford-core-nlp'
  require 'xmlsimple'
  require 'json'
  
  # initializes the coreNLP instance
  def initialize q
    @question = q
    
    @words = []
    @lemmas = []
    @pos = []
    @ners = []
  end
  
  # this method sends the question
  # to Stanford NLP Demo at http://nlp.stanford.edu:8080/corenlp/process
  # and parses the html answer
  def query_online_demo debug_log
    
    # build query URI
    uri = URI("http://nlp.stanford.edu:8080/corenlp/process")
    params = { 'outputFormat' => 'xml', 'input' => @question }
    uri.query = URI.encode_www_form(params)
    
    # run http query
    #result = Net::HTTP.get_response(uri) # old version without timeout
     
    http = Net::HTTP.new(uri.host, uri.port)
    
    http.read_timeout = 5
    http.open_timeout = 5
    begin
      result = http.start {|httpr|
        request = Net::HTTP::Get.new uri
        http.request request
      }
    rescue Net::OpenTimeout, SocketError, Net::ReadTimeout
      return { error: "The Stanford Core NLP Demo is not available." }
    end
      
    # extract xml part from html answer
    html = result.body.gsub!("<br>", '')
    html = Nokogiri::HTML(html).text
    from =  (html =~ /<\?xml /)
    to = (html =~ /<\/root>/) +7
    xml_string = html[from, to-from]
        
    # read in xml string from nlp parser
    xml = XmlSimple.xml_in(xml_string,  { 'KeyAttr' => 'name' })
    xml = xml['document'][0]['sentences'][0]['sentence'][0]['tokens'][0]['token']
    
    # extract data from xml document
    xml.each  { |element|
      @words << element['word'][0]
      @lemmas << element['lemma'][0]
      @pos << element['POS'][0]
      @ners << element['NER'][0]
    }
    
    # debug output
    debug_log << "Words:           #{@words.join(' | ')}"
    debug_log << "Lemmas:          #{@lemmas.join(' | ')}"
    debug_log << "Part-of-speech:  #{@pos.join(' | ')}"
    debug_log << "Words:           #{@ners.join(' | ')}"
    
    # return results
    return {words: @words, lemmas: @lemmas, pos: @pos, ners: @ners}
  end

  
  # send question to running TCP server and let it parse the question
  # retrieve the answer
  def query_tcp_nlp_server debug_log
    # connect to socket
    begin
      cnlps = TCPSocket.new 'localhost', 52534
    rescue Errno::ECONNREFUSED
      return {error: "The Stanford coreNLP server is not running."}
    end
    
    # send question to socket
    cnlps.puts @question

    # retrieve answer 
    while answer = cnlps.gets
      result = JSON.parse(answer)
    end
    
    # and return it
    return result
  end


  # This method uses the coreNLP libs
  # it requires tem to be loaded:
  #   -> This needs to be set in application.yml:
  #   -> config.pipeline = StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :ner) 
  #     
  def query_inherited_nlp debug_log
    
    # if libs loaded
    if defined? Rails.application.config.pipeline
      # run core NLP annotation
      annotated_question = StanfordCoreNLP::Annotation.new(@question)
      Rails.application.config.pipeline.annotate(annotated_question)
    else
      return {error: "The Stanford coreNLP libraries are not loaded."}
    end
      
    annotated_question.get(:tokens).to_a.each do |token|
      @words << token.get(:text).to_s
      @lemmas << token.get(:lemma).to_s 
      @pos << token.get(:part_of_speech).to_s
      @ners << token.get(:named_entity_tag).to_s
    end
    
    # debug output
    debug_log << "Words:           #{@words.join('|')}"
    debug_log << "Lemmas:          #{@lemmas.join('|')}"
    debug_log << "Part-of-speech:  #{@pos.join('|')}"
    debug_log << "Words:           #{@ners.join('|')}"
    
    # return results
    return {words: @words, lemmas: @lemmas, pos: @pos, ners: @ners}
  end
  
end