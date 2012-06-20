#Export variable 
#i.e  export MONGODB_URI=mongodb://localhost:27017/test
#     export MONGODB_POOL_SIZE=5      
#

ENV['MONGODB_URI'] = 'mongodb://localhost:27017/test'
ENV['MONGODB_POOL_SIZE'] = "5"

require 'rubygems'
require 'bundler/setup'
require 'anemone'

Anemone::Page.remove
Anemone::Link.remove

['http://www.example.com/'].collect { |l|
   Anemone::Link.enq(:url => l)
}

opts = {:verbose => true, :queue_timeout => 20}


puts "**** Start Time: #{Time.now} ****"
puts "Process Id: #{$$}"

Anemone::Core.crawl(opts)

puts "End Time: #{Time.now} ****"
