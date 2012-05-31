module Anemone
  class Link
    include MongoLite::Document
    include Anemone::Queue

    collection :links

    field :url
    field :page_url
    field :depth, :Integer, :default => 0
    field :referer

    create_index 'url'

  end
end
