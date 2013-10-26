class QuestionsController < ApplicationController
  before_action :set_question, only: [:show, :edit, :update, :destroy]
  # GET /questions
  # GET /questions.json
  def index
    @questions = Question.all
    @total = @questions.count
    
    @relation_count = Hash.new(0)
    @country_count = Hash.new(0)
    
    @correct = 0
    @wrong = 0
    
    @questions.each do |q|
      @relation_count[q.relation] += 1
      @country_count[q.country] += 1
      if q.correct == true
        @correct += 1
      elsif q.correct == false
        @wrong += 1
      end    
    end
    @ratio = @correct.to_f * 100 / (@correct.to_f + @wrong.to_f)
    
    @relation_count.sort_by {|k, v| -v}
    @country_count = @country_count.sort_by {|k, v| -v}
    
  end

  # DELETE /questions/1
  # DELETE /questions/1.json
  def destroy
    @question.destroy
    respond_to do |format|
      format.html { redirect_to questions_url }
      format.json { head :no_content }
    end
  end
  
  
  def export
    @questions = Question.all
    respond_to do |format|
      format.csv { send_data @questions.to_csv }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_question
    @question = Question.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def question_params
    params.require(:question).permit(:question, :answer, :correct)
  end
end
