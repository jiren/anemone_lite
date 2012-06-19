require 'rubygems'
require 'bundler/setup'
require 'fakeweb'
require File.dirname(__FILE__) + '/fakeweb_helper'

$:.unshift(File.dirname(__FILE__) + '/../lib/')

ENV['MONGODB_URI'] = 'mongodb://localhost:27017/test'
ENV['MONGODB_POOL_SIZE'] = "5"

SPEC_DOMAIN = 'http://www.example.com/'

require 'anemone'

