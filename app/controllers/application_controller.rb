class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  stale_when_importmap_changes

  private

  def configure_permitted_parameters
    keys = [ :school_name, :academic_year, :current_enrollment ]
    devise_parameter_sanitizer.permit(:sign_up, keys: keys)
    devise_parameter_sanitizer.permit(:account_update, keys: keys)
  end
end
