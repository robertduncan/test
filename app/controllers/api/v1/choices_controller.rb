class Api::V1::ChoicesController < Api::V1::ApplicationController

  include SessionsHelper
  include ApplicationHelper
  skip_before_action :require_login
  skip_before_filter :verify_authenticity_token

  def create
    if !params["record_id"]
      choice = Choice.create extract_non_model_attributes(params, Choice)
      render json: api_response("createChoice", choice.to_hash) and return
    else
      choice = Choice.find params["record_id"]
      render json: api_response("updateChoice", pol.to_hash) and return
    end
  end

  def show
    begin
      choice = Choice.find params[:id]
      render json: api_response("getChoice", choice.to_hash)
    rescue
      render json: api_error("getChoice", "404", "Record not Found")
    end
  end

  def update
    begin
      choice = Choice.find params[:id]
      choice.update_attributes extract_non_model_attributes(params, Choice)
      render json: api_response("updateChoice", choice.to_hash)
    rescue
      render json: api_error("updateChoice", "404", "Record not Found")
    end
  end

  def index
    choices = Choice.all
    new_params = extract_non_model_attributes(params, Choice, true)
    if new_params
      choices = Choice.where(extract_non_model_attributes(params, Choice, true))
    end
    render json: api_response("choices", to_array_of_hashes(choices))
  end

  def vote
    bot_action = false
    choices = []
    begin
      params["answers"].each do |answer|
        @choice = Choice.find answer["record_id"]
        @event = @choice.poll.event
        answer = answer["answer"]
        if answer == "yes"
          @choice.update_attributes yes: true
        else
          @choice.update_attributes yes: false
        end
        poll = @choice.poll
        if @choice.poll.choices.where(yes: nil).empty?
          poll.update_attributes answered: true
        end
        if @choice.yes_count >= @event.threshold && @event.confirmation_id == nil || (@choice.yes_count >= @event.threshold && @event.confirmation_id != nil && @event.current_choice != @choice.value)
          # ReservationWorker.perform_async({restaurant_id: @choice.service_id, date_time: '11/20/2014 18:30:00',
          # party_size: @event.polls.count , first_name: @event.user.first_name, last_name: @event.user.last_name,
          # email: @event.user.email, phone_number: "9499813668"}, @event.user.id, @event.id, @choice.id)
          bot_action = true
        end
        choices << @choice
      end
      render json: api_response("voteChoices", {bot_action: bot_action, choices: to_array_of_hashes(choices)})
    rescue
      render json: api_error("voteChoices", "404", "Record not Found")
    end
  end
end
