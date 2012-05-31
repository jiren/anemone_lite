DB_ENV = {:mongo => {:database => 'test', :pool_size => 5} }

require 'anemone'

Anemone::Page.remove
Anemone::Link.remove

links = ['http://www.example.com/'].collect { |l|
   Anemone::Link.enq(:url => l)
}

opts = {:verbose => true, :queue_timeout => 20}

Anemone::Core.crawl(opts)
