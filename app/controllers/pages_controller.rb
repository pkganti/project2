class PagesController < ApplicationController
  def home
    if @current_user.present?
      redirect_to recipes_path
    end
  end
end
