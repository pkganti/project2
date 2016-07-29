class Recipe < ActiveRecord::Base
  belongs_to: user
  has_many :ingredients :through => quantities
  has_many :quantities
end
