class WelcomeController < ApplicationController

  def index
  
    # set to debug mode
    @DEBUG_MODE = true
    
    # if judge answer
    if params[:judge_answer]
      id = params[:judge_answer]
      @question = Question.find(id)
      @answer = @question.answer
      
      if params[:correct]
        @question.correct = true
      elsif params[:incorrect]
        @question.correct = false
      end
       
      @question.save
      
      params[:question] = @question.question 
      
      flash.now[:notice] =  "Thanks for the feedback that the answer is #{@question.correct?}"
      render action: :index 

    # if question asked
    elsif params[:question]
      @question = params[:question]
      q = Question.new
      q.question = @question
    
      ##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>SCRIPT BEGIN

      require_relative '../qas-core/QAScript.rb'
      qas = QAScript.new
      
      result = qas.find_answer(@question)
      
      @answer = result[:answer]
      
      if @DEBUG_MODE
        flash.now[:notice] = result[:debug].join "<br />"
      end
      
      ##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>SCRIPT END
       
      # save question with answer to db
      q.answer = @answer
      q.save
      @question = q
      
      render action: "index"
    end
    
    
  end #def index


private 


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
end

end