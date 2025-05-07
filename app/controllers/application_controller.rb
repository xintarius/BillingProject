# Application controller
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!

  delegate :admin?, to: :current_user

  private

  def require_admin
    redirect_to root_path, alert: 'Brak dostępu' unless admin?
  end
end
