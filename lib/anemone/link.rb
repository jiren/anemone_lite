module Anemone
  class Link
    include MongoLite::Document
    include Anemone::Queue

    field :url
    field :page_url
    field :depth, :Integer
    field :referer

    create_index 'url'

  end
end
