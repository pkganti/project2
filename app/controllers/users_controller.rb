class UsersController < ApplicationController
  before_action :authorise_user, :only => [:index]
  before_action :check_for_user, :only => [:edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new (user_params)
    if @user.save
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
  @user = @current_user
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
    @user = User.find params[:id]
  end

  def destroy
    user = User.find params[:id]
    user.isActive = false
    user.save
    
    redirect_to root_path
  end

  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :image)
    end

    def authorise_user
      redirect_to root_path unless  @current_user.present? &&   @current_user.admin?
    end

    def check_for_user
      redirect_to new_user_path unless  @current_user.present?
    end

end
