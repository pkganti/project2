class Recipe < ActiveRecord::Base
  belongs_to :user
  has_many :ingredients, :through => :quantities
  has_many :quantities
  accepts_nested_attributes_for :quantities, allow_destroy: true
  accepts_nested_attributes_for :ingredients, allow_destroy: true

end
