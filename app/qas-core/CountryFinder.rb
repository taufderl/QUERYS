# This class uses the coreNLP output to
# find a country in the question
# TODO: make order more understandable and readable
class CountryFinder
  require_relative 'CountryAdjectives.rb'
  
  def initialize cnlp
    @words = cnlp[:words]
    @lemmas = cnlp[:lemmas]
    @pos = cnlp[:pos]
    @ners = cnlp[:ners]
  end
  
  # find country and return it
  def search debug_log
    
    locations = []
    adjectives = []
    
    # find locations in question
    @ners.each.with_index { |elem, i|
      if elem == 'LOCATION'
           locations << [@words[i], i]
      end
    }
    
    # check how many possible locations were found
    case locations.length
      when 0 # if did not find any country name
        debug_log << "no certain country found"
        # find MISC in NERS and get wordnet pertaynim
        miscs = []
    
        # find miscs in question
        @ners.each.with_index { |elem, i|
          if elem == 'MISC'
               miscs << [@words[i], i]
          end
        }
        debug_log << "found miscs: #{miscs.to_s}"
        
        case miscs.length
        when 1
          word = miscs[0][0] # look this word in wordnet (not possible for now)
          if CountryAdjectives.map.keys.include? word
            return {country: CountryAdjectives.map[word]}
          end
          
        when 2..10
          first = miscs.first[1]
          last = miscs.last[1]
        
          aggregated_misc = @words[first..last].join('_')
          
          if Country.find_by_name(aggregated_misc)
            return {country: aggregated_misc}
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
          debug_log << "found proper nouns #{nnps.to_s}"
          
          case nnp_indices.length
          when 2
            if nnp_indices[1] - nnp_indices[0] == 1
              # combine them
              c = nnps.join('_')
              debug_log << "Check for Country #{c} if exists"
              if Country.find_by_name(c)
                return {country: c}
              end 
            end
          when 0 || 1
            # try to find Country in adjectives
            @pos.each_with_index do |elem, i|
              if elem.include? 'JJ'
                 adjectives << [@lemmas[i], i]
              end
            end
            adjectives.each do |adj, i|
              if CountryAdjectives.map.keys.include? adj
                return {country: CountryAdjectives.map[adj] }
              end
            end
          end
        end

        
      when 1 # if 1 location found 
        # check if that location is country
        if Country.find_by_name(locations[0])
          debug_log << "found country #{locations[0][0]}"
          return {country: locations[0][0]}
        else
          debug_log << "only location is no country"
          return {error: "Could not determine the referred country"}   
        end
         
         
      when 2..10 # if more than 1 location was found
        debug_log << "more than one location tag, try aggregation"
        
        first = locations.first[1]
        last = locations.last[1]
        
        aggregated_country = @words[first..last].join('_')
        
        debug_log << "aggregated country: #{aggregated_country}"
        
        if Country.find_by_name(aggregated_country)
          return { country: aggregated_country }
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
            debug_log << "this should not happen!!"  
          when 1
            debug_log << "one country found: #{@country}"
            return { country: locations[indices[0]] }
          when 2..10
            debug_log << "more than one country found...abort"
            return { error: "Didn't understand the question, because more than one country was mentioned" }
        end
      end
    end 
    
    return {error: "No country found in the given question."}
    
  end
  
end