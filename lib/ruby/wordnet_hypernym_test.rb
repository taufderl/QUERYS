class WordnetTest
  
  require 'wordnet'
  require 'set'
   
  def initialize
    @wordnet = WordNet::Lexicon.new  
  end
  
   
  # find hypernyms from wordnet
  def wordnet_hypernyms(word, part_of_speech)
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
  
    # find hypernyms from wordnet
  def wordnet_recursive_hypernyms(word, part_of_speech)
      # look in wordnet
      synsets = @wordnet.lookup_synsets(word, part_of_speech) 
      
      hypernyms = Set.new
      
      synsets.each  { |ss|
         ss.traverse(:hypernyms).each { |synset|
           synset.words.each { |word|
             hypernyms << word.lemma
           }
         }
       }
      
      #check these with the mappings
      return hypernyms.to_a
    
  end # end wordnet_hypernyms method
  
end

w = WordnetTest.new
require 'wordnet'


puts w.wordnet_recursive_hypernyms('president', WordNet::Noun)
