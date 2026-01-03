# Serves frontend HTML pages.
class PagesController < ActionController::Base
  # Use the application layout
  layout "application"

  # GET /
  # Redirects to projects if authenticated, signin otherwise.
  def home
    if session[:user_id]
      redirect_to projects_path
    else
      redirect_to signin_path
    end
  end

  # GET /signin
  # Shows the signin page with HCA OAuth button.
  def signin
    # If already signed in, redirect to projects
    redirect_to projects_path if session[:user_id]
  end

  # GET /projects
  # Shows the user's projects. Requires authentication.
  def projects
    unless session[:user_id]
      redirect_to signin_path and return
    end

    @current_user = User.find_by(id: session[:user_id])
    unless @current_user
      session.delete(:user_id)
      redirect_to signin_path and return
    end

    @projects = @current_user.projects.order(created_at: :desc)
  end

  # DELETE /signout
  # Signs out the user and redirects to signin.
  def signout
    session.delete(:user_id)
    session.delete(:jwt)
    redirect_to signin_path, notice: "Signed out successfully"
  end
end
