# landing_controller
class LandingController < ApplicationController
  before_action :authenticate_user!, :signed_in
  def index; end

  private

  def signed_in
    redirect_to dashboard_index_path if current_user.present?
  end
end
