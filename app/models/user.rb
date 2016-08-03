class User < ActiveRecord::Base
  has_secure_password
  validates :email, :presence => true, :uniqueness => true

  has_many :favorites
  has_many :recipes

  ratyrate_rater
  
end
