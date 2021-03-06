require 'google_calendar'

class UserGoogleCalendarTokensController < ApplicationController
  unloadable

  TIME_RANGES = [
		  ['synchronize last day', 1],
		  ['synchronize last 2 days', 2],
		  ['synchronize last 3 days', 3],
		  ['synchronize last week', 7],
		  ['synchronize last 2 weeks', 14],
		  ['synchronize last 4 weeks', 28]
  ]

  def show
    @user = User.find(params[:user_id])
    @token = UserGoogleCalendarToken.where(user_id: @user).first
    if @token
      @connected = if @token.calendar
        synchronizer = GoogleCalendarActivity::Synchronizer.new(refresh_token: @token.refresh_token,
                                                                calendar: @token.calendar,
                                                                redirect_url: google_calendar_oauth2_url)
        synchronizer.connected?
      end
    else
      # Force approval prompt in case we lost refresh token
      @authorize_url = calendar.authorize_url.to_s + "&state=#{@user.id}&approval_prompt=force"
    end
  end

  def create
    @user = User.find(params[:state])
    refresh_token = calendar.login_with_auth_code(params[:code])
    UserGoogleCalendarToken.create!(user: @user, refresh_token: refresh_token)
    redirect_to user_google_calendar_token_path(@user)
  end

  def update
    @user = User.find(params[:user_id])
    @token = UserGoogleCalendarToken.where(user_id: @user).first
    if @token.update_attributes(params[:user_google_calendar_token])
			if params[:synchronize]
				@token.synchronize!(true)
      end
			redirect_to user_google_calendar_token_path(@user)
    else
      flash[:error] = @token.errors.full_messages.join(", ")
      render :show
    end
  end

  private

  def calendar
    @calendar ||= GoogleCalendarActivity::Synchronizer.calendar(redirect_url: google_calendar_oauth2_url)
  end
end
