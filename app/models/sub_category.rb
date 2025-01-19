class SubCategory < ApplicationRecord
	belongs_to :category
	has_many :yggs, foreign_key: 'sub_category', primary_key: 'code'
end
