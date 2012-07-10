module Anemone
  class Link
    include MongoLite::Document
    include Anemone::Queue

    set_collection({:name => :links})

    field :url
    field :referer
    field :depth, :Integer, :default => 0
    field :fetch_attempts, :Integer, :default => 1
    field :error

    index :url, {:unique => true}

    def self.[](link_url)
      self.first(:url => link_url.to_s)
    end

  end
end
