DB_ENV = {:mongo => {:database => 'test'} }

require 'yaml'
#config = YAML.load_file("config.yaml")
#DB_ENV = {:mongo => config[:anemone] }

require 'anemone'

Anemone::Page.remove
Anemone::Link.remove

links = ['http://www.test.com/'].collect { |l|
   Anemone::Link.create(:url => l)
}

opts = {:verbose => true}

Anemone::Core.crawl(opts)
