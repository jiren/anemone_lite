ENV['MONGODB_URI'] = 'mongodb://localhost:27017/test'
ENV['MONGODB_POOL_SIZE'] = "5"

require 'rubygems'
require 'bundler/setup'
require 'anemone'
