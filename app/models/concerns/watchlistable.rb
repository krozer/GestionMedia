#app\models\concerns\watchlistable.rb
module Watchlistable
	extend ActiveSupport::Concern
  
	included do
	  scope :in_watchlist, -> { where(watchlist: true) }
	end
  
	def add_to_watchlist
	  update(watchlist: true)
	end
  
	def remove_from_watchlist
	  update(watchlist: false)
	end
  end