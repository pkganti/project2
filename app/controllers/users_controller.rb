class UsersController < ApplicationController
  before_action :authorise_user, :only => [:index]
  before_action :check_for_user, :only => [:edit, :update]

  def new
    @user = User.new
  end

  def create
    # signing up a new user to the app
    @user = User.new (user_params)
    if @user.save
      # setting the session id
      session[:user_id] = @user.id
      redirect_to user_path
    else
      render :new
    end
  end

  def edit
    @user = @current_user
  end

  def update
    # updating the user details
  @user = @current_user
  # checking if user is updating the image
  if params[:file].present?
    req = Cloudinary::Uploader.upload(params[:file])
    @user.image = req["url"]
    if @user.update(user_params)
      redirect_to user_path
    else
      render :edit
    end
  else
    if @user.update(user_params)
      redirect_to user_path
    else
      render :edit
    end
  end

  end

  def show
    # show the user specific details
    @user = User.find params[:id]
    recipes = Recipe.all

    @list_recipes = recipes.sample(2)
  end

  def destroy
    # inactivating the user if a user decides to delete his/her account
    user = User.find params[:id]
    user.isActive = false
    user.save

    redirect_to root_path
  end

  private
  # whitelisting the params
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :image)
    end

    #adding authorisation specific things
    def authorise_user
      redirect_to root_path unless  @current_user.present? &&   @current_user.admin?
    end

    # checking if a user is logged in
    def check_for_user
      redirect_to new_user_path unless  @current_user.present?
    end

end
