# lib\trakt_api.rb
require 'httparty'

class TraktApi
  include HTTParty
  base_uri 'https://api.trakt.tv'

  def initialize( access_token = nil)
    @headers = {
      'Content-Type' => 'application/json',
      'trakt-api-key' => Rails.application.credentials.dig(:trakt, :token),
      'trakt-api-version' => '2'
    }
    @headers['Authorization'] = "Bearer #{access_token}" if access_token
  end

  def watched(username,media_type, page: 1, limit: 10)
    response = self.class.get(
      "/users/#{username}/history/#{media_type}",
      headers: @headers,
      query: { page: page, limit: limit }
    )

    parse_paginated_response(response)
  end

  def watched_all(username,media_type, limit: 10)
	page = 1
	all_media = []
  
	loop do
	  response = watched(username, media_type, page: page, limit: limit)
	  all_media.concat(response[:data])
  
	  break if page >= response[:pagination][:total_pages]
  
	  page += 1
	end
  
	all_media
  end
  # Gestion des réponses paginées
  private

  def parse_paginated_response(response)
    if response.success?
      {
        data: response.parsed_response,
        pagination: {
          current_page: response.headers['X-Pagination-Page'].to_i,
          limit: response.headers['X-Pagination-Limit'].to_i,
          total_pages: response.headers['X-Pagination-Page-Count'].to_i,
          total_items: response.headers['X-Pagination-Item-Count'].to_i
        }
      }
    else
      raise "Erreur API : #{response.code} - #{response.message}"
    end
  end

end