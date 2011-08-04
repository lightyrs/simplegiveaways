class UsersController < ApplicationController
  
  respond_to :html, :xml, :json
  
  before_filter :authenticate_user!
  
  def show
    @user = User.find(params[:id], :include => [:facebook_pages])
  end
end