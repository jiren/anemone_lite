require 'rubygems'
require 'bundler/setup'
require 'fakeweb'
require File.dirname(__FILE__) + '/fakeweb_helper'

$:.unshift(File.dirname(__FILE__) + '/../lib/')

SPEC_DOMAIN = 'http://www.example.com/'
DB_ENV = {:mongo => {:database => 'test'} }

require 'anemone'

