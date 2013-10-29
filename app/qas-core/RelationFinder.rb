# This class uses the coreNLP output to
# find out the relation that is asked for
# Therefore it searches in the wordnet tree for hypernyms
# TODO: clean
class RelationFinder
  require 'wordnet'
  require_relative 'Relations.rb'
  
  def initialize cnlp
    @words = cnlp[:words]
    @lemmas = cnlp[:lemmas]
    @pos = cnlp[:pos]
    @ners = cnlp[:ners]
    
    @wordnet = WordNet::Lexicon.new
  end
  
  # find country and return it
  def determine debug_log
    
    nouns = []
    verbs = []
    possible_relations = []
    
    # search for word types
    @pos.each.with_index do |elem, i|
      if (elem == 'NN' || elem == 'NNS')
        nouns << [@lemmas[i], i]
        # get noun hypernyms
        possible_relations += direct_hypernyms(@lemmas[i], WordNet::Noun)     
      elsif elem.include? 'VB'
        verbs << [@lemmas[i], i]
        # get verb hypernyms
        possible_relations += direct_hypernyms(@lemmas[i], WordNet::Verb)
      end
    end
    
    debug_log << "possible relations: #{possible_relations}"
    
    case possible_relations.length
      when 0
        debug_log << "didn't find possible relation"
      when 1
        return { relation: Relations.map[possible_relations[0]] }
      when 2..10
        
        # if all relations target the same predicated 
        targets = Set.new
        possible_relations.each do |r|
          targets.add Relations.map[r]
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
            return {relation: Relations.map[possible_relations[0]] }
          else
            #TODO: find correct one, print first
            return {relation: Relations.map[possible_relations[0]] }
          end
        end        
    end

    # if still not found a relation
  
    debug_log << "do deep search for nouns"
    
    nouns.each do |noun, i|
      possible_relations += recursive_hypernyms(noun, WordNet::Noun)
      
      if possible_relations.any?
        break
      end
    end
    
    case possible_relations.length
    when 0
      debug_log << "nothing found in deep search..."
    when 1
      return { relation: Relations.map[possible_relations[0]] }
    when 2..10
      debug_log << "possible_relations: #{possible_relations}"
    end
    
    if @relation.nil?
      return { error: "Could not determine the aimed relation of the question" }
    end
    
  end
  
  private
  
  # find hypernyms from wordnet
  def direct_hypernyms(word, part_of_speech)
    if Relations.map.keys.include? word
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
      return hypernyms.to_a & Relations.map.keys.to_a
    end
  end # end wordnet_hypernyms method
  
    # find hypernyms from wordnet
  def recursive_hypernyms(word, part_of_speech)
    if Relations.map.keys.include? word
      return [word]
    else
      # look in wordnet
      synsets = @wordnet.lookup_synsets(word, part_of_speech) 
      
      hypernyms = Set.new
      
      synsets.each  { |ss|
         ss.traverse(:hypernyms).each { |synset|
           synset.words.each { |w|
             hypernyms << w.lemma
           }
         }
       }
      
      #check these with the mappings
      return hypernyms.to_a & Relations.map.keys.to_a
    end
  end # end wordnet_hypernyms method

end