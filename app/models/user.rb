# user model
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable
  has_many :companies, through: :members
  has_many :exports, dependent: :nullify
  has_many :invoices, dependent: :destroy
  validates :email, presence: true
  validates :password, presence: true
  belongs_to :role

  def admin?
    role&.code == 'ADM'
  end
end
