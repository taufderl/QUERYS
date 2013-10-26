require 'wordnet'
require 'set'

class WordnetTest
 # find pertainym from wordnet and check if country
  def wordnet_pertainym(word, part_of_speech)
    # look in wordnet
    @wordnet = WordNet::Lexicon.new
    puts "look for #{word} as an #{part_of_speech}"
    synsets = @wordnet.lookup_synsets(word, part_of_speech) 
    
    puts synsets.inspect
    pertainyms = Set.new
      
      # get all hypernyms from wordnet
    synsets.each  { |ss|
      ss.pertainyms.each { |synset|
        synset.words.each { |w|
          pertainyms << w.lemma
        }
      }
    }
      
      #check these with the mappings
    return pertainyms.to_a
 
  end # end wordnet_pertainyms method
end

#w = WordnetTest.new

#puts w.wordnet_pertainym('German', WordNet::Adjective)

@wordnet = WordNet::Lexicon.new
puts @wordnet.inspect
   
   
synsets = @wordnet.lookup_synsets("pay", WordNet::Verb)
puts synsets.inspect
