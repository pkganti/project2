class UsersController < ApplicationController
  before_action :authorise_user, :only => [:index, :show]
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
    req = Cloudinary::Uploader.upload(params[:file])
    @user = @current_user
    @user.image = req["url"]
    if @user.update(user_params)
      redirect_to user_path
    else
      render :edit
    end
  end

  def show
    @user = User.find params[:id]
  end

  def destroy
    user = User.find params[:id]
    user.destroy
    redirect_to root_path
  end

  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :isAdmin, :image)
    end

end
