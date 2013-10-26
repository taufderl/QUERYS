require 'wordnet'
require 'set'

class WordnetTest
 # find pertainym from wordnet and check if country
   # find hypernyms from wordnet
  
   
  def wordnet_hypernym(word, part_of_speech)
    @wordnet = WordNet::Lexicon.new
    
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
      return hypernyms.to_a
  end # end wordnet_hypernyms method 
end

w = WordnetTest.new

puts w.wordnet_hypernym('pay', WordNet::Verb)
