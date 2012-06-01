module Anemone
  class Link
    include MongoLite::Document
    include Anemone::Queue

    collection :links

    field :url
    field :referer
    field :depth, :Integer, :default => 0

    create_index 'url'

  end
end
