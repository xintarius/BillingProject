# export_model
class Export < ApplicationRecord
  belongs_to :user
  has_one_attached :file
end
