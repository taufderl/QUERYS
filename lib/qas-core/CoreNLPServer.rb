class CoreNLPServer
  require 'stanford-core-nlp'
  require 'socket'
  require 'json'

  def run
    pipeline =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :ner)
    @logger = File.open("cnlps-log.txt", 'w')
    @logger.write("whate")
    
    # log counter
    n = 0
    
    # define data arrays
    @words = []
    @lemmas = []
    @pos = []
    @ners = []
    
    server = TCPServer.new 52534
    loop do
      client = server.accept
      
      question = client.gets
      puts question
      
      question = StanfordCoreNLP::Annotation.new(question)
      pipeline.annotate(question)
      
      question.get(:tokens).to_a.each_with_index do |token, i|
        @words[i] = token.get(:text).to_s
        @lemmas[i] = token.get(:lemma).to_s 
        @pos[i] = token.get(:part_of_speech).to_s
        @ners[i] = token.get(:named_entity_tag).to_s
      end  
      
      puts "[#{n+=1}]>>> handled incoming request"
      puts "words:     #{@words.join(', ')}"
      puts "lemmas:    #{@lemmas.join(', ')}"
      puts "pos-tags:  #{@pos.join(', ')}"
      puts "ner-tags:  #{@ners.join(', ')}"
      
      hash = {:words => @words, :lemmas => @lemmas, :pos => @pos, :ners => @ners}
      
      out = hash.to_json.to_s
        
      client.puts out
      client.close
    end
  end # def run
end