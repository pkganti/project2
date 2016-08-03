class RaterController < ApplicationController
  def create
    if @current_user.present?
      score = params[:score]
      recipe_id = params[:id]
      user_id = @current_user.id
      rate_to_update = Rate.find_by(:rater_id => user_id, :rateable_id => recipe_id)

      if rate_to_update.present?
        rate_to_update.stars = score
        rate_to_update.save
      else
        rate = Rate.new(:rater_id => user_id, :rateable_id => recipe_id,:stars => score)
        rate.save
      end
    end

    redirect_to :back

  end
end
