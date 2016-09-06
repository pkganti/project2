class PagesController < ApplicationController
  # displays recipes list if user is present
  def home
    if @current_user.present?
      redirect_to recipes_path
    end
  end
end
