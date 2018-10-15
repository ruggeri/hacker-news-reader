require 'json'
require 'faraday'
require_relative './item.rb'

module HackerNewsReader; end

# Methods to pull data down from the Hacker News API.
module HackerNewsReader::WebAPI
  BASE_URL = "https://hacker-news.firebaseio.com/v0"

  # Pulls a list of the ids of the current "best" stories.
  def self.pull_best_ids
    uri = "#{BASE_URL}/beststories.json?print=pretty"

    response = Faraday.get(uri)
    if response.status != 200
      raise "pull_best_ids status: #{response.status}"
    end

    new_ids = JSON.parse(response.body)
    new_ids
  end

  # Pulls the information of a given story.
  def self.pull_item(new_id)
    uri = "#{BASE_URL}/item/#{new_id}.json?print=pretty"

    response = Faraday.get(uri)
    if response.status != 200
      raise "get_id: #{new_id} status: #{response.status}"
    end

    json = JSON.parse(response.body, symbolize_names: true)
    Item.from_json(json)
  end
end
