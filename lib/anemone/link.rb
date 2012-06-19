module Anemone
  class Link
    include MongoLite::Document
    include Anemone::Queue

    collection :links

    field :url
    field :referer
    field :depth, :Integer, :default => 0
    field :fetch_attempts, :Integer, :default => 0
    field :error

    create_index 'url'

    def self.[](link_url)
      self.first(:url => link_url.to_s)
    end

  end
end
