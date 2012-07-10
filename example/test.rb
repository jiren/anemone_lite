#Export variable 
#i.e  export CRAWLER='db_config:config/mongo.yml,env:development'

#For test only
ENV['CRAWLER'] = 'db_config:config/mongo.yml,env:development'

require 'rubygems'
require 'bundler/setup'
require 'anemone'

Anemone::Page.remove
Anemone::Link.remove

Anemone::Link.enq(:url => 'http://www.example.com/')

opts = {:verbose => true, :queue_timeout => 20}

puts "**** Start Time: #{Time.now} => Process Id: #{$$} ****"

Anemone::Core.crawl(opts)

puts "**** End Time: #{Time.now} ****"
