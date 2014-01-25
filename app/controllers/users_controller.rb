# -*- encoding : utf-8 -*-
class UsersController < ApplicationController

  before_filter :parse_signed_request, only: [:deauth]

  def show
    if @user = current_user
      unless @user && @user.finished_onboarding?
        flash[:notice] = { title: "Welcome to Simple Giveaways.", content: "Please hold on a moment while we fetch your Facebook Pages." }
      end
      render 'dashboard/index'
    else
      redirect_to root_path
    end
  end

  def edit
  end

  def deauth
    if @identity = Identity.find_by_uid(@signed_request["user_id"])
      # TODO: Send email (should we destroy your User account and unsubscribe?)
      @identity.user.update_attributes(name: 'DEAUTHED_FACEBOOK')
      @identity.destroy
    end
    head :ok
  end

  private

  def parse_signed_request
    oauth = Koala::Facebook::OAuth.new(FB_APP_ID, FB_APP_SECRET)
    @signed_request = oauth.parse_signed_request(params[:signed_request])
  end
end
