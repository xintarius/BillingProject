# member model
class Member < ApplicationRecord
  belongs_to :user
  belongs_to :company
end
