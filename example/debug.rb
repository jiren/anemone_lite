#Export variable 
#i.e  export CRAWLER='db_config:config/mongo.yml,env:development'

#For test only
ENV['CRAWLER'] = 'db_config:config/mongo.yml,env:development'

require 'rubygems'
require 'bundler/setup'
require 'anemone'
