require 'rubygems'
require 'bundler/setup'
require 'fakeweb'
require File.dirname(__FILE__) + '/fakeweb_helper'

$:.unshift(File.dirname(__FILE__) + '/../lib/')

ENV['CRAWLER'] = 'db_config:spec/config/mongo.yml,env:test'

SPEC_DOMAIN = 'http://www.example.com/'

require 'anemone'

