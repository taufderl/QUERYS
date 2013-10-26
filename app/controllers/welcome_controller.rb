class WelcomeController < ApplicationController
  
  # if index page
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

      # run qascript
      require_relative '../qas-core/QAScript.rb'
      qascript = QAScript.new
      result = qascript.find_answer(@question, session[:country])


      # retrieve answer
      if result[:answer]
        @answer = result[:answer]
      elsif result[:error]
        flash.now[:alert] = result[:error]
      end
      
      # save country to session
      if result[:country]
        session[:country] = result[:country]
      end

      # and debug information if asked for
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

end