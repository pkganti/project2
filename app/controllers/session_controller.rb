class SessionController < ApplicationController
  # method to create session id as user_id if the user is logged in 'LOGIN function'
  def create
    user = User.find_by :email => params[:email]
    if user.present? && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to recipes_path
    else
      redirect_to root_path
    end
  end
  # method to logout
  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end

end
