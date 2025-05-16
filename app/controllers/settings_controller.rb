# settings_controller
class SettingsController < ApplicationController
  layout 'dashboard_layout'

  def index
    member = Member.find_by(user_id: current_user.id)
    @username = current_user.email
    @user_created = current_user.created_at
    @user_updated = current_user.updated_at
    @nip = Company.find_by(member_id: member.id)
  end
end
