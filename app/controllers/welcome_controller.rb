class WelcomeController < ApplicationController
  
  def index
    
    if params[:judge_answer]
      id = params[:judge_answer]
      question = Question.find(id)
      @answer = question.answer
      question.correct = params[:correct]? true : false 
      question.save
      
      @question = question
      params[:question] = question.question 
      
      
      flash.now[:notice] =  "Thanks for the feedback that the answer is #{question.correct?}"
      render action: :index
      

    # if question asked
    elsif params[:question]
      question = params[:question]
      q = Question.new
      q.question = question
      
      #TODO: process question and find answer
      @answer = "Couldn't find an answer to \'#{question}\'."
    
      q.answer = @answer
      q.save
      @question = q
    end
    
  end #def index
end
