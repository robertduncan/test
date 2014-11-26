class Simple::EventsController < ApplicationController

  include SessionsHelper

  before_filter :get_event, only: [:activate, :route, :generate_poll, :show]

  def new
    @event = Event.new
  end

  def create
    p params["questions"]
    puts "\n" * 10
    if params["questions"] != ","
      p "hid"
      Event.create_simple_event params, current_user
    end
    redirect_to dashboard_path
  end

  def route
    session[:user_id] = nil
    if params[:code] != @event.code
      redirect_to root_path and return
    end
    @polls = @event.polls
    session[:route_poll] = true
    session[:event_id] = @event.id
  end

  def generate_poll
    if @event.user_id == current_user.id
      poll = @event.polls.where(user_id: current_user.id).first
      redirect_to poll.url and return
    else
      poll = Poll.create event_id: @event.id, confirmed_attending: true ,email: current_user.email, user_id: current_user.id
      #REFACTOR: confirmed_attending should default to true
      poll.choices << @event.choices
      @event.users << current_user
      redirect_to poll.url
    end
  end

  def show
    @poll = @event.polls.where(user_id: current_user.id).first
    @service = Service.find @event.service_id
    @choices = @event.choices
    @event.update_attributes status: "activated"
  end

  private

  def get_event
    @event = Event.find(params[:id])
  end
end